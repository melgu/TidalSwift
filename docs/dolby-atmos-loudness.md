# Dolby Atmos Loudness

Dolby Atmos tracks play noticeably quieter than their stereo counterparts. Analysis from September 2026; nothing implemented yet.

## Current state

TidalSwift applies no loudness handling. `Player` passes the stream URL straight to `AVPlayer`, and the only gain is the user's volume (`avPlayer.volume` in `TidalSwift/Player.swift`). `Track.replayGain` and `Track.peak` (`TidalSwiftLib/Codables/Tracks.swift`) are decoded but never used. Every file plays at the level it was mastered at.

## Causes

1. **Mastering target (main cause).** Atmos mixes are delivered at about -18 LUFS integrated with a -1 dBTP ceiling (Dolby spec, required by the streaming services). Stereo masters, especially pop and rock, are often -8 to -12 LUFS. That is a 6–10 dB gap.
2. **Decoding to stereo.** The E-AC-3 JOC stream carries dialnorm and DRC metadata, which the macOS decoder applies when rendering to headphones or speakers. The downmix and binaural render add further headroom. This can lower the output by a few more dB.
3. **No normalization.** Tidal's official app can normalize all tracks to a common level, which hides the gap. TidalSwift plays stereo masters at full loudness, so the contrast is at its biggest.

## Possible fix: loudness normalization

Optional setting that applies a per-track gain factor:

- `gain = 10^((target - trackLoudness) / 20)`, clamped by the track's peak so it doesn't clip.
- Target around -14 LUFS, or the Atmos level to avoid boosting.
- Apply it as a multiplier on `avPlayer.volume`, or via an `AVAudioMix` so the volume slider stays independent. Note that `AVPlayer.volume` can't go above 1.0, so boosting quiet tracks needs an `AVAudioMix` or `AVAudioEngine`.

Open points:

- `Track.replayGain` describes the stereo master. For Atmos, the playbackinfo response probably carries its own `trackReplayGain` / `trackPeakAmplitude` for that stream. Not verified yet.
- Offline files need these values stored alongside them, since playback of offline files doesn't hit the playbackinfo endpoint.
