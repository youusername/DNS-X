//
//  AuthorHelper.h
//  DNS-XHelper
//
//  Created by zhangjing on 2018/5/8.
//  Copyright © 2018年 214644496@qq.com. All rights reserved.
//

#ifndef AuthorHelper_h
#define AuthorHelper_h

@protocol AuthorHelperProtocol

@required

- (void)getVersion:(void(^)(NSString * version))reply;
- (void)openBPF:(void(^)(int))reply;
- (void)authTest:(NSData *)authData withReply:(void(^)(NSString * version))reply;

@end


@interface AuthorHelper : NSObject

- (id)init;

- (void)run;

@end
#endif /* AuthorHelper_h */
