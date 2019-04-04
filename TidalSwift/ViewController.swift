//
//  ViewController.swift
//  TidalSwift
//
//  Created by Melvin Gundlach on 12.03.19.
//  Copyright © 2019 Melvin Gundlach. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
	
	func errorDialog(title: String, text: String) {
		let alert = NSAlert()
		alert.messageText = title
		alert.informativeText = text
		alert.alertStyle = .warning
		alert.runModal()
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		let appDelegate = NSApplication.shared.delegate as? AppDelegate
		appDelegate?.mainViewController = self
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}


}
