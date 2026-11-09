#!/bin/zsh
# Releases the macOS app: checks that it compiles for macOS, iOS and visionOS, asks for the release
# notes in the editor, archives and zips the app, tags and pushes, creates the GitHub release, adds
# the release to the update feed, updates the Homebrew cask and installs the app to /Applications.
#
# Usage: ./release.sh [--dry-run] [--prerelease] [--notes <file>]
#   --dry-run     Run the checks, builds, notes, archive and feed, show what would be published and
#                 stop. Nothing is tagged, pushed, uploaded or installed.
#   --prerelease  Mark the GitHub release as a pre-release.
#   --notes       Open the editor with this file instead of the template.
#
# Bump MARKETING_VERSION and CURRENT_PROJECT_VERSION in a "Bump version to X" commit first, and run
# it on main with a clean working copy. It needs gh (logged in), jq, a clone of melgu/homebrew-tap at
# ../homebrew-tap (or TIDAL_TAP_DIR), and the feed server's SFTP login: FEED_SFTP_HOST,
# FEED_SFTP_USER and FEED_SFTP_PATH in .release.env (not committed), the password in the login
# keychain and the host key in ~/.ssh/known_hosts.

set -euo pipefail
setopt extendedglob

fail() {
	print -r -- "Error: $1" >&2
	exit 1
}

step() {
	print -r -- ""
	print -r -- "==> $1"
}

ask() {
	local answer
	read "answer?$1 [y/N] "
	[[ $answer == [yY]* ]]
}

usage="Usage: $0 [--dry-run] [--prerelease] [--notes <file>]"
dry_run=0
prerelease=0
notes_input=
while (( $# )); do
	case $1 in
		--dry-run) dry_run=1 ;;
		--prerelease) prerelease=1 ;;
		--notes)
			(( $# >= 2 )) || fail $usage
			notes_input=${2:A}
			[[ -f $notes_input ]] || fail "There is no notes file at $notes_input."
			shift
			;;
		*) fail $usage ;;
	esac
	shift
done

cd "${0:A:h}"
# Git over SSH fails instead of waiting for input that never comes
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND=${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=15}

repo_url=https://github.com/melgu/TidalSwift
feed_url=https://www.melvin-gundlach.de/apps/app-feeds/TidalSwift.json
tap=${TIDAL_TAP_DIR:-../homebrew-tap}
cask=$tap/Casks/tidalswift.rb

# MARK: Checks

step "Checking the setup"
for tool in jq gh xcodebuild sftp trash; do
	command -v $tool >/dev/null || fail "$tool is missing."
done
[[ -f .release.env ]] && source ./.release.env
[[ -n ${FEED_SFTP_HOST:-} && -n ${FEED_SFTP_USER:-} && -n ${FEED_SFTP_PATH:-} ]] || fail "Set FEED_SFTP_HOST, FEED_SFTP_USER and FEED_SFTP_PATH in .release.env."
security find-internet-password -s "$FEED_SFTP_HOST" -a "$FEED_SFTP_USER" >/dev/null 2>&1 || fail "The keychain has no password for $FEED_SFTP_USER@$FEED_SFTP_HOST. Add it with: security add-internet-password -s $FEED_SFTP_HOST -a $FEED_SFTP_USER -r 'ssh ' -w"
ssh-keygen -F "$FEED_SFTP_HOST" >/dev/null || fail "$FEED_SFTP_HOST isn't in ~/.ssh/known_hosts. Connect once with: sftp $FEED_SFTP_USER@$FEED_SFTP_HOST"
gh auth status >/dev/null 2>&1 || fail "Log in with gh auth login first."
[[ -f $cask ]] || fail "No cask at $cask. Clone melgu/homebrew-tap there or set TIDAL_TAP_DIR."

# A dry run is mostly made before committing, so these only warn there
problems=()
[[ $(git branch --show-current) == main ]] || problems+="Releases are made from main."
[[ -z $(git status --porcelain) ]] || problems+="Commit or stash the changes first."
git fetch -q origin
git merge-base --is-ancestor origin/main HEAD || problems+="main is behind origin/main. Pull first."
# A released version has to build for everyone, which a dependency on a local folder doesn't
if grep -qE 'XCLocalSwiftPackageReference|path = "?\.\./TidalSwiftLib' TidalSwift.xcodeproj/project.pbxproj; then
	problems+="The project uses a local TidalSwiftLib. Remove it and point it to a release first."
fi
[[ $(git -C "$tap" branch --show-current) == main && -z $(git -C "$tap" status --porcelain) ]] || problems+="The tap at $tap has to be on main and clean."
if (( ${#problems} )); then
	if (( dry_run )); then
		for problem in $problems; do
			print -r -- "Warning: $problem"
		done
	else
		fail "${(F)problems}"
	fi
fi

settings=$(xcodebuild -project TidalSwift.xcodeproj -scheme TidalSwift -configuration Release -showBuildSettings 2>/dev/null)
setting() {
	local -a matches=(${(M)${(f)settings}:#[[:space:]]#$1 = *})
	print -r -- "${${matches[1]:-}#*= }"
}
version=$(setting MARKETING_VERSION)
build=$(setting CURRENT_PROJECT_VERSION)
min_os=$(setting MACOSX_DEPLOYMENT_TARGET)
[[ -n $version && -n $build && -n $min_os ]] || fail "Couldn't read the version, build and deployment target from the project."
tag=$version-$build
# The feed has three-part versions (0.17 is 0.17.0), the tags use MARKETING_VERSION as it is
version_parts=("${(@s:.:)version}")
while (( ${#version_parts} < 3 )); do
	version_parts+=0
done
feed_version=${(j:.:)version_parts}
min_os_parts=("${(@s:.:)min_os}")
# Homebrew names macOS versions in depends_on
case ${min_os_parts[1]} in
	14) macos_name=sonoma ;;
	15) macos_name=sequoia ;;
	26) macos_name=tahoe ;;
	*) fail "Add the Homebrew name of macOS $min_os to release.sh." ;;
esac
print -r -- "TidalSwift $version ($build), tag $tag, macOS $min_os or later"

! git rev-parse -q --verify "refs/tags/$tag" >/dev/null || fail "Tag $tag exists already. Bump the version first."
remote_tag=$(git ls-remote --tags origin "refs/tags/$tag") || fail "Couldn't check the tags on GitHub."
[[ -z $remote_tag ]] || fail "Tag $tag exists on GitHub already."

work=${TMPDIR:-/tmp}
work=${work%/}/TidalSwift-release-$tag
mkdir -p "$work"
curl -sSfL "$feed_url" -o "$work/feed-old.json" || fail "Couldn't load the feed from $feed_url."
last_build=$(jq -r '.items[0].build' "$work/feed-old.json")
(( build > last_build )) || fail "Build $build isn't newer than the feed's latest build $last_build. Bump the version first."

# MARK: Compiling

step "Checking that it compiles"
for platform in macOS 'iOS Simulator' 'visionOS Simulator'; do
	print -r -- "Building for $platform…"
	log=$work/build-${platform// /-}.log
	if ! xcodebuild -project TidalSwift.xcodeproj -scheme TidalSwift -configuration Debug -destination "generic/platform=$platform" build >|$log 2>&1; then
		grep -m 20 'error:' $log || true
		fail "The build for $platform failed. Log: $log"
	fi
done

# MARK: Release notes

step "Release notes"
notes=$work/notes.md
if [[ -n $notes_input ]]; then
	cp "$notes_input" "$notes"
elif [[ -f $notes ]]; then
	print -r -- "Continuing with the notes from the last run."
else
	last_tag=$(git describe --tags --abbrev=0 HEAD 2>/dev/null || true)
	commits=$(git log --format='- %s' ${last_tag:+$last_tag..}HEAD)
	cat >|$notes <<-EOF
	#

	New
	-

	Improvements
	-

	Fixes
	-

	<!--
	Release notes for TidalSwift $version ($build), in Markdown. The first line is the title, the rest
	the text. Delete the sections you don't need. This comment is left out.

	GitHub shows the Markdown. The update notes in the app show plain text, where headings, bold,
	code and links lose their markup.

	Commits since ${last_tag:-the first one}:
	$commits
	-->
	EOF
fi

editor=${VISUAL:-${EDITOR:-}}
edit_notes() {
	if [[ -n $editor ]]; then
		${=editor} "$notes"
	else
		print -r -- "Quit TextEdit when you're done."
		open -W -t "$notes"
	fi
}

# Sets title and body from the notes file, or explains what's wrong and returns 1
parse_notes() {
	local content=$(perl -0pe 's/<!--.*?-->\n?//gs' "$notes")
	local -a lines=("${(@f)content}")
	local i=1
	while (( i <= ${#lines} )) && [[ -z ${lines[i]//[[:space:]]/} ]]; do
		(( i += 1 ))
	done
	local title_line=${lines[i]:-}
	title=${${title_line#\#}##[[:space:]]#}
	title=${title%%[[:space:]]#}
	if [[ $title_line != '# '* || -z $title ]]; then
		print -r -- "The first line has to be the title, like: # Lyrics view"
		return 1
	fi
	body=${(F)lines[i+1,-1]}
	body=${body##[[:space:]]#}
	body=${body%%[[:space:]]#}
	if [[ -z $body ]]; then
		print -r -- "The text below the title is empty."
		return 1
	fi
	if [[ -n ${(M)${(f)body}:#[[:space:]]#[-*][[:space:]]#} ]]; then
		print -r -- "There are empty list items. Fill them in or delete them."
		return 1
	fi
}

while true; do
	edit_notes
	parse_notes && break
	ask "Edit the notes again?" || fail "Stopped. The notes are kept in $notes for the next run."
done

# The app shows the text as plain text, so the Markdown markup goes
feed_text=$(print -r -- "$body" | perl -pe 's/^#{1,6}\s+//; s/\*\*(.+?)\*\*/$1/g; s/__(.+?)__/$1/g; s/`([^`]*)`/$1/g; s/\[([^\]]+)\]\(([^)]+)\)/$1 ($2)/g')
release_body=$work/release-body.md
print -r -- "# $title"$'\n\n'"$body" >|$release_body

# MARK: Archive

step "Archiving"
if (( dry_run )); then
	archive=$work/TidalSwift.xcarchive
	[[ -e $archive ]] && trash "$archive"
else
	archive=~/Library/Developer/Xcode/Archives/$(date +%F)/"TidalSwift $tag.xcarchive"
	[[ ! -e $archive ]] || fail "There is an archive at $archive already."
fi
log=$work/archive.log
if ! xcodebuild -project TidalSwift.xcodeproj -scheme TidalSwift -configuration Release -destination 'generic/platform=macOS' -allowProvisioningUpdates -archivePath "$archive" archive >|$log 2>&1; then
	grep -m 20 'error:' $log || true
	if grep -q errSecInternalComponent $log; then
		print -r -- "Signing needs the login keychain. Unlock it with: security unlock-keychain ~/Library/Keychains/login.keychain-db"
	fi
	fail "Archiving failed. Log: $log"
fi
app=$archive/Products/Applications/TidalSwift.app
[[ $(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist") == $version ]] || fail "The archived app has the wrong version."
[[ $(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$app/Contents/Info.plist") == $build ]] || fail "The archived app has the wrong build."
codesign --verify --deep --strict "$app" || fail "The archived app's signature isn't valid."

zip=$work/TidalSwift.zip
[[ -e $zip ]] && trash "$zip"
ditto -c -k --sequesterRsrc --keepParent "$app" "$zip"
sha=$(shasum -a 256 "$zip" | cut -d ' ' -f 1)
print -r -- "Archive: $archive"

# MARK: Feed

step "Adding the release to the feed"
feed=$work/feed-new.json
jq -c \
	--arg title "$title" \
	--arg text "$feed_text" \
	--arg version "$feed_version" \
	--arg build "$build" \
	--arg info "$repo_url/releases/tag/$tag" \
	--arg download "$repo_url/releases/download/$tag/TidalSwift.zip" \
	--argjson major "${min_os_parts[1]}" \
	--argjson minor "${min_os_parts[2]:-0}" \
	--argjson patch "${min_os_parts[3]:-0}" \
	'.items = [{
		title: $title,
		text: $text,
		minOSVersion: {majorVersion: $major, minorVersion: $minor, patchVersion: $patch},
		build: $build,
		infoUrl: $info,
		date: (now - 978307200),
		version: $version,
		downloadUrl: $download
	}] + .items' \
	"$work/feed-old.json" >|$feed
# The date counts seconds since 2001, as Swift's JSONEncoder writes it
jq -e --slurpfile old "$work/feed-old.json" '.items[1:] == $old[0].items and del(.items) == ($old[0] | del(.items))' "$feed" >/dev/null || fail "The new feed doesn't keep the old items."

# MARK: Summary

step "Release $tag"
print -r -- "GitHub release: $version ($build)$( (( prerelease )) && print -n ', pre-release')"
print -r -- "Zip SHA-256:    $sha"
print -r -- "Minimum macOS:  $min_os ($macos_name)"
print -r -- ""
print -r -- "--- GitHub release notes ---"
cat "$release_body"
print -r -- ""
print -r -- "--- Feed item ---"
jq '.items[0]' "$feed"

if (( dry_run )); then
	step "Dry run: stopping before publishing"
	print -r -- "A real run would now:"
	print -r -- "- tag HEAD as $tag and push main and the tag"
	print -r -- "- create the GitHub release $tag with the zip"
	print -r -- "- upload the feed to $FEED_SFTP_HOST and check $feed_url"
	print -r -- "- set the cask to $tag with SHA-256 $sha and macOS $macos_name, commit and push the tap"
	print -r -- "- install the app to /Applications"
	print -r -- ""
	print -r -- "Everything is in $work"
	exit 0
fi

ask "Publish $tag?" || fail "Stopped before publishing. The notes are kept in $notes for the next run."

# MARK: Publishing

step "Tagging $tag"
git tag -a "$tag" -m ""
git push -q origin main "refs/tags/$tag"

step "Creating the GitHub release"
release_flags=()
(( prerelease )) && release_flags+=--prerelease
gh release create "$tag" "$zip" --title "$version ($build)" --notes-file "$release_body" --verify-tag $release_flags
mkdir -p "$work/check"
gh release download "$tag" -p TidalSwift.zip -D "$work/check" --clobber
[[ $(shasum -a 256 "$work/check/TidalSwift.zip" | cut -d ' ' -f 1) == $sha ]] || fail "The zip on GitHub doesn't match the built one."

step "Uploading the feed"
askpass=$work/askpass.sh
print -r -- "#!/bin/sh
exec security find-internet-password -s '$FEED_SFTP_HOST' -a '$FEED_SFTP_USER' -w" >|$askpass
chmod 700 "$askpass"
SSH_ASKPASS=$askpass SSH_ASKPASS_REQUIRE=force sftp -q -o PreferredAuthentications=password,keyboard-interactive "$FEED_SFTP_USER@$FEED_SFTP_HOST" >/dev/null <<EOF
put "$feed" "$FEED_SFTP_PATH"
EOF
# sftp doesn't fail on a failed command when reading them from stdin, so this checks the result
curl -sSfL -H 'Cache-Control: no-cache' "$feed_url" | cmp -s - "$feed" || fail "The live feed doesn't match the new one. Upload $feed by hand."

step "Updating the Homebrew cask"
git -C "$tap" pull -q --ff-only
sed -i '' -E "s/^  version \".*\"$/  version \"$tag\"/; s/^  sha256 \".*\"$/  sha256 \"$sha\"/; s/^  depends_on macos: :.*$/  depends_on macos: :$macos_name/" "$cask"
grep -qx "  version \"$tag\"" "$cask" && grep -qx "  sha256 \"$sha\"" "$cask" && grep -qx "  depends_on macos: :$macos_name" "$cask" || fail "Couldn't set the version, SHA-256 and minimum macOS in $cask."
brew style melgu/tap
git -C "$tap" commit -qam "tidalswift $tag"
git -C "$tap" push -q

step "Installing to /Applications"
install=1
if pgrep -xq TidalSwift; then
	if ask "TidalSwift is running. Quit it to install $tag?"; then
		osascript -e 'quit app "TidalSwift"'
		for _ in {1..20}; do
			pgrep -xq TidalSwift || break
			sleep 1
		done
		! pgrep -xq TidalSwift || fail "TidalSwift didn't quit. Install it from $app by hand."
	else
		install=0
		print -r -- "Skipped. The app is in $app."
	fi
fi
if (( install )); then
	[[ -e /Applications/TidalSwift.app ]] && trash /Applications/TidalSwift.app
	ditto "$app" /Applications/TidalSwift.app
	[[ $(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' /Applications/TidalSwift.app/Contents/Info.plist) == $build ]] || fail "The installed app has the wrong build."
	codesign --verify --deep --strict /Applications/TidalSwift.app || fail "The installed app's signature isn't valid."
fi

trash "$work"
step "Released $tag: $repo_url/releases/tag/$tag"
