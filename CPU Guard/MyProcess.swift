//
//  MyProcess.swift
//  CPU Guard
//
//  Created by Cenk Altı on 2021-11-13.
//

import Foundation
import UserNotifications

struct MyProcessInfo {
    var pid: Int
    var cpu: Double
    var command: String
    var arguments: [String]
}

class MyProcess {
    
    var info: MyProcessInfo
    var uuid: UUID
    var start: UInt64? // When did this process became hot?
    
    private var delivered: Bool = false
    
    init(info: MyProcessInfo) {
        self.info = info
        self.uuid = UUID()
    }
    
    func deliverNotification() {
        if delivered {
            return
        }
        delivered = true
        logger.log("delivering notification for pid: \(self.info.pid)")
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: self.uuid.uuidString, content: createNotificationContent(), trigger: nil))
    }
    
    func removeNotification() {
        if !delivered {
            return
        }
        delivered = false
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [self.uuid.uuidString])
    }
    
    private func createNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(info.command) is using too much CPU"
        content.body = info.arguments.joined(separator: " ")
        content.userInfo = ["PID": info.pid]
        content.categoryIdentifier = "CPU_USAGE"
        content.sound = UNNotificationSound.default
        return content
    }
    
}
