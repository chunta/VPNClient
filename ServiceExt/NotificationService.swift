import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            return
        }
        
        // Download the main image if the URL is provided
        if let attachmentURLAsString = bestAttemptContent.userInfo["url"] as? String,
           let attachmentURL = URL(string: attachmentURLAsString) {
            downloadImageFrom(url: attachmentURL, identifier: "main_image") { mainAttachment in
                if let mainAttachment = mainAttachment {
                    bestAttemptContent.attachments.append(mainAttachment)
                }
                contentHandler(bestAttemptContent)
            }
        } else {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func downloadImageFrom(url: URL, identifier: String, with completionHandler: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (downloadedUrl, response, error) in
            guard let downloadedUrl = downloadedUrl else {
                print("Failed to download image from URL: \(url)")
                completionHandler(nil)
                return
            }
            
            var urlPath = URL(fileURLWithPath: NSTemporaryDirectory())
            let uniqueURLEnding = ProcessInfo.processInfo.globallyUniqueString + ".jpg"
            urlPath = urlPath.appendingPathComponent(uniqueURLEnding)
            
            do {
                try FileManager.default.moveItem(at: downloadedUrl, to: urlPath)
                let attachment = try UNNotificationAttachment(identifier: identifier, url: urlPath, options: nil)
                print("Successfully created attachment: \(identifier)")
                completionHandler(attachment)
            } catch {
                print("Failed to create attachment for \(identifier): \(error)")
                completionHandler(nil)
            }
        }
        task.resume()
    }
}
