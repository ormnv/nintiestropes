//
//  ViewController.h
//  windowlicker
//
//  Created by Olga Romanova on 5/2/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "FaceAnimator.hpp"
#import "OpticalFlow.hpp"
#import <CoreMotion/CoreMotion.h>


@interface ViewController : UIViewController<CvVideoCameraDelegate, UIGestureRecognizerDelegate>
{
    CvVideoCamera* videoCamera;
    bool isCapturing;
    FaceAnimator::Parameters parameters;
    cv::Ptr<FaceAnimator> faceAnimator;
    cv::Ptr<OpticalFlow> opticalFlow;
    double currentMaxAccelX;
    double currentMaxAccelY;
    double currentMaxAccelZ;
    double currentAccelX;
    double currentAccelY;
    double currentAccelZ;
    double currentMaxRotX;
    double currentMaxRotY;
    double currentMaxRotZ;
    double currentRotX;
    double currentRotY;
    double currentRotZ;
    float tappedX;
    float tappedY;
    bool faceOn;
    bool flowOn;
    bool colorsOn;

}


@property (strong, nonatomic) IBOutlet UILabel *accX;
@property (strong, nonatomic) IBOutlet UILabel *accY;
@property (strong, nonatomic) IBOutlet UILabel *accZ;

@property (strong, nonatomic) IBOutlet UILabel *maxAccX;
@property (strong, nonatomic) IBOutlet UILabel *maxAccY;
@property (strong, nonatomic) IBOutlet UILabel *maxAccZ;

@property (strong, nonatomic) IBOutlet UILabel *rotX;
@property (strong, nonatomic) IBOutlet UILabel *rotY;
@property (strong, nonatomic) IBOutlet UILabel *rotZ;

@property (strong, nonatomic) IBOutlet UILabel *maxRotX;
@property (strong, nonatomic) IBOutlet UILabel *maxRotY;
@property (strong, nonatomic) IBOutlet UILabel *maxRotZ;

@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startCaptureButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stopCaptureButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *toggleCameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *savevideoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *recordSwitch;
@property (strong, nonatomic) CMMotionManager *motionManager;

- (IBAction)resetMaxValues:(id)sender;
-(IBAction)startCaptureButtonPressed:(id)sender;
-(IBAction)stopCaptureButtonPressed:(id)sender;
-(IBAction)toggleCameraButtonPressed:(id)sender;
-(IBAction)savevideoButtonPressed:(id)sender;
-(IBAction)recordSwitchFlipped:(id)sender;

@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *tapRecognizer;

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer;

//@property (weak, nonatomic) IBOutlet UISegmentedControl *buttons;
//- (IBAction)ButtonsPressed:(id)sender;
//- (IBAction)FirstPressed:(id)sender;
//- (IBAction)SecondPressed:(id)sender;
//- (IBAction)ThirdPressed:(id)sender;
//- (IBAction)FourthPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIToolbar *ColorEffectsButton;
@property (weak, nonatomic) IBOutlet UIToolbar *OpticalFlowButton;
@property (weak, nonatomic) IBOutlet UIToolbar *FaceButton;
- (IBAction)FacePressed:(id)sender;
- (IBAction)OpticalFlowPressed:(id)sender;
- (IBAction)ColorEffectsPressed:(id)sender;

@end





