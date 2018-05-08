//
//  main.m
//  DNS-XHelper
//
//  Created by zhangjing on 2018/5/8.
//  Copyright © 2018年 214644496@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuthorHelper.h"

#include <syslog.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, const char * argv[]) {
    syslog(LOG_NOTICE, "Hello world! uid = %d, euid = %d, pid = %d\n", (int) getuid(), (int) geteuid(), (int) getpid());
    @autoreleasepool {
        [[[AuthorHelper alloc] init] run];
    }
    return 0;
}
