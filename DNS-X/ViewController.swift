//
//  ViewController.swift
//  DNS-X
//
//  Created by zhangjing on 2018/5/4.
//  Copyright © 2018年 214644496@qq.com. All rights reserved.
//

import Cocoa

@available(OSX 10.10, *)
class ViewController: NSViewController {
    override func loadView() {
        view = NSView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer?.backgroundColor = NSColor.white.cgColor
//        view.frame = NSRect(origin: .zero, size: AppDelegate.windowSize)
    }
}

