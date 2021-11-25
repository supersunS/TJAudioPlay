//
//  TJAudioPlayManager.h
//  BossCloud
//
//  Created by SuperSun on 2021/3/29.
//  Copyright © 2021 superSun. All rights reserved.
//  音频文章播放管理

#import <Foundation/Foundation.h>
#import <StreamingKit/STKAudioPlayer.h>
#import "TJMediaBackGroundManager.h"
NS_ASSUME_NONNULL_BEGIN




@interface TJAudioPlayManager : NSObject


+(void)audioPlayStateChangeListener:(void(^)(STKAudioPlayerState audioState))audioPlayStateChangeBlock
                  audioPlayProgress:(void(^)(float progress))progressBlock;


+(nullable TJMediaBackGroundModel *)getNowPlayingModelInfo;


/// default NO
+(void)openBackGround:(BOOL)openBackGround;

///是否自动播放下一首 or 设置资源后自动开始播放
+(void)autoNextAudio:(BOOL)autoNextAudio;

+(BOOL)audioSourceData:(NSArray<TJMediaBackGroundModel *> *)dataArray;

+(BOOL)getAudioIsPlaying;

+(BOOL)playWithModel:(TJMediaBackGroundModel *)model;
+(void)pause;
+(void)resume;
+(void)stop;
+(void)destory;
+(void)seekTime:(float)time;

//下一篇
+(void)nextAudio;

//上一篇
+(void)lastAudio;

+(void)registerNSNotification;

//网络音乐试听  同属音乐播放，但与本类关系不大
+(void)startPlayAudioWithUrl:(NSString *)audioUrl playerStatus:(void(^)(STKAudioPlayerState audioState)) stauts audioPlayProgress:(void(^)(float progress))progress;
+(BOOL)isPlayingItem:(NSString *)itemId;//是否正在播放当前音频
@end

NS_ASSUME_NONNULL_END
