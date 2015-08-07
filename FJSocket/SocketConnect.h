//
//  SocketConnect.h
//  www.dudu.me
//
//  Created by 杨方军 on 15/8/7.
//  Copyright (c) 2015年 www.dudu.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "AsyncUdpSocket.h"

/**
 *  1、基于asyncSocket,进行了json和nsdata的返回数据的封装，封装了心跳包，便于与服务器进行通信
 *  2、asyncSocket为非ARC模式，需要手动切换为arc模式(-fno-objc-arc)
 */



/**
 *  协议方法
 */
@protocol SocketConnectDelegate <NSObject>


- (void)receiveData:(id)object;

@end


@interface SocketConnect : NSObject

enum ReceiveDataType{
    FJJSONRequestSerializer,//返回json数据
    FJHTTPRequestSerializer,//返回二进制数据
};

enum{
    SocketOfflineByServer,//服务器掉线
    SocketOffLineByUser,//用户手动断开
};

@property (assign,nonatomic)id<SocketConnectDelegate>delegate;

//socket通信

@property (strong,nonatomic)NSString *hostIpAddress;//ip地址
@property (assign,nonatomic)NSInteger hostPort;//端口号
@property (strong,nonatomic)NSDictionary *userInfoDic;//用户登录的信息
@property (assign,nonatomic)NSInteger heartTimeInterval;//发送心跳包的时间间隔,默认20秒发送一次

@property (assign,nonatomic)NSInteger withTimeout;//设置socket超时时间,默认为10秒

//tcp Socket
@property (strong,nonatomic)AsyncSocket *tcpSocket;

@property (assign,nonatomic)enum ReceiveDataType receiveDataType;//设置返回接收的数据类型

+ (instancetype)sharedInstance;

/**
 *  登录服务器
 *
 *  @return 登录成功返回yes
 */
- (BOOL)loginServer;

/**
 *  断开socket
 */
- (void)cutOffSocket;




@end
