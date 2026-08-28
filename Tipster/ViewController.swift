//
//  ViewController.swift
//  Tipster
//
//  Created by Craig Hockenberry on 8/24/26.
//

import UIKit

class ViewController: UIViewController {

	@IBAction func resetTipsPressed() {
		debugLog()
		TipKitHelper.resetTips()
	}

}

