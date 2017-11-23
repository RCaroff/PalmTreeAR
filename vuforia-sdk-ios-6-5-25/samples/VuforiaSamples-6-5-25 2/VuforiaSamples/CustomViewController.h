//
//  CustomViewController.h
//  VuforiaSamples
//
//  Created by Clément Casamayou on 23/11/2017.
//  Copyright © 2017 PTC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserDefinedTargetsEAGLView.h"
#import "SampleApplicationSession.h"
#import "SampleAppMenuViewController.h"
#import <Vuforia/DataSet.h>

@interface CustomViewController : UIViewController <SampleApplicationControl> {
    Vuforia::DataSet *dataSetUserDef;
    RefFreeFrame *refFreeFrame;
}

@property (nonatomic, strong) UserDefinedTargetsEAGLView *eaglView;
@property (nonatomic, strong) SampleApplicationSession *vapp;

@end
