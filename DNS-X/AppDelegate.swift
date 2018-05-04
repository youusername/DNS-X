//
//  AppDelegate.swift
//  DNS-X
//
//  Created by zhangjing on 2018/5/4.
//  Copyright © 2018年 214644496@qq.com. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let g_scriptPath = Bundle.main.path(forResource: "change_dns", ofType: "sh")


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(printQuote(_:))
        }
        constructMenu()
    }
    func constructMenu() {
        
        let dnsMenu = NSMenu()
        let filePath = Bundle.main.path(forResource: "dns", ofType: "plist")
        let dnsServers = NSArray(contentsOfFile: filePath ?? "")
        
        dnsServers?.enumerateObjects({(_ obj: Any, _ idx: Int, _ stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            var ageDict:Dictionary<String, String> = obj as! Dictionary<String, String>
            let title = ageDict["name"]
            dnsMenu.addItem(NSMenuItem(title: title!, action: nil, keyEquivalent: ""))
            })
        
        let menu = NSMenu()
        
        let dns = NSMenuItem(title: "Change DNS", action: nil, keyEquivalent: "")
        dns.submenu = dnsMenu
        menu.addItem(dns)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Quotes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    @objc func printQuote(_ sender: Any?) {
        let quoteText = "Never put off until tomorrow what you can do the day after tomorrow."
        let quoteAuthor = "Mark Twain"
        
        print("\(quoteText) — \(quoteAuthor)")
    }
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func changeDNSwithServer(_ dnsServer: String?) {
        var output: String? = nil
        var processErrorDescription: String? = nil
        let success: Bool = runProcess(asAdministrator: g_scriptPath, withArguments: [dnsServer!], output: &output, errorDescription: &processErrorDescription)
        if !success {
            // ...look at errorDescription
        } else {
            // ...process output
        }
    }
    func runProcess(asAdministrator scriptPath: String?, withArguments arguments: [String]?, output: inout String?, errorDescription: inout String?) -> Bool {
        let allArgs = arguments!.joined(separator: " ")
        let fullScript = "'\(scriptPath)' \(allArgs)"
        var errorInfo : NSDictionary? = nil
        let script = "do shell script \"\(fullScript)\" with administrator privileges"
        let appleScript = NSAppleScript.init(source: script)
        let eventResult: NSAppleEventDescriptor? = appleScript?.executeAndReturnError(&errorInfo)
        // Check errorInfo
        if eventResult == nil {
            // Describe common errors
            errorDescription = nil
            if errorInfo![NSAppleScript.errorNumber] != nil {
                var errorNumber = errorInfo![NSAppleScript.errorNumber] as? NSNumber
                if Int(truncating: errorNumber ?? 0) == -128 {
                    errorDescription = "The administrator password is required to do this."
                }
            }
            // Set error message from provided message
            if errorDescription == nil {
                if errorInfo![NSAppleScript.errorMessage] != nil {
                    errorDescription = errorInfo![NSAppleScript.errorMessage] as? String
                }
            }
            return false
        } else {
            // Set output to the AppleScript's output
            output = "\(eventResult)"
            return true
        }
        
    }
}

