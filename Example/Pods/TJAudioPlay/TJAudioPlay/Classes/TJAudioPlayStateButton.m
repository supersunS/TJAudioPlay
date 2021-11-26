//
//  TJAudioPlayStateButton.m
//  BossCloud
//
//  Created by SuperSun on 2021/3/31.
//  Copyright © 2021 superSun. All rights reserved.
//

#import "TJAudioPlayStateButton.h"


@interface TJAudioPlayStateButton ()<CAAnimationDelegate>

@property(nonatomic,strong) CAShapeLayer *layerCenter;

@property(nonatomic,strong) CAShapeLayer *layerLeft_1 ;

@property(nonatomic,strong) CAShapeLayer *layerLeft_2;

@property(nonatomic,strong) CAShapeLayer *layerRight_1;

@property(nonatomic,strong) CAShapeLayer *layerRight_2;

@property(nonatomic,strong) CAShapeLayer *bgLayer;

@end


@implementation TJAudioPlayStateButton

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self addAnimationLayer];
    }
    return self;
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if(flag){
        [self startAnimation_2];
    }
}

-(void)startAnimation{
    self.bgLayer.fillColor = [UIColor colorWithRed:48/255.0 green:114/255.0 blue:246/255.0 alpha:1].CGColor;
    
    self.layerCenter.backgroundColor = [UIColor whiteColor].CGColor;
    self.layerLeft_1.backgroundColor = [UIColor whiteColor].CGColor;
    self.layerLeft_2.backgroundColor = [UIColor whiteColor].CGColor;
    self.layerRight_1.backgroundColor = [UIColor whiteColor].CGColor;
    self.layerRight_2.backgroundColor = [UIColor whiteColor].CGColor;
    
    CFTimeInterval duration = 0.3;
    
    
    CABasicAnimation *animation_2 = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    animation_2.removedOnCompletion = NO;
    animation_2.duration = duration; // 动画持续时间
    animation_2.repeatCount = HUGE_VALF; // 重复次数
    animation_2.autoreverses = YES; // 动画结束时执行逆动画
    animation_2.fromValue = [NSNumber numberWithFloat:sin(M_PI/8.0)]; // 开始时的倍率
    animation_2.toValue = [NSNumber numberWithFloat:sin((M_PI/2.0))]; // 结束时的倍率
    [self.layerLeft_2 addAnimation:animation_2 forKey:@"scale-layer"];
    [self.layerRight_2 addAnimation:animation_2 forKey:@"scale-layer"];
    

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    animation.removedOnCompletion = NO;
    animation.duration = duration; // 动画持续时间
    animation.repeatCount = HUGE_VALF; // 重复次数
    animation.autoreverses = YES; // 动画结束时执行逆动画
    animation.fromValue = [NSNumber numberWithFloat:sin(M_PI/2.0)]; // 开始时的倍率
    animation.toValue = [NSNumber numberWithFloat:sin((M_PI/8.0))]; // 结束时的倍率
    [self.layerCenter addAnimation:animation forKey:@"scale-layer"];
    
    
    CABasicAnimation *animation_1 = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    animation_1.delegate = self;
    animation_1.fillMode = kCAFillModeForwards;
    animation_1.removedOnCompletion = NO;
    animation_1.duration = duration/2; // 动画持续时间
    animation_1.repeatCount = 1; // 重复次数
    animation_1.autoreverses = NO; // 动画结束时执行逆动画
    animation_1.toValue = [NSNumber numberWithFloat:sin((M_PI/2.0))]; // 结束时的倍率
    [self.layerLeft_1 addAnimation:animation_1 forKey:@"scale-layer"];
    [self.layerRight_1 addAnimation:animation_1 forKey:@"scale-layer"];
}

-(void)startAnimation_2{
    
    CFTimeInterval duration = 0.3;
    CABasicAnimation *animation_1_1 = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    animation_1_1.removedOnCompletion = NO;
    animation_1_1.duration = duration; // 动画持续时间
    animation_1_1.repeatCount = HUGE_VALF; // 重复次数
    animation_1_1.autoreverses = YES; // 动画结束时执行逆动画
    animation_1_1.fromValue = [NSNumber numberWithFloat:sin(M_PI/2.0)]; // 开始时的倍率
    animation_1_1.toValue = [NSNumber numberWithFloat:sin((M_PI/8.0))]; // 结束时的倍率
    [self.layerLeft_1 addAnimation:animation_1_1 forKey:@"scale-layer"];
    [self.layerRight_1 addAnimation:animation_1_1 forKey:@"scale-layer"];

}

-(void)stopAnimation{
    self.bgLayer.fillColor = [UIColor whiteColor].CGColor;
    
    self.layerCenter.backgroundColor = [UIColor grayColor].CGColor;
    self.layerLeft_1.backgroundColor = [UIColor grayColor].CGColor;
    self.layerLeft_2.backgroundColor = [UIColor grayColor].CGColor;
    self.layerRight_1.backgroundColor = [UIColor grayColor].CGColor;
    self.layerRight_2.backgroundColor = [UIColor grayColor].CGColor;
    
    [self.layerCenter removeAllAnimations];
    [self.layerLeft_1 removeAllAnimations];
    [self.layerLeft_2 removeAllAnimations];
    [self.layerRight_1 removeAllAnimations];
    [self.layerRight_2 removeAllAnimations];
}

-(void)addAnimationLayer{
    
    CGFloat radius = (self.frame.size.width-8)/2;
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width/2, self.frame.size.height/2) radius:radius startAngle:-M_PI/2 endAngle:3*M_PI/2 clockwise:YES];
    [[UIColor whiteColor] set];
    [circlePath stroke];
    
    self.bgLayer = [CAShapeLayer layer];
    self.bgLayer.frame = self.bounds;
    self.bgLayer.fillColor = [UIColor whiteColor].CGColor;
    self.bgLayer.path = circlePath.CGPath;
    [self.layer addSublayer:self.bgLayer];

    
    self.layerCenter = [CAShapeLayer layer];
    self.layerCenter.frame = CGRectMake((self.frame.size.width-2)/2, (self.frame.size.height-12)/2, 2, 12);
    self.layerCenter.backgroundColor = [UIColor grayColor].CGColor;
    self.layerCenter.cornerRadius = 1;
    [self.layer addSublayer:self.layerCenter];
    
    self.layerLeft_1 = [CAShapeLayer layer];
    self.layerLeft_1.frame = CGRectMake((self.frame.size.width-2)/2 - 4, (self.frame.size.height-12)/2, 2, 12);
    self.layerLeft_1.backgroundColor = [UIColor grayColor].CGColor;
    self.layerLeft_1.cornerRadius = 1;
    //初始化高度12 避免圆角拉伸
    self.layerLeft_1.transform = CATransform3DMakeScale(1.0, 6.0/12.0, 1.0);
    [self.layer addSublayer:self.layerLeft_1];
    
    self.layerLeft_2 = [CAShapeLayer layer];
    self.layerLeft_2.frame = CGRectMake((self.frame.size.width-2)/2 - 8, (self.frame.size.height-12)/2, 2, 12);
    self.layerLeft_2.backgroundColor = [UIColor grayColor].CGColor;
    self.layerLeft_2.cornerRadius = 1;
    //初始化高度12 避免圆角拉伸
    self.layerLeft_2.transform = CATransform3DMakeScale(1.0, 3.0/12.0, 1.0);
    [self.layer addSublayer:self.layerLeft_2];
    
    
    self.layerRight_1 = [CAShapeLayer layer];
    self.layerRight_1.frame = CGRectMake((self.frame.size.width-2)/2 + 4, (self.frame.size.height-12)/2, 2, 12);
    self.layerRight_1.backgroundColor = [UIColor grayColor].CGColor;
    self.layerRight_1.cornerRadius = 1;
    //初始化高度12 避免圆角拉伸
    self.layerRight_1.transform = CATransform3DMakeScale(1.0, 6.0/12.0, 1.0);
    [self.layer addSublayer:self.layerRight_1];
    
    self.layerRight_2 = [CAShapeLayer layer];
    self.layerRight_2.frame = CGRectMake((self.frame.size.width-2)/2 + 8, (self.frame.size.height-12)/2, 2, 12);
    self.layerRight_2.backgroundColor = [UIColor grayColor].CGColor;
    self.layerRight_2.cornerRadius = 1;
    //初始化高度12 避免圆角拉伸
    self.layerRight_2.transform = CATransform3DMakeScale(1.0, 3.0/12.0, 1.0);
    [self.layer addSublayer:self.layerRight_2];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
