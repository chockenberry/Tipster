//
//  TipKit.swift
//  Tipster
//
//  Created by Craig Hockenberry on 8/24/26.
//

import UIKit
import TipKit

@objcMembers
class TipKitHelper: NSObject {
	
	static func configureTips(withReset: Bool = false) {
		if withReset {
			// NOTE: This does not reset a tip's eligibility, it removes everything in the database
			// used to track the tips. It must also be called before .configure() below. Calling it
			// after configuration throws an error.
			try? Tips.resetDatastore()
		}
		
#if DEBUG && true
#warning("DEBUGGING TIPS")
		// NOTE: This will display tips immediately so you can test them. Unfortunately, the
		// smallest increment of time to display tips is hourly, so you need to have patience
		// when testing in your production app. It's unlikely that your customers will want
		// to see these tips as frequently as you do, so avoid short intervals.
		try? Tips.configure([.displayFrequency(.immediate)])
#else
		try? Tips.configure([.displayFrequency(.hourly)])
#endif

		// NOTE: In theory, these should be helpful for testing. In practice, they are not.
		//Tips.showTipsForTesting([SecretTip.self])
		//Tips.showAllTipsForTesting()
	}

	static func resetTips() {
		if #available(iOS 26.0, *) {
			Task {
				await ToggleTip().resetEligibility()
				await SecretTip().resetEligibility()
				await CountTip().resetEligibility()
			}
		}
		else {
			// NOTE: If you really need this functionality in earlier releases, you'll need to use
			// resetDatastore() sometime at launch before configure() is called (along with some kind
			// of user messaging to force quit and relaunch the app).
		}
	}
}

struct ToggleTip: Tip {
	
	var title: Text = Text("Tip for a Toggle")
	var message: Text? = Text("This is a tip that shows when the switch's `isOn` state is true. It **does not** use the AppModel.\n\nYou can close it manually before 5 seconds elapses.")
	var image: Image? = Image(systemName: "switch.2")

	@Parameter
	static var isOn: Bool = false
	
	var rules: [Rule] = [
		#Rule(Self.$isOn) { $0 == true }
	]
}

struct SecretTip: Tip {
	var title: Text = Text("Secret Tip")
	var message: Text? = Text("Congratulations! You found the secret tip.")
	var image: Image? = Image(systemName: "magnifyingglass")
	
	@Parameter
	static var foundSecret: Bool = false
	
	var rules: [Rule] = [
		#Rule(Self.$foundSecret) { $0 == true }
	]
}

struct CountTip: Tip {
	static let noneMoreBlack = Color.black // none more

	// NOTE: You can style the individual tips as needed.
	var title: Text = Text("It Goes to 11").foregroundStyle(noneMoreBlack)
	var message: Text? = Text("All the best ones do. It’s that extra push over the cliff.").foregroundStyle(noneMoreBlack)
	var image: Image? = Image("Nigel") // NOTE: Use your own image assets, but also use .template renderingMode.

	@Parameter
	static var overTheCliff: Bool = false
	
	var rules: [Rule] = [
		#Rule(Self.$overTheCliff) { $0 == true }
	]
}

@objcMembers
class TipPresenter: NSObject {

	let tip: any Tip
	private weak var viewController: UIViewController?
	private weak var sourceItem: UIView?
	private let arrowDirections: UIPopoverArrowDirection
	
	private var tipObservationTask: Task<Void, Never>?
	private var tipPopoverController: TipUIPopoverViewController?

	init(tip: any Tip, from viewController: UIViewController, sourceItem: UIView, arrowDirections: UIPopoverArrowDirection) {
		self.tip = tip
		self.viewController = viewController
		self.sourceItem = sourceItem
		self.arrowDirections = arrowDirections
		
		self.tipPopoverController = nil
	}
	
	func start() {
		debugLog("\(tip.id): called")
		guard self.tipObservationTask == nil else { return }
		
		debugLog("\(tip.id): starting")
		self.tipObservationTask = Task { @MainActor in
			debugLog("\(tip.id): awaiting")
			for await shouldDisplay in tip.shouldDisplayUpdates {
				if let viewController {
					debugLog("\(tip.id): shouldDisplay = \(shouldDisplay)")
					if shouldDisplay {
						if viewController.presentedViewController == nil {
							debugLog("\(tip.id): presenting")
							if let sourceItem {
								let popoverController = TipUIPopoverViewController(tip, sourceItem: sourceItem)
								popoverController.view.tintColor = UIColor(named: "AccentColor")!
								if let popoverPresentationController = popoverController.popoverPresentationController {
									popoverPresentationController.permittedArrowDirections = arrowDirections
								}
								
								viewController.present(popoverController, animated: true)
								tipPopoverController = popoverController
							}
							else {
								fatalError("\(tip.id): no sourceItem, remember to stop() the TipPresenter")
							}
						}
					}
					else {
						if viewController.presentedViewController != nil && viewController.presentedViewController == tipPopoverController {
							debugLog("\(tip.id): dismissing")
							viewController.dismiss(animated: true)
							tipPopoverController = nil
						}
					}
				}
				else {
					fatalError("\(tip.id): no view controller, remember to stop() the TipPresenter")
				}
			}
		}
	}
	
	func stop() {
		debugLog("\(tip.id): called")
		guard self.tipObservationTask != nil else { return }

		debugLog("\(tip.id): cancelling")
		tipObservationTask?.cancel()
		tipObservationTask = nil
	}
	
	// NOTE: invalidate() prevents the Tip from every appearing again. For example, if you have a tip for a
	// favorite button, you'd invalidate the TipPresenter whenever the user taps the control (they already
	// found the feature, so don't bug them about it!)
	func invalidate() {
		debugLog("\(tip.id): invalidating")
		tip.invalidate(reason: .actionPerformed)
	}
	
	func isDisplayed() -> Bool {
		return tipPopoverController != nil
	}
	
	/*
	func hasDisplayed() -> Bool {
		// NOTE: The tip.status will be a lie. After being .invalidated (like with .actionPerformed), the status will
		// be .pending for awhile until the async sequence starts pumping out updates. It's not a good indication of
		// "have we seen this tip?" and it appears that there's no mechanism that can answer that question. If you
	 	// really need to know, you'll have to create a Task that monitors the state changes and act accordingly.
		let status = tip.status
		switch status {
		case .pending:
			debugLog("\(tip.id): status = pending [false]")
			return false
		case .available:
			debugLog("\(tip.id): status = available [false]")
			return false
		case let .invalidated(reason):
			debugLog("\(tip.id): status = invalidated with \(reason) [true]")
			return true
		@unknown default:
			debugLog("\(tip.id): status = unknown [false]")
			return false
		}
	}
	*/

	deinit {
		debugLog("\(tip.id): clean up")
		stop()
	}
	
}

@objcMembers
class ToggleTipPresenter: TipPresenter {
	
	init(from viewController: UIViewController, sourceItem: UIView) {
		super.init(tip: ToggleTip(), from: viewController, sourceItem: sourceItem, arrowDirections: [.down, .up])
	}
	
	var isOn: Bool {
		set {
			debugLog("\(tip.id): set isOn = \(newValue)")
			ToggleTip.isOn = newValue
		}
		get {
			debugLog("\(tip.id): get isOn = \(ToggleTip.isOn)")
			return ToggleTip.isOn
		}
	}
	
}

@objcMembers
class SecretTipPresenter: TipPresenter {
	
	init(from viewController: UIViewController, sourceItem: UIView) {
		super.init(tip: SecretTip(), from: viewController, sourceItem: sourceItem, arrowDirections: [.down])
	}
	
	var foundSecret: Bool {
		set {
			debugLog("\(tip.id): set foundSecret = \(newValue)")
			SecretTip.foundSecret = newValue
		}
		get {
			debugLog("\(tip.id): get foundSecret = \(SecretTip.foundSecret)")
			return SecretTip.foundSecret
		}
	}

}

@objcMembers
class CountTipPresenter: TipPresenter {
	
	init(from viewController: UIViewController, sourceItem: UIView) {
		super.init(tip: CountTip(), from: viewController, sourceItem: sourceItem, arrowDirections: [.up])
	}

	var overTheCliff: Bool {
		set {
			debugLog("\(tip.id): set overTheCliff = \(newValue)")
			CountTip.overTheCliff = newValue
		}
		get {
			debugLog("\(tip.id): get overTheCliff = \(CountTip.overTheCliff)")
			return CountTip.overTheCliff
		}
	}

}

