//
//  DDMessageSendManager.m
//  ZKChat
//
//  Created by 张阔 on 2017/5/17.
//  Copyright © 2017年 张阔. All rights reserved.
//

#import "DDMessageSendManager.h"
#import "ZKDatabaseUtil.h"
#import "EmotionsModule.h"
#import "RuntimeStatus.h"
#import "NSDictionary+JSON.h"

static uint32_t seqNo = 0;

@interface DDMessageSendManager(PrivateAPI)

- (NSString* )toSendmessageContentFromContent:(NSString*)content;

@end
@implementation DDMessageSendManager
{
    NSUInteger _uploadImageCount;
}
+ (instancetype)instance
{
    static DDMessageSendManager* g_messageSendManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_messageSendManager = [[DDMessageSendManager alloc] init];
    });
    return g_messageSendManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _uploadImageCount = 0;
        _waitToSendMessage = [[NSMutableArray alloc] init];
        _sendMessageSendQueue = dispatch_queue_create("com.kafeihu.sendMessageSend", NULL);
        
    }
    return self;
}

- (void)sendMessage:(ZKMessageEntity *)message isGroup:(BOOL)isGroup Session:(ZKSessionEntity*)session completion:(DDSendMessageCompletion)completion Error:(void(^)(NSError *error))block {
    dispatch_async(self.sendMessageSendQueue, ^{
        //SendMessageAPI* sendMessageAPI = [[SendMessageAPI alloc] init];
        uint32_t nowSeqNo = ++seqNo;
        message.seqNo=nowSeqNo;
        
        NSString* newContent = message.msgContent;
        if ([message isImageMessage]) {
            NSDictionary* dic = [NSDictionary initWithJsonString:message.msgContent];
            NSString* urlPath = dic[DD_IMAGE_URL_KEY];
            newContent=urlPath;
        }
        
//        char* pOut='s';
        //EncryptMsg(test, nInLen, &pOut, nOutLen);
//        NSData *data = [[NSString stringWithCString:pOut encoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
//        Free(pOut);
        if(!message.msgID){
            return;
        }
        //NSArray* object = @[TheRuntime.user.objID,session.sessionID,data,@(message.msgType),@(message.msgID)];
        if ([message isImageMessage]) {
            session.lastMsg=@"[图片]";
        }else if ([message isVoiceMessage])
        {
            session.lastMsg=@"[语言]";
        }else
        {
            session.lastMsg=message.msgContent;
        }
       // [[UnAckMessageManager instance] addMessageToUnAckQueue:message];
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"SentMessageSuccessfull" object:session];
//        [sendMessageAPI requestWithObject:object Completion:^(id response, NSError *error) {
//            if (!error)
//            {
                NSLog(@"发送消息成功");
                [[ZKDatabaseUtil instance] deleteMesages:message completion:^(BOOL success){
                    
                }];
                
               // [[UnAckMessageManager instance] removeMessageFromUnAckQueue:message];

                //message.msgID=[response[0] integerValue];
                message.state=DDmessageSendSuccess;
                session.lastMsgID=message.msgID;
                session.timeInterval=message.msgTime;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SentMessageSuccessfull" object:session];
                [[ZKDatabaseUtil instance] insertMessages:@[message] success:^{
                    
                } failure:^(NSString *errorDescripe) {
                    
                }];
                completion(message,nil);
                
                
//            }
//            else
//            {
//                message.state=DDMessageSendFailure;
//                [[ZKDatabaseUtil instance] insertMessages:@[message] success:^{
//                    
//                } failure:^(NSString *errorDescripe) {
//                    
//                }];
//                NSError* error = [NSError errorWithDomain:@"发送消息失败" code:0 userInfo:nil];
//                block(error);
//            }
//        }];
        
    });
}

- (void)sendVoiceMessage:(NSData*)voice filePath:(NSString*)filePath forSessionID:(NSString*)sessionID isGroup:(BOOL)isGroup Message:(ZKMessageEntity *)msg Session:(ZKSessionEntity*)session completion:(DDSendMessageCompletion)completion {
    dispatch_async(self.sendMessageSendQueue, ^{
//        SendMessageAPI* sendVoiceMessageAPI = [[SendMessageAPI alloc] init];
        
        NSString* myUserID = [RuntimeStatus instance].user.objID;
        NSArray* object = @[myUserID,sessionID,voice,@(msg.msgType),@(0)];
//        [sendVoiceMessageAPI requestWithObject:object Completion:^(id response, NSError *error) {
//            if (!error)
//            {
        
                
                NSLog(@"发送消息成功");
                [[ZKDatabaseUtil instance] deleteMesages:msg completion:^(BOOL success){
                    
                }];
                
                
                NSUInteger messageTime = [[NSDate date] timeIntervalSince1970];
                msg.msgTime=messageTime;
               // msg.msgID=[response[0] integerValue];
                msg.state=DDmessageSendSuccess;
                session.lastMsg=@"[语音]";
                session.lastMsgID=msg.msgID;
                session.timeInterval=msg.msgTime;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SentMessageSuccessfull" object:session];
                [[ZKDatabaseUtil instance] insertMessages:@[msg] success:^{
                    
                } failure:^(NSString *errorDescripe) {
                    
                }];
                
                completion(msg,nil);
                
//            }
//            else
//            {
//                NSError* error = [NSError errorWithDomain:@"发送消息失败" code:0 userInfo:nil];
//                completion(nil,error);
//            }
//        }];
        
    });
}

#pragma mark Private API

- (NSString* )toSendmessageContentFromContent:(NSString*)content
{
    EmotionsModule* emotionModule = [EmotionsModule shareInstance];
    NSDictionary* unicodeDic = emotionModule.unicodeEmotionDic;
    NSArray* allEmotions = emotionModule.emotions;
    NSMutableString* newContent = [NSMutableString stringWithString:content];
    [allEmotions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString* emotion = (NSString*)obj;
        if ([newContent rangeOfString:emotion].length > 0)
        {
            NSString* placeholder = unicodeDic[emotion];
            NSRange range = NSMakeRange(0, newContent.length);
            [newContent replaceOccurrencesOfString:emotion withString:placeholder options:0 range:range];
        }
    }];
    return newContent;
}


@end
