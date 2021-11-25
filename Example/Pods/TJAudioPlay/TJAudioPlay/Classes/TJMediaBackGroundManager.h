//
//  TJMediaBackGroundManager.h
//  BossCloud
//
//  Created by SuperSun on 2021/3/29.
//  Copyright © 2021 superSun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN


extern NSString *const TJMediaBackGroundRegisterListerNotificationName;

extern NSString *const TJMediaBackGroundUnRegisterListerNotificationName;

extern NSString *const TJMediaPlayControllerByHeadsetListerNotificationName;


@interface TJMediaBackGroundModel : NSObject


//资源图片地址
@property(nonatomic,strong)NSString *coverUrl;

//资源图片
@property(nonatomic,strong)UIImage *coverImage;

//资源作者
@property(nonatomic,strong)NSString *auther;

//资源标题
@property(nonatomic,strong)NSString *title;

//资源媒体介绍
@property(nonatomic,strong)NSString *memo;

@property(nonatomic,assign)float playbackTime;
@property(nonatomic,assign)float playbackDuration;

//网络资源地址
@property(nonatomic,strong)NSString *mediaUrl;

//本地资源路径
@property(nonatomic,strong)NSString *mediaLocalPath;

// 是否为无效资源
@property(nonatomic,assign)BOOL invalidMedia;

//媒体资源id 对应相关文章或者短视频Id
@property(nonatomic,strong)NSString *mediaId;


@end


@interface TJMediaBackGroundManager : NSObject


@property(nonatomic,strong)TJMediaBackGroundModel *nowPlayingInfo;

@property(nonatomic,strong)MPRemoteCommandHandlerStatus (^playCommandActionBlock)(MPRemoteCommandEvent *event);

@property(nonatomic,strong)MPRemoteCommandHandlerStatus (^pauseCommandActionBlock)(MPRemoteCommandEvent *event);

@property(nonatomic,strong)MPRemoteCommandHandlerStatus (^nextTrackCommandActionBlock)(MPRemoteCommandEvent *event);

@property(nonatomic,strong)MPRemoteCommandHandlerStatus (^previousTrackCommandActionBlock)(MPRemoteCommandEvent *event);

@property(nonatomic,strong)MPRemoteCommandHandlerStatus (^skipForwardCommandActionBlock)(MPRemoteCommandEvent *event);

@property(nonatomic,strong)MPRemoteCommandHandlerStatus (^skipBackwardCommandActionBlock)(MPRemoteCommandEvent *event);

@property(nonatomic,strong)MPRemoteCommandHandlerStatus (^changePositionCommandActionBlock)(MPChangePlaybackPositionCommandEvent *event);

//插拔耳机监听,以及耳机操作
@property(nonatomic,strong) void(^audioRouteChangeListenerCallback)(AVAudioSessionRouteChangeReason state,UIEventSubtype subType);

//来电通知监听
@property(nonatomic,strong) void(^cxCallObserverCallback)(BOOL state);


+ (TJMediaBackGroundManager *)shareInstance;


-(void)updateNowPlayingInfo:(TJMediaBackGroundModel *__nullable)nowPlayingInfo palyState:(BOOL)isPlay;

-(void)updateNowPlayingInfoProgress:(float)time duration:(float)duration;

-(void)updateSoucreCount:(NSInteger)count;


-(void)registerRemoteCommandPlayCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))playCommandActionBlock
                           pauseCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))pauseCommandActionBlock
                       nextTrackCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))nextTrackCommandActionBlock
                   previousTrackCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))previousTrackCommandActionBlock
                     skipForwardCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))skipForwardCommandActionBlock
                    skipBackwardCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))skipBackwardCommandActionBlock
                  changePositionCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPChangePlaybackPositionCommandEvent *event))changePositionCommandActionBlock
                  audioRouteChangeListenerCallback:(void(^ __nullable)(AVAudioSessionRouteChangeReason state,UIEventSubtype subType))audioRouteChangeListenerCallbackBlock
                           cxCallObserverCallbackL:(void(^ __nullable)(BOOL state))cxCallObserverCallbackBlock
                                          moreData:(BOOL)moreData;

-(void)unregisterRemoteCommandAction;

@end






NS_ASSUME_NONNULL_END
