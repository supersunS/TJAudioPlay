//
//  TJAudioCircleProgressView.m
//  BossCloud
//
//  Created by SuperSun on 2021/4/12.
//  Copyright © 2021 superSun. All rights reserved.
//

#import "TJAudioCircleProgressView.h"

@interface TJAudioCircleProgressView ()

@property(nonatomic,strong)CAShapeLayer *progressLayer;

@property(nonatomic,strong)CAShapeLayer *bgLayer;

@end

@implementation TJAudioCircleProgressView

-(instancetype)init{
    return [super initWithFrame:CGRectZero];
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        [self creatSubView];
    }
    return self;
}


-(void)setProgress:(float)progress{
    float oldProgress = _progress;
    _progress = progress;
    [self animationWithFromProgress:oldProgress toProgress:progress];
}



- (void)animationWithFromProgress:(float)fromProgress toProgress:(float)toProgress{
    CABasicAnimation *animation_1 = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation_1.fromValue = [NSNumber numberWithDouble:fromProgress];
    animation_1.toValue = [NSNumber numberWithDouble:toProgress];
    if(fromProgress == 0 || toProgress == 0){
        animation_1.duration = 0.25;
    }else{
        animation_1.duration = 0.01;
    }
    animation_1.fillMode = kCAFillModeForwards;
    animation_1.removedOnCompletion = NO;
    [self.progressLayer addAnimation:animation_1 forKey:nil];
}


-(void)creatSubView{
    CGFloat radius = self.frame.size.width/2;
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width/2, self.frame.size.height/2) radius:radius startAngle:-M_PI/2 endAngle:3*M_PI/2 clockwise:YES];
    [[UIColor whiteColor] set];
    circlePath.lineWidth = 2;
    [circlePath stroke];
    
    _bgLayer = [CAShapeLayer layer];
    _bgLayer.frame = self.bounds;
    _bgLayer.fillColor = [UIColor clearColor].CGColor;
    _bgLayer.lineWidth = 2;
    _bgLayer.strokeColor = self.fillColor.CGColor?:[UIColor colorWithRed:243.0/255.0 green:245.0/255.0 blue:246.0/255.0 alpha:1].CGColor;;
    _bgLayer.strokeStart = 0;
    _bgLayer.strokeEnd = 1;
    _bgLayer.lineCap = kCALineCapRound;
    _bgLayer.path = circlePath.CGPath;
    [self.layer addSublayer:_bgLayer];
    
    _progressLayer = [CAShapeLayer layer];
    _progressLayer.frame = self.bounds;
    _progressLayer.fillColor = [UIColor clearColor].CGColor;
    _progressLayer.lineWidth = 2;
    _progressLayer.lineCap = kCALineCapRound;
    _progressLayer.strokeColor =  self.progressColor.CGColor?:[UIColor colorWithRed:48/255.0 green:114/255.0 blue:246/255.0 alpha:1].CGColor;
    _progressLayer.strokeStart = 0;
    _progressLayer.strokeEnd = 0;
    _progressLayer.path = circlePath.CGPath;
    [self.layer addSublayer:_progressLayer];
    
}

-(void)setLineWidth:(float)lineWidth{
    _lineWidth = lineWidth;
    _bgLayer.lineWidth = _lineWidth;
    _progressLayer.lineWidth = _lineWidth;
}

-(void)setProgressColor:(UIColor *)progressColor{
    _progressColor = progressColor;
    _progressLayer.strokeColor =  _progressColor.CGColor?:[UIColor colorWithRed:48/255.0 green:114/255.0 blue:246/255.0 alpha:1].CGColor;
}

-(void)setFillColor:(UIColor *)fillColor{
    _fillColor = fillColor;
    _bgLayer.strokeColor = _fillColor.CGColor?:[UIColor colorWithRed:243.0/255.0 green:245.0/255.0 blue:246.0/255.0 alpha:1].CGColor;;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
