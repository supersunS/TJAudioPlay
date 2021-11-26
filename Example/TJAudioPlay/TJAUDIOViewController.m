//
//  TJAUDIOViewController.m
//  TJAudioPlay
//
//  Created by SuperSun on 11/25/2021.
//  Copyright (c) 2021 SuperSun. All rights reserved.
//

#import "TJAUDIOViewController.h"
#import "TJAudioPlayManager.h"
#import "TJAudioPlayViewManger.h"

@interface TJAUDIOViewController ()

@end

@implementation TJAUDIOViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIButton *actionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    actionBtn.backgroundColor = [UIColor orangeColor];
    [actionBtn setTitle:@"播放" forState:UIControlStateNormal];
    actionBtn.frame = CGRectMake(0, 0, 100, 100);
    actionBtn.center = self.view.center;
    [actionBtn addTarget:self action:@selector(actionClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:actionBtn];
    
}

-(void)actionClick{
    
    //加载资源
    TJMediaBackGroundModel *model = [[TJMediaBackGroundModel alloc]init];
    model.mediaId = @"1";
    model.coverUrl = @"https://tianjiutest.oss-cn-beijing.aliyuncs.com/tojoy/tojoyClould/backstageSystem/image/1631168736433.jpg";
    model.auther = @"AudioPlayDemo";
    model.mediaUrl = @"https://tianjiutest.oss-cn-beijing.aliyuncs.com/tojoy/tojoyClould/serverUpload/202109/01/image/1630459636944.mp3";
    
    
    //展示UI
    if(true){
        [TJAudioPlayViewManger openBackGround:YES];
        [TJAudioPlayViewManger audioSourceData:@[model]];
        [TJAudioPlayViewManger show];
        [TJAudioPlayViewManger playWithModel:[TJAudioPlayViewManger getAudioSourceData].firstObject];
    }else{
        
        //    不展示UI
        [TJAudioPlayManager openBackGround:YES];
        [TJAudioPlayManager audioSourceData:@[model]];
        [TJAudioPlayManager playWithModel:model];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
