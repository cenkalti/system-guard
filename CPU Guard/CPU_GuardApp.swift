//
//  CPU_GuardApp.swift
//  CPU Guard
//
//  Created by Cenk Altı on 2021-11-13.
//

// TODO
// Fix notification issue
// Fix icon in notification content
//
// Convert print statements to Logger calls
// Put arguments to notification body
// Adjust values for release

import os
import SwiftUI
import UserNotifications
import LaunchAtLogin

// TODO adjust values before release
let cpuTreshold = 80.0
let allowedDuration = Int64(3e9) // nanoseconds
let interval = 1.0 // 5

var processes = [Int:MyProcess]() // keyed by pid
let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")

@main
struct CPU_GuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusBarItem: NSStatusItem!
    var launchAtLoginMenuItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        runAutomaticallyAtStartup()
        createMenuBarItem()
        setupNotifications()
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: self.tick)
    }
    
    func setupNotifications() {
        print("requesting notification authorization")
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("notification authorization error:", error)
            }
            print("notification authorization granted:", granted)
            if !granted {
                NSApplication.shared.terminate(self)
                return
            }
            
            // Clear notifications from previous launch
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
            // Define the custom actions.
            let terminateAction = UNNotificationAction(
                identifier: "TERMINATE_ACTION",
                title: "Terminate",
                options: [.authenticationRequired, .destructive])
            let killAction = UNNotificationAction(
                identifier: "KILL_ACTION",
                title: "Kill",
                options: [.authenticationRequired, .destructive])
            
            // Define the notification type
            let cpuUsageCategory = UNNotificationCategory(
                identifier: "CPU_USAGE",
                actions: [terminateAction, killAction],
                intentIdentifiers: [])
            
            // Register the notification type.
            UNUserNotificationCenter.current().setNotificationCategories([cpuUsageCategory])
        }
    }
    
    func createMenuBarItem() {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusBarItem.button?.image = NSImage(named: "StatusIcon")
        self.statusBarItem.button?.image?.isTemplate = true
        self.statusBarItem.menu = NSMenu(title: "CPU Guard Status Bar Menu")
        launchAtLoginMenuItem = self.statusBarItem.menu?.addItem(withTitle: "Launch at login", action: #selector(handleLaunchAtLogin), keyEquivalent: "")
        if LaunchAtLogin.isEnabled {
            launchAtLoginMenuItem.state = .on
        }
        self.statusBarItem.menu?.addItem(withTitle: "Quit", action: #selector(handleQuitMenuItem), keyEquivalent: "")
    }
    
    @objc func handleLaunchAtLogin () {
        if launchAtLoginMenuItem.state == .off {
            LaunchAtLogin.isEnabled = true
            launchAtLoginMenuItem.state = .on
        } else {
            LaunchAtLogin.isEnabled = false
            launchAtLoginMenuItem.state = .off
        }
    }
    
    @objc func handleQuitMenuItem () {
        NSApplication.shared.terminate(self)
    }

    func runAutomaticallyAtStartup() {
        let key = "launchedBefore"
        let launchedBefore = UserDefaults.standard.bool(forKey: key)
        print("application launched before:", launchedBefore)
        if !launchedBefore {
            print("first launch, setting LaunchAtLogin = true")
            LaunchAtLogin.isEnabled = true
            UserDefaults.standard.set(true, forKey: key)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
           didReceive response: UNNotificationResponse,
           withCompletionHandler completionHandler:
             @escaping () -> Void) {
        
        // Get the PID from the original notification.
        let pid = response.notification.request.content.userInfo["PID"] as! Int
        
        // Perform the task associated with the action.
        switch response.actionIdentifier {
        case "TERMINATE_ACTION":
            kill(pid_t(pid), SIGTERM)
            processes[pid] = nil
            break
        case "KILL_ACTION":
            kill(pid_t(pid), SIGKILL)
            processes[pid] = nil
            break
        default:
            break
        }
        
        // Always call the completion handler when done.
        completionHandler()
    }
    
    func tick(timer: Timer) {
        let now = DispatchTime.now().uptimeNanoseconds
        
        // Run ps command
        let currentProcesses = runPs()
        
        // Check new processes
        for (pid, currentProcess) in currentProcesses {
            if let existingProcess = processes[pid] {
                // Update existing processes
                existingProcess.info = currentProcess
            } else {
                // Add new process
                processes[pid] = MyProcess(info: currentProcess)
            }
        }
        
        // Check existing processes
        for (pid, process) in processes {
            if currentProcesses[pid] == nil {
                // Remove stale process
                process.removeNotification()
                processes[pid] = nil
            } else if process.info.cpu < cpuTreshold {
                // CPU below treshold
                process.start = nil
                process.removeNotification()
            } else {
                // CPU above treshold
                if let start = process.start {
                    if (now - start) > allowedDuration {
                        process.deliverNotification()
                    }
                } else {
                    process.start = now
                }
            }
        }
    }
    
}
