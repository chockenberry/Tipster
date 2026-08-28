//
//  AppModel.swift
//  Tipster
//
//  Created by Craig Hockenberry on 8/24/26.
//

import Foundation

extension Notification.Name {
	static let appModelDidChange = Notification.Name("AppModelDidChangeNotification")
}

class AppModel {
	
	// NOTE: An old school model that you're likely to have if you started working on iOS prior to SwiftUI.
	// There is some persisted data (in UserDefaults) and saving the model posts a notification.
	
	static let shared = AppModel()

	
	static let textKey = "text";
	static let countKey = "count";

	var text: String
	var count: Int
	
	init() {
		text = UserDefaults.standard.string(forKey: Self.textKey) ?? "CHOCK WAS HEAR"
		count = UserDefaults.standard.integer(forKey: Self.countKey)
	}
	
	func save() {
		UserDefaults.standard.set(text, forKey: Self.textKey)
		UserDefaults.standard.set(count, forKey: Self.countKey)
		NotificationCenter.default.post(name: .appModelDidChange, object: self)
	}
}
