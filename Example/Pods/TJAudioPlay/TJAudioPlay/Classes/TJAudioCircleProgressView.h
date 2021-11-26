//
//  TJAudioCircleProgressView.h
//  BossCloud
//
//  Created by SuperSun on 2021/4/12.
//  Copyright © 2021 superSun. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface TJAudioCircleProgressView : UIView


@property(nonatomic,assign)float progress;

@property(nonatomic,assign)float lineWidth;

@property(nonatomic,strong)UIColor *progressColor;

@property(nonatomic,strong)UIColor *fillColor;

@end

NS_ASSUME_NONNULL_END
