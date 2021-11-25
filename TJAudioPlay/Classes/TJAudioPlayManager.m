//
//  TJAudioPlayManager.m
//  BossCloud
//
//  Created by SuperSun on 2021/3/29.
//  Copyright © 2021 superSun. All rights reserved.
//

#import "TJAudioPlayManager.h"


@interface TJAudioPlayManager ()<STKAudioPlayerDelegate,STKDataSourceDelegate>


@property(nonatomic,strong) CADisplayLink *displayLink;

/// 检查加载超时定时器
@property(nonatomic,strong) NSTimer *timeoutTimer;

@property(nonatomic,strong)NSArray<TJMediaBackGroundModel *> *dataArray;

@property(nonatomic,strong) STKDataSource* dataSource;
@property(nonatomic,strong) STKAudioPlayer* audioPlayer;

///当前正在播放的model
@property(nonatomic,strong) TJMediaBackGroundModel* playingModel;

//是否开启后台播放
@property(nonatomic,assign)BOOL isOpenBackGround;

@property(nonatomic,assign)BOOL isAutoNextAudio;

///是否处于后台
@property (nonatomic,assign) BOOL  isEnterBackGround;


@property (nonatomic,assign) STKAudioPlayerState audioState;

@property (nonatomic,strong) void(^audioPlayStateChangeBlock)(STKAudioPlayerState audioState);
@property (nonatomic,strong) void(^audioPlayProgressBlock)(float progress);

@end

@implementation TJAudioPlayManager



static TJAudioPlayManager *_shareInstance = nil;

+ (TJAudioPlayManager *)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[super allocWithZone:nil] init];
    });
    return _shareInstance;
}

-(STKAudioPlayer *)audioPlayer{
    if(!_audioPlayer){
        STKAudioPlayerOptions options = {
            .flushQueueOnSeek = YES,
            .enableVolumeMixer = YES,
            .equalizerBandFrequencies = {50, 100, 200, 400, 800, 1600, 2600, 16000},
            .bufferSizeInSeconds = 10
        };
        _audioPlayer = [[STKAudioPlayer alloc] initWithOptions:options];
        _audioPlayer.meteringEnabled = YES;
        _audioPlayer.volume = 1;
        _audioPlayer.delegate = self;
    }
    return _audioPlayer;
}


#pragma mark instance methode

-(BOOL)audioSourceData:(NSArray<TJMediaBackGroundModel *> *)dataArray{
    _dataArray = [[NSArray alloc]initWithArray:dataArray];
    [[TJMediaBackGroundManager shareInstance] updateSoucreCount:[_dataArray count]];
    if([_dataArray count]){
        return YES;
    }
    return NO;
}

-(BOOL)playWithModel:(TJMediaBackGroundModel *)model{
    
    if(!model){
        model = [self.dataArray firstObject];
    }
    if(!model){
        return NO;
    }else{
        BOOL hasValue = NO;
        for (TJMediaBackGroundModel *targetModel in self.dataArray) {
            if([targetModel.mediaId isEqualToString:model.mediaId]){
                hasValue = YES;
                targetModel.mediaLocalPath = model.mediaLocalPath;
                targetModel.mediaUrl = model.mediaUrl;
                break;
            }
        }
        if(!hasValue){
            NSMutableArray *newValueArray = [[NSMutableArray alloc] initWithArray:self.dataArray];
            [newValueArray addObject:model];
            self.dataArray = [[NSArray alloc]initWithArray:newValueArray];
        }
    }
    NSString *Url = model.mediaLocalPath.length?model.mediaLocalPath:@"";
    if(!Url.length){
        Url = model.mediaUrl.length?model.mediaUrl:@"";
    }
    /*
    if(![Url hasSuffix:@"http"]){
        Url =  kGetImageUrl(Url);
    }
     */
    NSURL *mediaUrl = [NSURL URLWithString:Url];
    _dataSource = [STKAudioPlayer dataSourceFromURL:mediaUrl];
    _dataSource.delegate = self;
    [self.audioPlayer setDataSource:_dataSource withQueueItemId:model];
    _playingModel = model;
    return YES;
}

#pragma mark TXLiveAudioSessionDelegate
- (BOOL)setCategory:(NSString *)category withOptions:(AVAudioSessionCategoryOptions)options error:(NSError **)outError{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeMoviePlayback options:AVAudioSessionCategoryOptionAllowAirPlay error:nil];

    BOOL result =  [[AVAudioSession sharedInstance] setActive:YES
                                                        error:nil];
    return result;
}



-(void)pause{
    [self.audioPlayer pause];
}

-(void)resume{
    [self.audioPlayer resume];
}

-(void)stop{
    [self.audioPlayer stop];
}

-(void)destory{
    if(_audioPlayer){
        [_audioPlayer clearQueue];
        [_audioPlayer dispose];
        _audioPlayer.delegate = nil;
        _audioPlayer = nil;
    }
    _playingModel = nil;
    if(_displayLink){
        [_displayLink invalidate];
        _displayLink = nil;
    }
    if(_dataSource){
        _dataSource.delegate = nil;
        _dataSource = nil;
    }
    [self unregisterNSNotification];
    [[TJMediaBackGroundManager shareInstance] updateNowPlayingInfo:nil palyState:NO];
    
}
-(void)seekTime:(float)time{
    [self.audioPlayer seekToTime:time];
}

//下一篇
-(void)nextAudio{
    NSInteger targetIndex = 0;
    for(NSInteger i=0 ; i < [self.dataArray count]; i++ ){
        TJMediaBackGroundModel *model = [self.dataArray objectAtIndex:i];
        NSString *targetId = model.mediaId;
        NSString *currentId = _playingModel.mediaId;
        
        if([targetId isEqualToString:currentId]){
            targetIndex = i+1;
            break;
        }
        
    }
    if(targetIndex > [self.dataArray count]-1){
        targetIndex = 0;
    }
    __weak typeof(self) weakself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TJMediaBackGroundModel *model = weakself.dataArray[targetIndex];
        if(!model.invalidMedia){
            [weakself playWithModel:model];
        }else{
            weakself.playingModel = model;
        }
    });
}

//上一篇
-(void)lastAudio{
    NSInteger targetIndex = 0;
    for(NSInteger i = 0;i<[self.dataArray count]; i++ ){
        TJMediaBackGroundModel *model = [self.dataArray objectAtIndex:i];
        NSString *targetId = model.mediaId;
        NSString *currentId = _playingModel.mediaId;
        
        if([targetId isEqualToString:currentId]){
            targetIndex = i-1;
            break;
        }
    }
    if(targetIndex < 0){
        targetIndex = [self.dataArray count]-1;
    }
    __weak typeof(self) weakself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TJMediaBackGroundModel *model = weakself.dataArray[targetIndex];
        if(!model.invalidMedia){
            [weakself playWithModel:model];
        }else{
            weakself.playingModel = model;
        }
    });
}

-(nullable TJMediaBackGroundModel *)getNowPlayingModelInfo{
    return _playingModel;
}

-(BOOL)getAudioIsPlaying{
    return (_audioState == STKAudioPlayerStatePlaying);
}


-(void)openBackGround:(BOOL)openBackGround{
    _isOpenBackGround = openBackGround;
}

-(void)autoNextAudio:(BOOL)autoNextAudio{
    _isAutoNextAudio = autoNextAudio;
}

-(void)audioPlayStateChangeListener:(void(^)(STKAudioPlayerState audioState))audioPlayStateChangeBlock
                  audioPlayProgress:(void(^)(float progress))progressBlock{
    self.audioPlayStateChangeBlock = audioPlayStateChangeBlock;
    self.audioPlayProgressBlock = progressBlock;
}

//在低系统（如7.1.2）可能收不到这个回调，请在onAppDidEnterBackGround和onAppWillEnterForeground里面处理打断逻辑
- (void)onAudioSessionEvent: (NSNotification *) notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) { //音频被其他app占用
        if([self getAudioIsPlaying]){
            [self pause];
        }
    }else{
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            AVAudioSession *session = [AVAudioSession sharedInstance];
            if(session.category != AVAudioSessionCategoryPlayback){
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeMoviePlayback options:AVAudioSessionCategoryOptionAllowAirPlay error:nil];

                [[AVAudioSession sharedInstance] setActive:YES
                                                     error:nil];
            }
        }
    }
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    __weak typeof(self) weakself = self;
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            //耳机插入
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            //耳机拔出
            dispatch_async(dispatch_get_main_queue(), ^{
                if([weakself getAudioIsPlaying]){
                    [weakself pause];
                }
            });
            break;
    }
}


-(void)onAppWillResignActiveNotification:(UIApplication*)app {
    [self onAppDidEnterBackGround:app];
}

- (void)onAppDidEnterBackGround:(UIApplication*)app {
    if(self.isOpenBackGround){
        [[TJMediaBackGroundManager shareInstance] updateNowPlayingInfo:_playingModel palyState:[self getAudioIsPlaying]];
    }
    
    _isEnterBackGround = YES;
}

- (void)onAppWillEnterForeground:(UIApplication*)app {
    _isEnterBackGround = NO;
}

-(CADisplayLink *)displayLink{
    if(!_displayLink){
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return _displayLink;
}

-(void)displayLinkAction{
    self.playingModel.playbackTime = self.audioPlayer.progress;
    self.playingModel.playbackDuration = self.audioPlayer.duration;
    if(self.audioPlayProgressBlock){
        self.audioPlayProgressBlock(self.audioPlayer.progress/self.audioPlayer.duration);
    }
    if(self.isEnterBackGround && [self getAudioIsPlaying] && self.isOpenBackGround){
        [[TJMediaBackGroundManager shareInstance] updateNowPlayingInfoProgress:self.audioPlayer.progress duration:self.audioPlayer.duration];
    }
}


#pragma mark STKDataSourceDelegate
-(void) dataSourceDataAvailable:(STKDataSource*)dataSource{
    
}

-(void) dataSourceErrorOccured:(STKDataSource*)dataSource{
    
}
-(void) dataSourceEof:(STKDataSource*)dataSource{
    
}


#pragma mark STKAudioPlayerDelegate
/// Raised when an item has started playing
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId{
    self.playingModel.playbackTime = audioPlayer.progress;
    self.playingModel.playbackDuration = audioPlayer.duration;
    if(_isEnterBackGround && self.isOpenBackGround){
        [[TJMediaBackGroundManager shareInstance] updateNowPlayingInfo:self.playingModel  palyState:[self getAudioIsPlaying]];
    }
}

/// Raised when an item has finished buffering (may or may not be the currently playing item)
/// This event may be raised multiple times for the same item if seek is invoked on the player
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId{
    
}
/// Raised when the state of the player has changed
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState{
    _audioState =  state;
    self.displayLink.paused = YES;
    switch (_audioState) {
        case STKAudioPlayerStateReady:{NSLog(@"准备播放");}break;
        case STKAudioPlayerStateRunning:{NSLog(@"已挂载");}break;
        case STKAudioPlayerStatePlaying:{
            NSLog(@"播放");
            self.displayLink.paused = NO;
        }break;
        case STKAudioPlayerStateBuffering:{NSLog(@"加载");}break;
        case STKAudioPlayerStatePaused:{NSLog(@"暂停");}break;
        case STKAudioPlayerStateStopped:{NSLog(@"停止");}break;
        case STKAudioPlayerStateError:{NSLog(@"错误");
            _playingModel.invalidMedia = YES;
            [self stop];
        }break;
        case STKAudioPlayerStateDisposed:{NSLog(@"已销毁");}break;
        default:
            break;
    }
    if(self.audioPlayStateChangeBlock){
        self.audioPlayStateChangeBlock(_audioState);
    }
}
/// Raised when an item has finished playing
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration{
    if (stopReason == STKAudioPlayerStopReasonEof){
        if(self.isAutoNextAudio){
            [self nextAudio];
        }
    }else if (stopReason == STKAudioPlayerStopReasonUserAction){
        
    }else{
        
    }
}
/// Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode{
    if(self.isAutoNextAudio){
        [self nextAudio];
    }else{
        _playingModel.invalidMedia = YES;
        [self stop];
        NSLog(@"音频播放出现错误");
    }
}


- (void)registerNSNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAudioSessionEvent:) name:AVAudioSessionInterruptionNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppWillEnterForeground:) name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification
                                               object:nil];
    if(self.isOpenBackGround){
        [self registerRemoteCommandAction];
    }
}





- (void)unregisterNSNotification{

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    
    if(!self.isOpenBackGround){
        return;
    }
    [[TJMediaBackGroundManager shareInstance] unregisterRemoteCommandAction];
}

-(void)registerRemoteCommandAction{
        
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeMoviePlayback options:AVAudioSessionCategoryOptionAllowAirPlay error:nil];

    [[AVAudioSession sharedInstance] setActive:YES
                                         error:nil];

    __weak typeof(self) weakself = self;
    [[TJMediaBackGroundManager shareInstance] registerRemoteCommandPlayCommandActionBlock:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if(![weakself getAudioIsPlaying]){
            [weakself resume];
            return MPRemoteCommandHandlerStatusSuccess;
        }
        return MPRemoteCommandHandlerStatusCommandFailed;
    } pauseCommandActionBlock:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if([weakself getAudioIsPlaying]){
            [weakself pause];
            return MPRemoteCommandHandlerStatusSuccess;
        }
        return MPRemoteCommandHandlerStatusCommandFailed;
    } nextTrackCommandActionBlock:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [weakself nextAudio];
        return MPRemoteCommandHandlerStatusSuccess;
    } previousTrackCommandActionBlock:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [weakself lastAudio];
        return MPRemoteCommandHandlerStatusSuccess;
    } skipForwardCommandActionBlock:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        float targetSeekTime = weakself.audioPlayer.progress+10.f;
        if(targetSeekTime > weakself.audioPlayer.duration){
            targetSeekTime = weakself.audioPlayer.duration-2.0f;
        }
        [weakself seekTime:targetSeekTime];
        return MPRemoteCommandHandlerStatusSuccess;
    } skipBackwardCommandActionBlock:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        float targetSeekTime = weakself.audioPlayer.progress-10.f;
        if(targetSeekTime < 0){
            targetSeekTime = 0;
        }
        [weakself seekTime:targetSeekTime];
        return MPRemoteCommandHandlerStatusSuccess;
    } changePositionCommandActionBlock:^MPRemoteCommandHandlerStatus(MPChangePlaybackPositionCommandEvent * _Nonnull event) {
        [weakself seekTime:event.positionTime];
        return MPRemoteCommandHandlerStatusSuccess;
    } audioRouteChangeListenerCallback:^(AVAudioSessionRouteChangeReason state,UIEventSubtype subType) {
        if (state == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {//拔出耳机
            if([weakself getAudioIsPlaying]){
                [weakself pause];
            }
        }else{
            if(subType == UIEventSubtypeRemoteControlTogglePlayPause){
                if([weakself getAudioIsPlaying]){
                    [weakself pause];
                }else{
                    [weakself resume];
                }
            }
        }
    } cxCallObserverCallbackL:^(BOOL state) {
        if (state) {//接通
            if([weakself getAudioIsPlaying]){
                [weakself pause];
            }
        }
    } moreData:[self.dataArray count]>1];
}

#pragma mark calss methode


+ (void)registerNSNotification{
    [[self shareInstance] registerNSNotification];
}

+(BOOL)audioSourceData:(NSArray<TJMediaBackGroundModel *> *)dataArray{
    return  [[self shareInstance] audioSourceData:dataArray];
}


+(BOOL)playWithModel:(TJMediaBackGroundModel *)model{
    return [[self shareInstance] playWithModel:model];
}
+(void)pause{
    [[self shareInstance] pause];
}

+(void)resume{
    [[self shareInstance] resume];
}
+(void)stop{
    [[self shareInstance] stop];
}
+(void)destory{
    [[self shareInstance] destory];
}

+(void)seekTime:(float)time{
    [[self shareInstance] seekTime:time];
}

//下一篇
+(void)nextAudio{
    [[self shareInstance] nextAudio];
}

//上一篇
+(void)lastAudio{
    [[self shareInstance] lastAudio];
}

+(nullable TJMediaBackGroundModel *)getNowPlayingModelInfo{
    return [[self shareInstance] getNowPlayingModelInfo];
}

+(BOOL)getAudioIsPlaying{
    return [[self shareInstance] getAudioIsPlaying];
}

+(void)openBackGround:(BOOL)openBackGround{
    [[self shareInstance]openBackGround:openBackGround];
}

+(void)autoNextAudio:(BOOL)autoNextAudio{
    [[self shareInstance]autoNextAudio:autoNextAudio];
}


+(void)audioPlayStateChangeListener:(void(^)(STKAudioPlayerState audioState))audioPlayStateChangeBlock
                  audioPlayProgress:(void(^)(float progress))progressBlock{
    [[self shareInstance] audioPlayStateChangeListener:audioPlayStateChangeBlock audioPlayProgress:progressBlock];
}

+(void)startPlayAudioWithUrl:(NSString *)audioUrl playerStatus:(nonnull void (^)(STKAudioPlayerState))stauts audioPlayProgress:(void(^)(float progress))progress
{
    STKDataSource * aDataSource = [STKAudioPlayer dataSourceFromURL:[NSURL URLWithString:audioUrl]];
    [TJAudioPlayManager shareInstance].audioPlayStateChangeBlock = stauts;
    [TJAudioPlayManager shareInstance].audioPlayProgressBlock = progress;
    if ([[TJAudioPlayManager shareInstance].audioPlayer.currentlyPlayingQueueItemId isEqual:audioUrl]) {
        [[TJAudioPlayManager shareInstance].audioPlayer resume];
        return;
    }
    [[TJAudioPlayManager shareInstance].audioPlayer setDataSource:aDataSource withQueueItemId:audioUrl];
}
+(BOOL)isPlayingItem:(NSString *)itemId
{
    NSString * aCurrentItemId = (NSString *)[TJAudioPlayManager shareInstance].audioPlayer.currentlyPlayingQueueItemId;
    return [aCurrentItemId containsString:itemId];
}

@end
