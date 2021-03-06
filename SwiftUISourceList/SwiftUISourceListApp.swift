//
//  SwiftUISourceListApp.swift
//  SwiftUISourceList
//
//  Created by cpahull on 05/03/2021.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct SwiftUISourceListApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate


    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
}
