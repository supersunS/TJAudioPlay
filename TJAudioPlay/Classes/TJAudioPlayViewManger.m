//
//  TJAudioPlayViewManger.m
//  BossCloud
//
//  Created by SuperSun on 2021/3/30.
//  Copyright © 2021 superSun. All rights reserved.
//



#define kBottomPadding  83.0

#define kTopPadding 64.0

#define Ratio(x) (int)(([UIScreen mainScreen].bounds.size.width/375) * (x))

#import "TJAudioPlayViewManger.h"
#import "TJAudioPlayStateButton.h"
#import "TJAudioCircleProgressView.h"

@interface TJAudioPlayViewManger ()

@property(nonatomic,strong) TJAudioPlayView *audioPlayView;

@property(nonatomic,strong) NSArray<TJMediaBackGroundModel *> *currentAudioSourceData;


@property(nonatomic,strong) NSArray<TJMediaBackGroundModel *> *cacheNewAudioSourceData;

@property (nonatomic,strong) void(^audioPlayStateChangeBlock)(STKAudioPlayerState audioState);
@property (nonatomic,strong) void(^audioPlayProgressBlock)(float progress);
@property (nonatomic,strong) void(^prefixActionBlock)(TJMediaBackGroundModel *model);
@property (nonatomic,assign) BOOL viewIsShow;


@end

@implementation TJAudioPlayViewManger


-(void)show{
    __weak typeof(self) weakself = self;

    UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
    [keyWindow addSubview:self.audioPlayView];
    if(!_viewIsShow){
        [TJAudioPlayManager registerNSNotification];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:TJMediaBackGroundRegisterListerNotificationName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TJMediaBackGroundRegisterListerChange:) name:TJMediaBackGroundRegisterListerNotificationName object:nil];
    }
    _viewIsShow = YES;
    
    [TJAudioPlayManager audioPlayStateChangeListener:^(STKAudioPlayerState audioState) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakself.audioPlayView.audioState = audioState;
            if(weakself.audioPlayStateChangeBlock){
                weakself.audioPlayStateChangeBlock(audioState);
            }
        });
    } audioPlayProgress:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakself.audioPlayView.progress = progress;
            if(weakself.audioPlayProgressBlock){
                weakself.audioPlayProgressBlock(progress);
            }
        }); 
    }];
}

-(void)TJMediaBackGroundRegisterListerChange:(NSNotification *)notification{
    [self.audioPlayView closeAudioBtnAction];
}

-(void)disMissView{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TJMediaBackGroundRegisterListerNotificationName object:nil];
    self.currentAudioSourceData = @[];
    self.currentAudioSourceData = @[];
    if(self.audioPlayStateChangeBlock){
        self.audioPlayStateChangeBlock(STKAudioPlayerStateDisposed);
    }
    [self.audioPlayView removeFromSuperview];
    self.audioPlayView = nil;
    _viewIsShow = NO;
}

-(BOOL)audioSourceData:(NSArray<TJMediaBackGroundModel *> * __nullable)dataArray{
    if([self.currentAudioSourceData count]){
        self.cacheNewAudioSourceData = dataArray;//缓存新的数据源
        return NO;
    }
    self.audioPlayView.sourceCount = [dataArray count];
    self.currentAudioSourceData = dataArray;
    [TJAudioPlayManager autoNextAudio:YES];
    
    BOOL result = [TJAudioPlayManager audioSourceData:dataArray];
    return result;
}



-(void)openBackGround:(BOOL)openBackGround{
    [TJAudioPlayManager openBackGround:openBackGround];
}

-(BOOL)playWithModel:(TJMediaBackGroundModel *)model{
    
//    只有开始新的播放才会切换数据源
    if(self.cacheNewAudioSourceData){
        if([self.cacheNewAudioSourceData count]){
            self.currentAudioSourceData = @[];
            [self audioSourceData:self.cacheNewAudioSourceData];
            self.cacheNewAudioSourceData = @[];
        }else{
            NSArray *dataArray = [[NSArray alloc]initWithArray:self.currentAudioSourceData];
            self.currentAudioSourceData = @[];
            [self audioSourceData:dataArray];
            self.cacheNewAudioSourceData = @[];
        }
    }else{
        self.currentAudioSourceData = @[];
        [self audioSourceData:@[]];
        self.cacheNewAudioSourceData = @[];
    }
    if(self.prefixActionBlock){
        self.prefixActionBlock(model);
    }
    BOOL result = [TJAudioPlayManager playWithModel:model];
    return result;
}

-(TJAudioPlayView *)audioPlayView{
    if(!_audioPlayView){
        _audioPlayView = [[TJAudioPlayView alloc]init];
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveAction:)] ;
        [_audioPlayView addGestureRecognizer:panGesture];
    }
    return _audioPlayView;
}

-(void)moveAction:(UIPanGestureRecognizer *)recognizer{
    UIView *targetView = recognizer.view;
    CGPoint center = targetView.center;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateChanged:{
            CGPoint translation = [recognizer translationInView:targetView];
            CGPoint targetPoint = CGPointMake(center.x + translation.x, center.y + translation.y);
            if(targetPoint.x - targetView.frame.size.width/2 <= Ratio(10)){
                targetPoint.x = Ratio(10) + targetView.frame.size.width/2;
            }
            if(targetPoint.x + targetView.frame.size.width/2 >= [UIScreen mainScreen].bounds.size.width - Ratio(10)){
                targetPoint.x = [UIScreen mainScreen].bounds.size.width - Ratio(10) - targetView.frame.size.width/2;
            }
            if(targetPoint.y - targetView.frame.size.height/2 <= kTopPadding){
                targetPoint.y = kTopPadding + targetView.frame.size.height/2;
            }
            if(targetPoint.y + targetView.frame.size.height/2 >= [UIScreen mainScreen].bounds.size.height - kBottomPadding){
                targetPoint.y = [UIScreen mainScreen].bounds.size.height - kBottomPadding - targetView.frame.size.height/2;
            }
            targetView.center = targetPoint;
            [recognizer setTranslation:CGPointZero inView:recognizer.view.superview];
        }
            break;
            
        default:
            break;
    }
    
}

-(void)audioPlayStateChangeListener:(void(^)(STKAudioPlayerState audioState))audioPlayStateChangeBlock
                  audioPlayProgress:(void(^)(float progress))progressBlock{
    self.audioPlayStateChangeBlock = audioPlayStateChangeBlock;
    self.audioPlayProgressBlock = progressBlock;
}

///播放视频前置操作
-(void)audioPlayByModelPrefixAction:(void(^)(TJMediaBackGroundModel *model))prefixAction{
    self.prefixActionBlock = prefixAction;
}


static TJAudioPlayViewManger *_shareInstance = nil;

+ (TJAudioPlayViewManger *)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[super allocWithZone:nil] init];
        _shareInstance.currentAudioSourceData = @[];
        _shareInstance.cacheNewAudioSourceData = @[];
    });
    return _shareInstance;
}



+(void)show{
    [[self shareInstance] show];
}

+(BOOL)audioSourceData:(NSArray<TJMediaBackGroundModel *> *)dataArray{
    return [[self shareInstance]audioSourceData:dataArray];
}


+(BOOL)playWithModel:(TJMediaBackGroundModel *)model{
    return [[self shareInstance]playWithModel:model];
}

+(NSArray<TJMediaBackGroundModel *> *)getAudioSourceData{
    return [self shareInstance].currentAudioSourceData;
}

/// default NO
+(void)openBackGround:(BOOL)openBackGround{
    [[self shareInstance] openBackGround:openBackGround];
}


+(void)audioPlayStateChangeListener:(void(^)(STKAudioPlayerState audioState))audioPlayStateChangeBlock
                  audioPlayProgress:(void(^)(float progress))progressBlock{
    [[self shareInstance] audioPlayStateChangeListener:audioPlayStateChangeBlock audioPlayProgress:progressBlock];
}

///播放视频前置操作
+(void)audioPlayByModelPrefixAction:(void(^)(TJMediaBackGroundModel *model))prefixAction{
    [[self shareInstance]audioPlayByModelPrefixAction:prefixAction];
}


@end



#pragma mark ///////////////////////////////////////  TJAudioPlayView  ///////////////////////////////////////

@interface TJAudioPlayView ()

@property(nonatomic,strong)TJAudioPlayStateButton *openViewBtn;

@property(nonatomic,assign)BOOL isOpenView;
@property(nonatomic,strong)CAShapeLayer *headerShapeLayerCic;
@property(nonatomic,strong)UIView *maskBgView;
@property(nonatomic,strong)UIView *actionBgView;

@property(nonatomic,strong)UIButton *playStateBtn;
@property(nonatomic,strong)UIButton *playNextAudioBtn;
@property(nonatomic,strong)UIButton *closeAudioBtn;

@property(nonatomic,strong)TJAudioCircleProgressView *progressView;

@end

@implementation TJAudioPlayView :UIView

-(instancetype)init{
    self = [super initWithFrame:CGRectMake(Ratio(10), [UIScreen mainScreen].bounds.size.height - kBottomPadding - Ratio(65), Ratio(48), Ratio(48))];
    if(self){
        self.backgroundColor = [UIColor clearColor];
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = Ratio(48)/2;
        [self creatSubView];
        
    }
    return self;
}


-(void)setProgress:(float)progress{
    self.progressView.progress = progress;
}

-(void)setAudioState:(STKAudioPlayerState)audioState{
    if([TJAudioPlayManager getAudioIsPlaying]){
        [_openViewBtn startAnimation];
        [_playStateBtn setImage:[self tj_imageNamed:@"audio_icon_pause"] forState:UIControlStateNormal];
        [_playStateBtn setImage:[self tj_imageNamed:@"audio_icon_pause"] forState:UIControlStateHighlighted];
    }else{
        [_openViewBtn stopAnimation];
        [_playStateBtn setImage:[self tj_imageNamed:@"audio_icon_play"] forState:UIControlStateNormal];
        [_playStateBtn setImage:[self tj_imageNamed:@"audio_icon_play"] forState:UIControlStateHighlighted];
    }
}

-(void)setSourceCount:(NSInteger)sourceCount{
    _sourceCount = sourceCount;
    if(_sourceCount > 1){
        [_playNextAudioBtn setImage:[self tj_imageNamed:@"audio_icon_next"] forState:UIControlStateNormal];
        [_playNextAudioBtn setImage:[self tj_imageNamed:@"audio_icon_next"] forState:UIControlStateHighlighted];
        _playNextAudioBtn.userInteractionEnabled = YES;
    }else{
        [_playNextAudioBtn setImage:[self tj_imageNamed:@"audio_icon_unnext"] forState:UIControlStateNormal];
        [_playNextAudioBtn setImage:[self tj_imageNamed:@"audio_icon_unnext"] forState:UIControlStateHighlighted];
        _playNextAudioBtn.userInteractionEnabled = NO;
    }
}




-(void)creatSubView{

    [self addSubview:self.maskBgView];
    [self.maskBgView addSubview:self.openViewBtn];
    
    [self.maskBgView addSubview:self.progressView];
    
    [self.maskBgView addSubview:self.actionBgView];
    [self.actionBgView addSubview:self.playStateBtn];
    [self.actionBgView addSubview:self.playNextAudioBtn];
    [self.actionBgView addSubview:self.closeAudioBtn];
    
    
    for (NSInteger i = 0; i<3; i++) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(_actionBgView.frame.size.width/3*i, (_actionBgView.frame.size.height-Ratio(18))/2, Ratio(1), Ratio(18));
        layer.backgroundColor = [UIColor colorWithRed:243.0/255.0 green:245.0/255.0 blue:246.0/255.0 alpha:1].CGColor;
        [self.actionBgView.layer addSublayer:layer];
    }
}


-(TJAudioCircleProgressView *)progressView{
    if(!_progressView){
        _progressView = [[TJAudioCircleProgressView alloc]initWithFrame:_maskBgView.bounds];
    }
    return _progressView;
}

-(void)playStateBtnAction:(UIButton *)button{
    if([TJAudioPlayManager getAudioIsPlaying]){
        [TJAudioPlayManager pause];
    }else{
        [TJAudioPlayManager resume];
    }
}
-(void)playNextAudioBtnAction{
    [TJAudioPlayManager nextAudio];
}
-(void)closeAudioBtnAction{
    _isOpenView = YES;
    [self openViewAction];
    self.progressView.progress = 0;
    [TJAudioPlayManager destory];
    [[TJAudioPlayViewManger shareInstance] disMissView];
}

-(void)openViewAction{
    __weak typeof(self) weakself = self;
    if(_isOpenView){
        CGRect tagretFrame = CGRectMake(weakself.frame.origin.x, weakself.frame.origin.y, weakself.frame.size.height, weakself.frame.size.height);
        [UIView animateWithDuration:0.25 animations:^{
            weakself.frame = tagretFrame;
            weakself.maskBgView.frame = CGRectMake(Ratio(4), Ratio(4), tagretFrame.size.width-Ratio(8), tagretFrame.size.height-Ratio(8));
        } completion:^(BOOL finished) {
            weakself.isOpenView = NO;
            [weakself setNeedsDisplay];
        }];
    }else{
        CGFloat targetX = weakself.frame.origin.x;
        if(targetX+Ratio(208) > [UIScreen mainScreen].bounds.size.width - Ratio(10)){
            targetX = [UIScreen mainScreen].bounds.size.width - Ratio(10) - Ratio(208);
        }
        CGRect tagretFrame = CGRectMake(targetX, weakself.frame.origin.y, Ratio(208), weakself.frame.size.height);
        [self setNeedsDisplay];
        [UIView animateWithDuration:0.25 animations:^{
            weakself.frame = tagretFrame;
            weakself.maskBgView.frame = CGRectMake(Ratio(4), Ratio(4), tagretFrame.size.width-Ratio(8), tagretFrame.size.height-Ratio(8));
        } completion:^(BOOL finished) {
            weakself.isOpenView = YES;
            
        }];
    }
}

-(UIView *)maskBgView{
    if(!_maskBgView){
        _maskBgView = [[UIView alloc]initWithFrame:CGRectMake(Ratio(4), Ratio(4), self.frame.size.width-Ratio(8), self.frame.size.width-Ratio(8))];
        _maskBgView.backgroundColor = [UIColor clearColor];
    }
    return _maskBgView;
}

-(UIButton *)openViewBtn{
    if(!_openViewBtn){
        _openViewBtn = [[TJAudioPlayStateButton alloc] initWithFrame:CGRectMake(Ratio(2), Ratio(2), Ratio(36), Ratio(36))];
        _openViewBtn.backgroundColor = [UIColor whiteColor];
        _openViewBtn.layer.cornerRadius = (_openViewBtn.frame.size.width)/2;
        _openViewBtn.layer.masksToBounds = YES;
        [_openViewBtn addTarget:self action:@selector(openViewAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _openViewBtn;
}


-(UIView *)actionBgView{
    if(!_actionBgView){
        _actionBgView = [[UIView alloc]initWithFrame:CGRectMake(Ratio(55), 0, Ratio(200-55), self.frame.size.width-Ratio(8))];
        _actionBgView.backgroundColor = [UIColor clearColor];
        UIBezierPath *headerPathCic = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, _actionBgView.frame.size.width, _actionBgView.frame.size.height) byRoundingCorners:UIRectCornerTopRight|UIRectCornerBottomRight cornerRadii:CGSizeMake(_actionBgView.frame.size.height/2, _actionBgView.frame.size.height/2)];
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = headerPathCic.CGPath;
        layer.fillColor = [UIColor whiteColor].CGColor;
        [_actionBgView.layer insertSublayer:layer atIndex:0];
    }
    return _actionBgView;
}

-(UIButton *)playStateBtn{
    if(!_playStateBtn){
        _playStateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playStateBtn.frame = CGRectMake(0, 0, _actionBgView.frame.size.width/3, _actionBgView.frame.size.height);
        _playStateBtn.backgroundColor = [UIColor whiteColor];
        [_playStateBtn setImage:[self tj_imageNamed:@"audio_icon_play"] forState:UIControlStateNormal];
        [_playStateBtn setImage:[self tj_imageNamed:@"audio_icon_play"] forState:UIControlStateHighlighted];
        [_playStateBtn addTarget:self action:@selector(playStateBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playStateBtn;
}

-(UIButton *)playNextAudioBtn{
    if(!_playNextAudioBtn){
        _playNextAudioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playNextAudioBtn.frame = CGRectMake(_actionBgView.frame.size.width/3, 0, _actionBgView.frame.size.width/3, _actionBgView.frame.size.height);;
        _playNextAudioBtn.backgroundColor = [UIColor whiteColor];
        [_playNextAudioBtn setImage:[self tj_imageNamed:@"audio_icon_next"] forState:UIControlStateNormal];
        [_playNextAudioBtn setImage:[self tj_imageNamed:@"audio_icon_next"] forState:UIControlStateHighlighted];
        [_playNextAudioBtn addTarget:self action:@selector(playNextAudioBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playNextAudioBtn;
}
-(UIButton *)closeAudioBtn{
    if(!_closeAudioBtn){
        _closeAudioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeAudioBtn.frame = CGRectMake(_actionBgView.frame.size.width/3*2, 0, _actionBgView.frame.size.width/3, _actionBgView.frame.size.height);;
        _closeAudioBtn.backgroundColor = [UIColor clearColor];
        [_closeAudioBtn setImage:[self tj_imageNamed:@"audio_icon_close"] forState:UIControlStateNormal];
        [_closeAudioBtn setImage:[self tj_imageNamed:@"audio_icon_close"] forState:UIControlStateHighlighted];
        [_closeAudioBtn addTarget:self action:@selector(closeAudioBtnAction) forControlEvents:UIControlEventTouchUpInside];

    }
    return _closeAudioBtn;
}


-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    UIBezierPath *headerPathCic = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, _maskBgView.frame.size.width, _maskBgView.frame.size.height) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(_maskBgView.frame.size.height/2, _maskBgView.frame.size.height/2)];
    //创建一个CAShapeLayer 图层
    if(_headerShapeLayerCic){
        [_headerShapeLayerCic removeFromSuperlayer];
        _headerShapeLayerCic = nil;
    }
    _headerShapeLayerCic = [CAShapeLayer layer];
    _headerShapeLayerCic.path = headerPathCic.CGPath;
    _headerShapeLayerCic.fillColor = [UIColor whiteColor].CGColor;
    _headerShapeLayerCic.shadowColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.18].CGColor;
    _headerShapeLayerCic.shadowOffset = CGSizeMake(0,0);
    _headerShapeLayerCic.shouldRasterize = YES;
    _headerShapeLayerCic.shadowOpacity = 0.92;
    _headerShapeLayerCic.shadowRadius = 2;
    [_maskBgView.layer insertSublayer:_headerShapeLayerCic atIndex:0];
}



- (NSBundle *)tj_refreshBundle
{
    static NSBundle *refreshBundle = nil;
    if (refreshBundle == nil) {
        NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
        // 获取当前bundle的名称
        NSString *currentBundleName = currentBundle.infoDictionary[@"CFBundleName"];
        refreshBundle = [NSBundle bundleWithPath:[currentBundle pathForResource:currentBundleName ofType:@"bundle"]];
    }
    return refreshBundle;
}

- (UIImage *)tj_imageNamed:(NSString *)imageName
{
    UIImage *image = nil;
    if (image == nil) {
        image = [[UIImage imageWithContentsOfFile:[[self tj_refreshBundle] pathForResource:[NSString stringWithFormat:@"%@@%dx",imageName,(int)[[UIScreen mainScreen]scale]] ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    return image;
}


@end
