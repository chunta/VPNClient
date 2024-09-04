//
//  NotificationService.swift
//  ServiceExt
//
//  Created by Rex Chen on 2024/9/4.
//

import UserNotifications

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        
        guard let bestAttemptContent = bestAttemptContent,
              let attachmentURLAsString = bestAttemptContent.userInfo["url"] as? String,
              let attachmentURL = URL(string: attachmentURLAsString) else {
            return
        }
        
        let iconName = bestAttemptContent.userInfo["icon_name"] as? String {
            
        }
        
        // 4. Download the image and pass it to attachments if not nil
        downloadImageFrom(url: attachmentURL) { attachment in
            if let attachment = attachment {
                bestAttemptContent.attachments = [attachment]
            }
            contentHandler(bestAttemptContent)
        }
    }
    
    private func downloadImageFrom(url: URL, with completionHandler: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (downloadedUrl, response, error) in
            // 1. Test URL and escape if URL not OK
            guard let downloadedUrl = downloadedUrl else {
                completionHandler(nil)
                return
            }
            
            // 2. Get current user's temporary directory path
            var urlPath = URL(fileURLWithPath: NSTemporaryDirectory())
            
            // 3. Add proper ending to URL path, in the case .jpg
            let uniqueURLEnding = ProcessInfo.processInfo.globallyUniqueString + ".jpg"
            urlPath = urlPath.appendingPathComponent(uniqueURLEnding)
            
            // 4. Move downloadedUrl to newly created urlPath
            try? FileManager.default.moveItem(at: downloadedUrl, to: urlPath)
            
            // 5. Try adding the attachment and pass it to the completion handler
            do {
                let attachment = try UNNotificationAttachment(identifier: "picture", url: urlPath, options: nil)
                completionHandler(attachment)
            } catch {
                completionHandler(nil)
            }
        }
        task.resume()
    }
    
}
