//
//  AppDelegate.swift
//  DNS-X
//
//  Created by zhangjing on 2018/5/4.
//  Copyright © 2018年 214644496@qq.com. All rights reserved.
//

import Cocoa
import Security
import ServiceManagement

@objc protocol AuthorHelperProtocol {
    func getVersion(_ withReply: (NSString) -> Void)
    func authTest(_ authData: NSData, withReply: (NSString) -> Void)
    //func openBpf(withReply: (Int, Int) -> Void)
}

@available(OSX 10.10, *)
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate,NSMenuDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let g_scriptPath = Bundle.main.path(forResource: "change_dns", ofType: "sh")
    var dnsServers = NSMutableArray()
    
    let HelperServiceName   = "com.214644496.DNS-XHelper"
    let HelperVersion       = "1.0.0"
    var authref: AuthorizationRef? = nil
    let kUserDefaultsKey    = "UserDefaultsArray"
    var isChange:Bool       = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(printQuote(_:))
        }
        constructMenu()

//        author()
    }

    func constructMenu() {
        
        let dnsMenu = NSMenu()
        
        let data = UserDefaults.standard.object(forKey: kUserDefaultsKey)
        if (data == nil) {
            let filePath = Bundle.main.path(forResource: "dns", ofType: "plist")
            dnsServers = NSMutableArray(contentsOfFile: filePath ?? "")!
            UserDefaults.standard.set(dnsServers, forKey: kUserDefaultsKey)
            UserDefaults.standard.synchronize()
        }else{
            dnsServers = data as! NSMutableArray
        }
        
        dnsServers.enumerateObjects({(_ obj: Any, _ idx: Int, _ stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            var ageDict:Dictionary<String, String> = obj as! Dictionary<String, String>
            let title = ageDict["name"]
            let item = NSMenuItem(title: title!, action: #selector(serverChanged(_:)), keyEquivalent: "")
                item.tag = idx
            dnsMenu.addItem(item)
            })
        
        let menu = NSMenu()
        menu.delegate = self
        let dns = NSMenuItem(title: "Change DNS", action: nil, keyEquivalent: "")
        let editor = NSMenuItem(title: "Editor List", action: #selector(editorList(_:)), keyEquivalent: "")
        dns.submenu = dnsMenu
        menu.addItem(dns)
        menu.addItem(editor)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Quotes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        

    }
    @objc func editorList(_ sender: Any?) {
        isChange = true
        let filePath = Bundle.main.path(forResource: "dns", ofType: "plist")
//        [[NSWorkspace sharedWorkspace] openURL:magnet];
        NSWorkspace.shared.openFile(filePath!)
    }
    @objc func serverChanged(_ item:NSMenuItem!) {
        var ip_dic = dnsServers[item.tag] as! Dictionary<String, String>
        let ip = ip_dic["IP"]
        
        changeDNSwithServer(ip)
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
        let success: Bool = runProcess(asAdministrator: g_scriptPath!, withArguments: [dnsServer!], output: &output, errorDescription:&processErrorDescription)
        if !success {
            print(processErrorDescription!)
        } else {
            // ...process output
        }
    }
    func runProcess(asAdministrator scriptPath: String, withArguments arguments: [String]?, output: inout String?, errorDescription: inout String?) -> Bool {
        let allArgs = arguments!.joined(separator: " ")
//        let fullScript = "'\(String(describing: scriptPath))' \(allArgs)"
        let fullScript = String.init(format: "'%@' %@",scriptPath,allArgs)
        
        var errorInfo :NSDictionary?
        let script = "do shell script \"" + fullScript + "\" with administrator privileges"
        let appleScript : NSAppleScript = NSAppleScript(source: script)!
        
        let eventResult: NSAppleEventDescriptor? = appleScript.executeAndReturnError(&errorInfo)
        // Check errorInfo
        if eventResult == nil {
            // Describe common errors
            errorDescription = nil
            if errorInfo![NSAppleScript.errorNumber] != nil {
                let errorNumber = errorInfo![NSAppleScript.errorNumber] as? NSNumber
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
            output = "\(String(describing: eventResult))"
            return true
        }
        
    }
    //MARK: - NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        if isChange {
            UserDefaults.standard.removeObject(forKey: kUserDefaultsKey)
            UserDefaults.standard.synchronize()
            constructMenu()
            isChange = false
        }
    }
    //MARK: - Author
    func author() {
                let status = AuthorizationCreate(nil, nil, AuthorizationFlags(), &authref)
                if (status != OSStatus(errAuthorizationSuccess)) {
                    print("AuthorizationCreate failed.")
                    return;
                }
                try_auth()
                connect_to_helper({
                    success in
                    if success {
                        self.connected()
                    } else {
                        self.install_helper()
                        self.connect_to_helper({
                            sucess in
                            self.connected()
                            if sucess {
                                print("Installed")
                            } else {
                                print("Fatal!  Could not install Helper!")
                            }
                        })
                    }
                })
    }
    
    func try_auth() {
        // 1. Create an empty authorization reference
        var aref: AuthorizationRef? = nil
        var status = AuthorizationCreate(nil, nil, AuthorizationFlags(), &aref)
        if (status != errAuthorizationSuccess) {
            print("AuthorizationCreate failed.")
            return;
        }
        
        // 2. Create AuthorizationRights.
        var item = AuthorizationItem(name: HelperServiceName, valueLength: 0, value: nil, flags: 0)
        var rights = AuthorizationRights(count: 1, items: &item)
        let flags = AuthorizationFlags([.interactionAllowed, .extendRights, .preAuthorize])
        status = AuthorizationCopyRights(authref!, &rights, nil, flags, nil)
        if (status != errAuthorizationSuccess) {
            print("AuthorizationCopyRights failed.")
            return;
        }
    }
    func connect_to_helper(_ callback: @escaping (Bool) -> Void) {
        let xpc = NSXPCConnection(machServiceName: HelperServiceName, options: .privileged)
        xpc.remoteObjectInterface = NSXPCInterface(with: AuthorHelperProtocol.self)
        xpc.resume()
        
        let helper = xpc.remoteObjectProxyWithErrorHandler({
            _ in callback(false)
        }) as! AuthorHelperProtocol
        
        helper.getVersion({
            version in
            print("get version => \(version), pid=\(xpc.processIdentifier)")
            callback(version as String == self.HelperVersion)
        })
    }
    func connected() {
        print("Hello!")
        
        let xpc = NSXPCConnection(machServiceName: HelperServiceName, options: .privileged)
        xpc.remoteObjectInterface = NSXPCInterface(with: AuthorHelperProtocol.self)
        xpc.invalidationHandler = { print("XPC invalidated...!") }
        xpc.resume()
        print(xpc)
        
        let proxy = xpc.remoteObjectProxyWithErrorHandler({
            err in
            print("xpc error =>\(err)")
        }) as! AuthorHelperProtocol
        
        var form = AuthorizationExternalForm()
        let status = AuthorizationMakeExternalForm(authref!, &form)
        if status != errAuthorizationSuccess {
            print("AuthorizationMakeExternalForm failed.")
            return;
        }
        
        let d = NSData(bytes: &form.bytes, length: MemoryLayout.size(ofValue: form.bytes))
        proxy.authTest(d, withReply: {
            msg in
            print("msg=\(msg)")
        })
    }
    func install_helper() {
        var item = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: nil, flags: 0)
        var rights = AuthorizationRights(count: 1, items: &item)
        let flags = AuthorizationFlags([.interactionAllowed, .extendRights])
        
        let status = AuthorizationCopyRights(authref!, &rights, nil, flags, nil)
        if (status != errAuthorizationSuccess) {
            print("AuthorizationCopyRights failed.")
            return;
        }
        
        var cfError: Unmanaged<CFError>?
        let success = SMJobBless(kSMDomainSystemLaunchd, HelperServiceName as CFString, authref, &cfError)
        if !success {
            print("SMJobBless failed: \(cfError!)")
        }
        
        print("SMJobBless suceeded")
        getversion()
    }
    func getversion() {
        let xpc = NSXPCConnection(machServiceName: HelperServiceName, options: .privileged)
        xpc.remoteObjectInterface = NSXPCInterface(with: AuthorHelperProtocol.self)
        xpc.invalidationHandler = { print("XPC invalidated...!") }
        xpc.resume()
        print(xpc)
        
        let proxy = xpc.remoteObjectProxyWithErrorHandler({
            err in
            print("xpc error =>\(err)")
        }) as! AuthorHelperProtocol
        proxy.getVersion({
            str in
            print("get version => \(str), pid=\(xpc.processIdentifier)")
        })
    }
}

