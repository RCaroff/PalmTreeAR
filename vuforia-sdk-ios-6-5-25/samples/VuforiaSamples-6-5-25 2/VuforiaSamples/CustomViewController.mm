//
//  CustomViewController.m
//  VuforiaSamples
//
//  Created by Clément Casamayou on 23/11/2017.
//  Copyright © 2017 PTC. All rights reserved.
//

#import "CustomViewController.h"
#import "VuforiaSamplesAppDelegate.h"
#import <Vuforia/ObjectTracker.h>

@implementation CustomViewController

@synthesize vapp, eaglView;

- (CGRect)getCurrentARViewFrame
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect viewFrame = screenBounds;
    
    // If this device has a retina display, scale the view bounds
    // for the AR (OpenGL) view
    if (YES == vapp.isRetinaDisplay) {
        viewFrame.size.width *= [UIScreen mainScreen].nativeScale;
        viewFrame.size.height *= [UIScreen mainScreen].nativeScale;
    }
    return viewFrame;
}

-(void)loadView{
    vapp = [[SampleApplicationSession alloc] initWithDelegate:self];
    
    CGRect viewFrame = [self getCurrentARViewFrame];
    
    refFreeFrame = new RefFreeFrame();
    eaglView = [[UserDefinedTargetsEAGLView alloc] initWithFrame:viewFrame appSession:vapp];
    [eaglView setBackgroundColor:UIColor.clearColor];
    [eaglView setRefFreeFrame: refFreeFrame];
    [self setView:eaglView];
    VuforiaSamplesAppDelegate *appDelegate = (VuforiaSamplesAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = eaglView;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(pauseAR)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(resumeAR)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    
    [vapp initAR:Vuforia::GL_20 orientation:self.interfaceOrientation];
    
    refFreeFrame->stopImageTargetBuilder();
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goodFrameQuality:)
                                                 name:@"kGoodFrameQuality"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(badFrameQuality:)
                                                 name:@"kBadFrameQuality"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(trackableCreated:)
                                                 name:@"kTrackableCreated"
                                               object:nil];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight {
    [eaglView configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight];
}

- (void)onVuforiaUpdate:(Vuforia::State *)state{
    
}

- (bool)doDeinitTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    trackerManager.deinitTracker(Vuforia::ObjectTracker::getClassType());
    return true;
}

- (bool)doInitTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* trackerBase = trackerManager.initTracker(Vuforia::ObjectTracker::getClassType());
    if (trackerBase == NULL)
    {
        NSLog(@"Failed to initialize ObjectTracker.");
        return false;
    }
    return true;
}

- (bool)doLoadTrackersData {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    if (objectTracker != nil)
    {
        // Create the data set:
        dataSetUserDef = objectTracker->createDataSet();
        if (dataSetUserDef != nil)
        {
            if (!objectTracker->activateDataSet(dataSetUserDef))
            {
                NSLog(@"Failed to activate data set.");
                return false;
            }
        }
    }
    return true;
}

- (bool)doStartTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    if(tracker == 0) {
        return false;
    }
    tracker->start();
    return true;
}

- (bool)doStopTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    
    if (NULL == tracker) {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return false;
    }
    
    tracker->stop();
    return true;
}

- (bool)doUnloadTrackersData {
    return true;
}

- (void)onInitARDone:(NSError *)error {
    if (error == nil) {
        NSError * error = nil;
        
        CGRect buttonFrame = CGRectMake(self.view.frame.size.width / 3,
                                         self.view.frame.size.height - 70,
                                         self.view.frame.size.width / 3,
                                         40);
        
        UIButton* button = [[UIButton alloc] initWithFrame:buttonFrame];
        [button setTitle:@"Save" forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor whiteColor]];
        [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor grayColor] forState:UIControlStateFocused];
        [button addTarget:self action:@selector(didClick) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        
        [self setCameraMode];
        
        [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];
        [eaglView updateRenderingPrimitives];
        
    } else {
        NSLog(@"Error initializing AR:%@", [error description]);
        
        dispatch_async( dispatch_get_main_queue(), ^{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[error localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        });
    }
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    
}

- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    
}

- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    
}

- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator {
    
}

- (void)setNeedsFocusUpdate {
    
}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
    return true;
}

- (void)updateFocusIfNeeded {
    
}

- (void) pauseAR {
    NSError * error = nil;
    if (![vapp pauseAR:&error]) {
        NSLog(@"Error pausing AR:%@", [error description]);
    }
}

- (void) resumeAR {
    NSError * error = nil;
    if(! [vapp resumeAR:&error]) {
        NSLog(@"Error resuming AR:%@", [error description]);
    }
    [eaglView updateRenderingPrimitives];
    
}

- (void) didClick {
    if (refFreeFrame->isImageTargetBuilderRunning() == YES)
    {
        refFreeFrame->startBuild();
    }
}

-(void)setCameraMode
{
    refFreeFrame->startImageTargetBuilder();
}

- (void)goodFrameQuality:(NSNotification *)aNotification
{
    //NSLog(@">> goodFrameQuality");
}

- (void)badFrameQuality:(NSNotification *)aNotification
{
    //NSLog(@">> badFrameQuality");
}

- (void)trackableCreated:(NSNotification *)aNotification
{
    // we restart the camera mode once a target has been added
    [self setCameraMode];
}

@end
