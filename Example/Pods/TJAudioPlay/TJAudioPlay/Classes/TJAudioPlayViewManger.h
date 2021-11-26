//
//  TJAudioPlayViewManger.h
//  BossCloud
//
//  Created by SuperSun on 2021/3/30.
//  Copyright © 2021 superSun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TJAudioPlayManager.h"

NS_ASSUME_NONNULL_BEGIN

/// 资源占用冲突需要关闭播放器 发送   TJMediaBackGroundRegisterListerNotificationName 通知即可

@interface TJAudioPlayViewManger : NSObject


/// default NO
+(void)openBackGround:(BOOL)openBackGround;
///必须先设置资源再执行 show ，不然 会造成监听错误
+(BOOL)audioSourceData:(NSArray<TJMediaBackGroundModel *> * __nullable)dataArray;


+(void)show;

+(BOOL)playWithModel:(TJMediaBackGroundModel *)model;


+(NSArray<TJMediaBackGroundModel *> *)getAudioSourceData;

+(void)audioPlayStateChangeListener:(void(^)(STKAudioPlayerState audioState))audioPlayStateChangeBlock
                  audioPlayProgress:(void(^)(float progress))progressBlock;

///播放视频前置操作
+(void)audioPlayByModelPrefixAction:(void(^)(TJMediaBackGroundModel *model))prefixAction;


@end


#pragma mark -------------------------------------TJAudioPlayView-------------------------------------

@interface TJAudioPlayView : UIView

@property(nonatomic,assign)float progress;

@property(nonatomic,assign)STKAudioPlayerState audioState;

@property(nonatomic,assign)NSInteger sourceCount;

-(void)closeAudioBtnAction;

@end


NS_ASSUME_NONNULL_END
