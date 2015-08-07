//
//  SocketConnect.h
//  www.dudu.me
//
//  Created by 杨方军 on 15/8/7.
//  Copyright (c) 2015年 www.dudu.me. All rights reserved.
//
#import "SocketConnect.h"

@interface SocketConnect ()

@property (strong,nonatomic)NSTimer *timer;//计时器，用于发送心跳包

@end


@implementation SocketConnect

#pragma mark - 懒加载


- (AsyncSocket *)tcpSocket{

    if (!_tcpSocket) {
        _tcpSocket = [[AsyncSocket alloc]initWithDelegate:self];
    }
    return _tcpSocket;
}


- (NSDictionary *)userInfoDic{

    if (!_userInfoDic) {
        _userInfoDic  = [NSDictionary dictionary];
    }
    return _userInfoDic;
}

//懒加载结束

#pragma mark - 初始化单例对象
+ (instancetype)sharedInstance{
    
    static SocketConnect *socketConnect = nil;
    static dispatch_once_t oneToken;
    
    dispatch_once(&oneToken, ^{
        
         socketConnect = [[SocketConnect alloc]init];
    });
    return socketConnect;
}


#pragma mark - 连接服务器
- (BOOL)loginServer{
    NSError *error = nil;
    static BOOL success;
    if (!self.tcpSocket.isConnected) {
        success = [self.tcpSocket connectToHost:self.hostIpAddress onPort:self.hostPort error:&error];
        
    }
    if (success) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.userInfoDic options:NSJSONWritingPrettyPrinted error:nil];
        [self sendInfo:data];
    }
    return success;
}

#pragma mark - 发送数据到服务器
- (void)sendInfo:(NSData *)data{
    
    [self.tcpSocket writeData:data withTimeout:self.withTimeout == 0 ? 10 : self.withTimeout tag:0];
    
}

#pragma mark - 通过socket协议方法，发送心跳包

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    [self.tcpSocket readDataWithTimeout:-1 tag:0];
    
    //设置心跳包默认20秒发送一次
    NSInteger heartPackTime = self.heartTimeInterval == 0 ? 20 : self.heartTimeInterval;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:heartPackTime target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
}



- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    if (self.receiveDataType == FJJSONRequestSerializer ) {
//        NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//        NSDictionary *dic = @{@"data" : str};
        NSError *error = nil;
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves|NSJSONReadingAllowFragments error:&error];
        [self.delegate receiveData:error ? error.localizedDescription : dic];
    }else{
        [self.delegate receiveData:data];
    }
    //设置30秒超时
    [self.tcpSocket readDataWithTimeout:30 tag:0];
}


#pragma mark - 长连接 发送心跳包
- (void)longConnectToSocket{
    static int i = 0;
    NSString *longStr = [NSString stringWithFormat:@"%d\n",i];
    i += 20;
    [self.tcpSocket writeData:[longStr dataUsingEncoding:NSUTF8StringEncoding] withTimeout:2 tag:1];
}

- (void)cutOffSocket{

    self.tcpSocket.userData = SocketOffLineByUser;
    [self.timer invalidate];//关闭心跳包的发送
    [self.tcpSocket disconnect];//tcpStock失去连接
}


#pragma mark - 断线重连接
- (void)onSocketDidDisconnect:(AsyncSocket *)sock{
    
    //如果是服务器断线，重连接
    if (sock.userData == SocketOfflineByServer ) {
        //连服务器
        [self loginServer];
    }else{
    
    //用户手动断开
        return;
    }

}






@end
