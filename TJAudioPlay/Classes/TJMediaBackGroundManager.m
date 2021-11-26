//
//  TJMediaBackGroundManager.m
//  BossCloud
//
//  Created by SuperSun on 2021/3/29.
//  Copyright © 2021 superSun. All rights reserved.
//

#import "TJMediaBackGroundManager.h"
#import <CallKit/CallKit.h>


// 被新的模块监听
NSString *const TJMediaBackGroundRegisterListerNotificationName = @"TJMediaBackGroundRegisterListerNotificationName";

// 被当前模块取消监听
NSString *const TJMediaBackGroundUnRegisterListerNotificationName = @"TJMediaBackGroundUnRegisterListerNotificationName";


///耳机相关按钮操作
NSString *const TJMediaPlayControllerByHeadsetListerNotificationName = @"TJMediaPlayControllerByHeadsetListerNotificationName";

@implementation TJMediaBackGroundModel

@end


@interface TJMediaBackGroundManager ()<CXCallObserverDelegate>

@property (nonatomic, strong) CXCallObserver * callObserver;

@property (nonatomic, assign) NSInteger routeChangeReason;

@end

@implementation TJMediaBackGroundManager

static TJMediaBackGroundManager *_shareInstance = nil;

+ (TJMediaBackGroundManager *)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[super allocWithZone:nil] init];
    });
    return _shareInstance;
}

#pragma mark 监听来电状态 --------------------

-(CXCallObserver *)callObserver{
    if(!_callObserver){
        _callObserver = [CXCallObserver new];
    }
    return _callObserver;
}


- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call
{
    //接通
    if (call.outgoing && call.hasConnected && !call.hasEnded) {
        if(self.cxCallObserverCallback){
            self.cxCallObserverCallback(YES);
        }
    }
    //挂断
    if (call.outgoing && call.hasConnected && call.hasEnded) {
        if(self.cxCallObserverCallback){
            self.cxCallObserverCallback(NO);
        }
    }
}

-(TJMediaBackGroundModel *)nowPlayingInfo{
    if(_nowPlayingInfo){
        return _nowPlayingInfo;
    }else{
        //设置歌曲时长
        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[center nowPlayingInfo]];
        TJMediaBackGroundModel *currentPlayInfo = [[TJMediaBackGroundModel alloc]init];
        currentPlayInfo.title = [dict objectForKey:MPMediaItemPropertyTitle];
        currentPlayInfo.auther = [dict objectForKey:MPMediaItemPropertyArtist];
        currentPlayInfo.playbackDuration = [[dict objectForKey:MPMediaItemPropertyPlaybackDuration]floatValue];
        currentPlayInfo.playbackTime = [[dict objectForKey:MPNowPlayingInfoPropertyElapsedPlaybackTime] floatValue];
        MPMediaItemArtwork *artwork = [dict objectForKey:MPMediaItemPropertyArtwork];
        UIImage *image = [artwork imageWithSize:CGSizeMake(200, 200)];
        if(!image){
            image = [UIImage imageNamed:@"AppIcon"];
        }
        currentPlayInfo.coverImage = image;
        _nowPlayingInfo = currentPlayInfo;
        return currentPlayInfo;
    }
    return nil;
}

#pragma mark -- MPRemoteCommandAction

-(void)updateNowPlayingInfo:(TJMediaBackGroundModel *__nullable)nowPlayingInfo palyState:(BOOL)isPlay
{
    _nowPlayingInfo = nowPlayingInfo;
    NSMutableDictionary *songInfo = nil;
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",[nowPlayingInfo.coverUrl lastPathComponent]?:@""]];
    if (nowPlayingInfo) {
        songInfo = [[NSMutableDictionary alloc] initWithDictionary:[center nowPlayingInfo]];
        __block UIImage *coverImage = nowPlayingInfo.coverImage;
        if(!coverImage){
            if([fileManager fileExistsAtPath:path]){
                coverImage = [UIImage imageWithContentsOfFile:path];
            }
        }
        if(!coverImage){
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:nowPlayingInfo.coverUrl?:@""] completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                   
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    coverImage = [UIImage imageWithContentsOfFile:path];
                    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(200, 200) requestHandler:^UIImage * _Nonnull(CGSize size) {
                        if(!coverImage){
                            coverImage = [UIImage imageNamed:@"AppIcon"];
                        }
                        return coverImage;
                    }];
                    [songInfo setObject: nowPlayingInfo.title.length?nowPlayingInfo.title:@"" forKey:MPMediaItemPropertyTitle];
                    [songInfo setObject: nowPlayingInfo.auther.length?nowPlayingInfo.auther:@"" forKey:MPMediaItemPropertyArtist];
                    [songInfo setObject: artwork forKey:MPMediaItemPropertyArtwork];
                    [songInfo setObject:[NSNumber numberWithDouble:nowPlayingInfo.playbackDuration] forKey:MPMediaItemPropertyPlaybackDuration];
                    //设置已经播放时长
                    [songInfo setObject:[NSNumber numberWithDouble:nowPlayingInfo.playbackTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
                    [songInfo setValue:[NSNumber numberWithDouble:isPlay?1.0:0.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
                    [songInfo setValue:[NSNumber numberWithDouble:isPlay?1.0:0.0] forKey:MPNowPlayingInfoPropertyDefaultPlaybackRate];
                    [center setNowPlayingInfo:songInfo];
                });
                    
            }];
            [task resume];
        }else{
            
            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(200, 200) requestHandler:^UIImage * _Nonnull(CGSize size) {
                if(!coverImage){
                    coverImage = [UIImage imageNamed:@"AppIcon"];
                }
                return coverImage;
            }];
            [songInfo setObject: nowPlayingInfo.title.length?nowPlayingInfo.title:@"" forKey:MPMediaItemPropertyTitle];
            [songInfo setObject: nowPlayingInfo.auther.length?nowPlayingInfo.auther:@"" forKey:MPMediaItemPropertyArtist];
            [songInfo setObject: artwork forKey:MPMediaItemPropertyArtwork ];
            [songInfo setObject:[NSNumber numberWithDouble:nowPlayingInfo.playbackDuration] forKey:MPMediaItemPropertyPlaybackDuration];
            //设置已经播放时长
            [songInfo setObject:[NSNumber numberWithDouble:nowPlayingInfo.playbackTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
            [songInfo setValue:[NSNumber numberWithDouble:isPlay?1.0:0.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
            [songInfo setValue:[NSNumber numberWithDouble:isPlay?1.0:0.0] forKey:MPNowPlayingInfoPropertyDefaultPlaybackRate];
            [center setNowPlayingInfo:songInfo];
        }
    }else{
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
    }
}

-(void)updateNowPlayingInfoProgress:(float)time duration:(float)duration{
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[center nowPlayingInfo]];
    [dict setObject:[NSNumber numberWithDouble:duration] forKey:MPMediaItemPropertyPlaybackDuration];
    //设置已经播放时长
    [dict setObject:[NSNumber numberWithDouble:time] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [dict setValue:@(1.0) forKey:MPNowPlayingInfoPropertyPlaybackRate];
    [center setNowPlayingInfo:dict];
}

-(MPRemoteCommandHandlerStatus)playCommandAction:(MPRemoteCommandEvent *)event{
    if(self.playCommandActionBlock){
        return self.playCommandActionBlock(event);
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
    
}
-(MPRemoteCommandHandlerStatus)pauseCommandAction:(MPRemoteCommandEvent *)event{
    if(self.pauseCommandActionBlock){
        return self.pauseCommandActionBlock(event);
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

-(MPRemoteCommandHandlerStatus)nextTrackCommandAction:(MPRemoteCommandEvent *)event{
    if(self.nextTrackCommandActionBlock){
        return self.nextTrackCommandActionBlock(event);
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}
-(MPRemoteCommandHandlerStatus)previousTrackCommandAction:(MPRemoteCommandEvent *)event{
    if(self.previousTrackCommandActionBlock){
        return self.previousTrackCommandActionBlock(event);
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}
-(MPRemoteCommandHandlerStatus)skipForwardCommandAction:(MPRemoteCommandEvent *)event{
    if(self.skipForwardCommandActionBlock){
        return self.skipForwardCommandActionBlock(event);
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}
-(MPRemoteCommandHandlerStatus)skipBackwardCommandAction:(MPRemoteCommandEvent *)event{
    if(self.skipBackwardCommandActionBlock){
        return self.skipBackwardCommandActionBlock(event);
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

-(MPRemoteCommandHandlerStatus)changePositionCommandAction:(MPChangePlaybackPositionCommandEvent *)event{
    if(self.changePositionCommandActionBlock){
        return self.changePositionCommandActionBlock(event);
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    _routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    __weak typeof(self) weakself = self;
    switch (_routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:{
            dispatch_async(dispatch_get_main_queue(), ^{
                if(weakself.audioRouteChangeListenerCallback){
                    weakself.audioRouteChangeListenerCallback( weakself.routeChangeReason,0);
                }
            });
        }
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:{
            //耳机拔出
            dispatch_async(dispatch_get_main_queue(), ^{
                if(weakself.audioRouteChangeListenerCallback){
                    weakself.audioRouteChangeListenerCallback(weakself.routeChangeReason,0);
                }
            });
        }
            break;
    }
}


-(void)remoteControlReceivedWithEvent:(NSNotification *)notification{
    UIEventSubtype type = [[notification object] integerValue];
    //type==2  subtype==单击暂停键：103，双击暂停键104
    switch (type) {
        case UIEventSubtypeRemoteControlTogglePlayPause:{
            if(self.audioRouteChangeListenerCallback){
                self.audioRouteChangeListenerCallback(_routeChangeReason,UIEventSubtypeRemoteControlTogglePlayPause);
            }
        }break;
        default:
            break;
    }
}

#pragma mark -- lazy View

-(void)updateSoucreCount:(NSInteger)count{
    MPRemoteCommandCenter *remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    MPRemoteCommand *nextTrackCommand = [remoteCommandCenter nextTrackCommand];
    MPRemoteCommand *previousTrackCommand = [remoteCommandCenter previousTrackCommand];
    MPSkipIntervalCommand *skipForwardCommand = [remoteCommandCenter skipForwardCommand];
    MPSkipIntervalCommand *skipBackwardCommand = [remoteCommandCenter skipBackwardCommand];
    
    if(count){
        [nextTrackCommand setEnabled:YES];
        [previousTrackCommand setEnabled:YES];
        [nextTrackCommand addTarget:self action:@selector(nextTrackCommandAction:)];
        [previousTrackCommand addTarget:self action:@selector(previousTrackCommandAction:)];
    }else{
        [skipForwardCommand setEnabled:YES];
        [skipBackwardCommand setEnabled:YES];
        [skipForwardCommand addTarget:self action:@selector(skipForwardCommandAction:)];
        [skipBackwardCommand addTarget:self action:@selector(skipBackwardCommandAction:)];
    }
}

-(void)registerRemoteCommandAction:(BOOL)moreData{
    [self unregisterRemoteCommandAction];
    [[NSNotificationCenter defaultCenter] postNotificationName:TJMediaBackGroundRegisterListerNotificationName object:nil];
    MPRemoteCommandCenter *remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    MPRemoteCommand *playCommand = [remoteCommandCenter playCommand];
    MPRemoteCommand *pauseCommand = [remoteCommandCenter pauseCommand];
    MPRemoteCommand *nextTrackCommand = [remoteCommandCenter nextTrackCommand];
    MPRemoteCommand *previousTrackCommand = [remoteCommandCenter previousTrackCommand];
    MPSkipIntervalCommand *skipForwardCommand = [remoteCommandCenter skipForwardCommand];
    MPSkipIntervalCommand *skipBackwardCommand = [remoteCommandCenter skipBackwardCommand];
    MPChangePlaybackPositionCommand *changePositionCommand = [remoteCommandCenter changePlaybackPositionCommand];
    
    [playCommand setEnabled:YES];
    [pauseCommand setEnabled:YES];
    [changePositionCommand setEnabled:YES];
    
    [playCommand addTarget:self action:@selector(playCommandAction:)];
    [pauseCommand addTarget:self action:@selector(pauseCommandAction:)];
    [changePositionCommand addTarget:self action:@selector(changePositionCommandAction:)];
    
    
    if(moreData){
        _nextTrackCommandActionBlock?[nextTrackCommand setEnabled:YES]:[nextTrackCommand setEnabled:NO];
        _previousTrackCommandActionBlock?[previousTrackCommand setEnabled:YES]:[previousTrackCommand setEnabled:NO];
        [nextTrackCommand addTarget:self action:@selector(nextTrackCommandAction:)];
        [previousTrackCommand addTarget:self action:@selector(previousTrackCommandAction:)];
    }else{
        _skipForwardCommandActionBlock?[skipForwardCommand setEnabled:YES]:[skipForwardCommand setEnabled:NO];
        _skipBackwardCommandActionBlock?[skipBackwardCommand setEnabled:YES]:[skipBackwardCommand setEnabled:NO];
        [skipForwardCommand addTarget:self action:@selector(skipForwardCommandAction:)];
        [skipBackwardCommand addTarget:self action:@selector(skipBackwardCommandAction:)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:)  name:AVAudioSessionRouteChangeNotification object:nil];//插拔耳机
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteControlReceivedWithEvent:)  name:TJMediaPlayControllerByHeadsetListerNotificationName object:nil];//插拔操作
    
    [self.callObserver setDelegate:self queue:dispatch_get_main_queue()];
    
}



-(void)registerRemoteCommandPlayCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))playCommandActionBlock
                           pauseCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))pauseCommandActionBlock
                       nextTrackCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))nextTrackCommandActionBlock
                   previousTrackCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))previousTrackCommandActionBlock
                     skipForwardCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))skipForwardCommandActionBlock
                    skipBackwardCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPRemoteCommandEvent *event))skipBackwardCommandActionBlock
                  changePositionCommandActionBlock:(MPRemoteCommandHandlerStatus (^ __nullable)(MPChangePlaybackPositionCommandEvent *event))changePositionCommandActionBlock
                  audioRouteChangeListenerCallback:(void(^ __nullable)(AVAudioSessionRouteChangeReason state,UIEventSubtype subType))audioRouteChangeListenerCallbackBlock
                           cxCallObserverCallbackL:(void(^ __nullable)(BOOL state))cxCallObserverCallbackBlock
                                          moreData:(BOOL)moreData{
    
    _playCommandActionBlock             = playCommandActionBlock;
    _pauseCommandActionBlock            = pauseCommandActionBlock;
    _nextTrackCommandActionBlock        = nextTrackCommandActionBlock;
    _previousTrackCommandActionBlock    = previousTrackCommandActionBlock;
    _skipForwardCommandActionBlock      = skipForwardCommandActionBlock;
    _skipBackwardCommandActionBlock     = skipBackwardCommandActionBlock;
    _changePositionCommandActionBlock   = changePositionCommandActionBlock;
    _audioRouteChangeListenerCallback   = audioRouteChangeListenerCallbackBlock;
    _cxCallObserverCallback             = cxCallObserverCallbackBlock;
    
    [self registerRemoteCommandAction:moreData];
    if(audioRouteChangeListenerCallbackBlock){
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
    
    
}


-(void)unregisterRemoteCommandAction{
    [[NSNotificationCenter defaultCenter] postNotificationName:TJMediaBackGroundUnRegisterListerNotificationName object:nil];
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    MPRemoteCommandCenter *remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    MPRemoteCommand *playCommand = [remoteCommandCenter playCommand];
    MPRemoteCommand *pauseCommand = [remoteCommandCenter pauseCommand];
    MPRemoteCommand *nextTrackCommand = [remoteCommandCenter nextTrackCommand];
    MPRemoteCommand *previousTrackCommand = [remoteCommandCenter previousTrackCommand];
    MPSkipIntervalCommand *skipForwardCommand = [remoteCommandCenter skipForwardCommand];
    MPSkipIntervalCommand *skipBackwardCommand = [remoteCommandCenter skipBackwardCommand];
    MPChangePlaybackPositionCommand *changePositionCommand = [remoteCommandCenter changePlaybackPositionCommand];
    
    [playCommand removeTarget:self action:@selector(playCommandAction:)];
    [pauseCommand removeTarget:self action:@selector(pauseCommandAction:)];
    [nextTrackCommand removeTarget:self action:@selector(nextTrackCommandAction:)];
    [previousTrackCommand removeTarget:self action:@selector(previousTrackCommandAction:)];
    [skipForwardCommand removeTarget:self action:@selector(skipForwardCommandAction:)];
    [skipBackwardCommand removeTarget:self action:@selector(skipBackwardCommandAction:)];
    [changePositionCommand removeTarget:self action:@selector(changePositionCommandAction:)];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TJMediaPlayControllerByHeadsetListerNotificationName
                                                  object:nil];
    
    
    [_callObserver setDelegate:nil queue:0];
    _callObserver = nil;
}


@end
