//
//  NotificationViewController.swift
//  ContentExt
//
//  Created by Rex Chen on 2024/9/4.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    @IBOutlet var label: UILabel?
    @IBOutlet var imageVw: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func didReceive(_ notification: UNNotification) {
        self.label?.text = notification.request.content.body
        
        let attachements = notification.request.content.attachments
        for attachement in attachements {
            if attachement.identifier == "picture" {
                guard let data = try? Data(contentsOf: attachement.url) else {
                    return
                }
                imageVw?.image = UIImage(data: data)
            }
        }
    }
}
