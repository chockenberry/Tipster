//
//  PresentedViewController.swift
//  Tipster
//
//  Created by Craig Hockenberry on 8/24/26.
//

import UIKit

// NOTE: You probably don't want to put your Tips in a view controller. Yes the view controller presents them, but they are higher-level
// concepts that can move around in your app. For example, a favorites button could move from a detail to primary view controller.
// Or a single tip could be needed for both the primary and detail views.
//
// For this example, we're putting the broken one here to keep it separate from the other ones in TipKitHelper.

import TipKit

struct BrokenTip: Tip {
	
	var title: Text = Text("This is a broken tip")
	var message: Text? = Text("When you tap the \(Image(systemName: "xmark.circle")) button, nothing happens. You have to tap outside the popover to dismiss it.")
	var image: Image? = Image(systemName: "questionmark.circle")
	
}

class PresentedViewController: UIViewController {

	@IBOutlet weak var brokenButton: UIButton!

	@IBOutlet weak var toggleSwitch: UISwitch!

	@IBOutlet weak var textTextField: UITextField!
	@IBOutlet weak var counterLabel: UILabel!
	@IBOutlet weak var counterIncrementButton: UIButton!
	@IBOutlet weak var counterDecrementButton: UIButton!
	@IBOutlet weak var saveButton: UIButton!

	var text: String = ""
	var count: Int = 0
	
	var toggleTipPresenter: ToggleTipPresenter?
	var secretTipPresenter: SecretTipPresenter?
	var countTipPresenter: CountTipPresenter?

	deinit {
		NotificationCenter.default.removeObserver(self)
		
		// NOTE: This is important: the Task used in the TipPresenter is retained until it's cancelled. This puts your tips
		// and the presenter in a retain cycle if you don't stop(). You'll also be left with invalid references to the
		// presenter's viewController and sourceItem. Treat the presenter like you would an observer.
		toggleTipPresenter?.stop()
		secretTipPresenter?.stop()
		countTipPresenter?.stop()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(appModelDidChange), name: .appModelDidChange, object: nil)

		self.text = AppModel.shared.text
		self.count = AppModel.shared.count
		
		toggleTipPresenter = ToggleTipPresenter(from: self, sourceItem: toggleSwitch)
		secretTipPresenter = SecretTipPresenter(from: self, sourceItem: textTextField)
		countTipPresenter = CountTipPresenter(from: self, sourceItem: counterLabel)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		updateView()
		updateTips()
		
		toggleTipPresenter?.start()
		secretTipPresenter?.start()
		countTipPresenter?.start()
	}
	
	private func updateView() {
		textTextField.text = text
		counterLabel.text = "The count is \(count)"
		counterIncrementButton.isEnabled = count < 11
		counterDecrementButton.isEnabled = count > 0
	}
	
	private func updateTips() {
		toggleTipPresenter?.isOn = toggleSwitch.isOn
		secretTipPresenter?.foundSecret = (text == "SEKRET") // SO SECURE
		countTipPresenter?.overTheCliff = (count == 11) // yes, this one goes to 11
	}
	
	@IBAction func dismiss() {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func brokenButtonPressed() {
		debugLog()
		
		// NOTE: This code uses the TipKit popover view controller to present a broken tip. The code
		// looks right, but the tip won't close when you tap the "X" button. Instead, use
		// TipPresenter. It's defined in TipKitHelper and used in this view controller via the
		// toggleTipPresenter, secretTipPresenter, and countTipPresenter instances.
		
		let tipPopoverController = TipUIPopoverViewController(BrokenTip(), sourceItem: brokenButton)
		tipPopoverController.view.tintColor = UIColor(named: "AccentColor")!
		if let popoverPresentationController = tipPopoverController.popoverPresentationController {
			popoverPresentationController.permittedArrowDirections = [.up, .down]
		}
		
		self.present(tipPopoverController, animated: true)
	}

	@IBAction func toggleSwitchPressed() {
		toggleTipPresenter?.isOn = toggleSwitch.isOn
		Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
			self.toggleSwitch.setOn(false, animated: true)
			self.toggleTipPresenter?.isOn = false
			timer.invalidate()
		}
	}

	@IBAction func counterDecrementButtonPressed() {
		debugLog()
		
		count -= 1
		updateView()
	}

	@IBAction func counterIncrementButtonPressed() {
		debugLog()
		
		count += 1
		updateView()
	}

	@IBAction func saveButtonPressed() {
		debugLog()
		
		text = textTextField.text ?? ""
		
		AppModel.shared.text = text
		AppModel.shared.count = count
		AppModel.shared.save()
	}

	@objc func appModelDidChange() {
		text = AppModel.shared.text
		count = AppModel.shared.count

		updateView()
		updateTips()
	}
}

