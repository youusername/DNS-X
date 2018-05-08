//
//  AuthorHelper.m
//  DNS-XHelper
//
//  Created by zhangjing on 2018/5/8.
//  Copyright © 2018年 214644496@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AuthorHelper.h"

#include <sys/types.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <net/bpf.h>

@interface AuthorHelper () <NSXPCListenerDelegate, AuthorHelperProtocol>

@property (atomic, strong, readwrite) NSXPCListener *listener;

@end

@implementation AuthorHelper

- (id)init
{
    self = [super init];
    if (self != nil) {
        self->_listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.214644496.DNS-XHelper"];
        self->_listener.delegate = self;
    }
    return self;
}

- (void)run
{
    [self.listener resume];
    [[NSRunLoop currentRunLoop] run];
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AuthorHelperProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

- (void)getVersion:(void(^)(NSString * version))reply
{
    reply([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
}

- (void)openBPF:(void(^)(int))reply
{
    reply(3);
}

- (void)authTest:(NSData *)authData withReply:(void(^)(NSString * version))reply
{
    AuthorizationRef authref;
    OSStatus myStatus;

    myStatus = AuthorizationCreateFromExternalForm([authData bytes], &authref);
    if (myStatus != errAuthorizationSuccess) {
        reply(@"form error");
        return;
    }
    
    reply(@"succeeded");
}

@end
