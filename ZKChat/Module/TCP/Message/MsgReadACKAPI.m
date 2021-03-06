//
//  MsgReadACKAPI.m
//  ZKChat
//
//  Created by 张阔 on 2017/4/23.
//  Copyright © 2017年 张阔. All rights reserved.
//

#import "MsgReadACKAPI.h"
#import "IMMessage.pb.h"
#import "DDTcpProtocolHeader.h"
#import "DDAPIScheduleProtocol.h"
#import "ZKUtil.h"
#import "DDDataOutputStream.h"

@implementation MsgReadACKAPI
/**
 *  请求超时时间
 *
 *  @return 超时时间
 */
- (int)requestTimeOutTimeInterval
{
    return 0;
}

/**
 *  请求的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)requestServiceID
{
    return SID_MSG;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return 0;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return IM_MSG_DATA_READ_ACK;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return 0;
}

/**
 *  解析数据的block
 *
 *  @return 解析数据的block
 */
- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSData* data)
    {
        
    };
    return analysis;
}

/**
 *  打包数据的block
 *
 *  @return 打包数据的block
 */
- (Package)packageRequestObject
{
    Package package = (id)^(id object,uint16_t seqNo)
    {
        IMMsgDataReadAckBuilder *readAck = [IMMsgDataReadAck builder];
        [readAck setUserId:0];
        [readAck setSessionId:[ZKUtil changeIDToOriginal:object[0]]];
        [readAck setMsgId:[object[1] integerValue]];
        [readAck setSessionType:[object[2] integerValue]];
        DDDataOutputStream *dataout = [[DDDataOutputStream alloc] init];
        [dataout writeInt:0];
        [dataout writeTcpProtocolHeader:SID_MSG cId:IM_MSG_DATA_READ_ACK seqNo:seqNo];
        [dataout directWriteBytes:[readAck build].data];
        [dataout writeDataCount];
        return [dataout toByteArray];
    };
    return package;
}
@end
