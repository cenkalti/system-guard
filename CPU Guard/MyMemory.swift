//
//  MyMemory.swift
//  CPU Guard
//
//  Created by Cenk Altı on 2024-09-16.
//

import Foundation
import UserNotifications

class MyMemory {
    
    var usage: Int = 0
    
    static let notificationRequestID = "MEMORY_PRESSURE"
    
    private var delivered: Bool = false
    
    func deliverNotification() {
        if delivered {
            return
        }
        delivered = true
        logger.log("delivering notification for high memory: \(self.usage)%")
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: MyMemory.notificationRequestID, content: createNotificationContent(), trigger: nil))
    }
    
    func removeNotification() {
        if !delivered {
            return
        }
        delivered = false
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [MyMemory.notificationRequestID])
    }
    
    private func createNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "High memory pressure"
        content.body = "Click to open Activity Monitor"
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive
        return content
    }
    
}
