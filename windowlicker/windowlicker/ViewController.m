//
//  ViewController.m
//  windowlicker
//
//  Created by Olga Romanova on 5/2/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//
#import "ViewController.h"
#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#include "opencv2/core/core.hpp"
#import "opencv2/highgui/cap_ios.h"
#import "opencv2/highgui/ios.h"


@interface ViewController ()

@end

@implementation ViewController

@synthesize imageView;
@synthesize startCaptureButton;
@synthesize toolbar;
@synthesize videoCamera;
@synthesize toggleCameraButton;
@synthesize savevideoButton;
@synthesize ColorEffectsButton;
@synthesize OpticalFlowButton;
@synthesize FaceButton;
@synthesize alphaXSlider;
@synthesize alphaYSlider;
@synthesize alphaZSlider;
@synthesize biasXSlider;
@synthesize BiasYSlider;
@synthesize BiasZSlider;

- (NSInteger)supportedInterfaceOrientations
{
    //only portrait orientation
    return UIInterfaceOrientationMaskPortrait;
}

//important! Use this method over MatToUIImage and UIImageToMat in ios.h. The other methods cause color space issues or memory leaks.
cv::Mat cvMatFromUIImage(UIImage *image)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

UIImage * UIImageFromCVMat(cv::Mat cvMat)
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

//load all images that will be used
-(void) loadAssets
{
    
    NSString* filePath = [[NSBundle mainBundle]
                          pathForResource:@"smileyP" ofType:@"png"];
    UIImage* resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, parameters.smileyP, true);
    cvtColor(parameters.smileyP, parameters.smileyP, CV_BGRA2RGBA);
    
    filePath = [[NSBundle mainBundle]
                pathForResource:@"smileyLL" ofType:@"png"];
    resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, parameters.smileyLL, true);
    cvtColor(parameters.smileyLL, parameters.smileyLL, CV_BGRA2RGBA);
    
    filePath = [[NSBundle mainBundle]
                pathForResource:@"smileyLR" ofType:@"png"];
    resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, parameters.smileyLR, true);
    cvtColor(parameters.smileyLR, parameters.smileyLR, CV_BGRA2RGBA);
    
    filePath = [[NSBundle mainBundle]
                pathForResource:@"smileyPU" ofType:@"png"];
    resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, parameters.smileyPU, true);
    cvtColor(parameters.smileyPU, parameters.smileyPU, CV_BGRA2RGBA);
    
    //Load Cascade Classisiers
    NSString* filename = [[NSBundle mainBundle]
                          pathForResource:@"lbpcascade_frontalface" ofType:@"xml"];
    parameters.face_cascade.load([filename UTF8String]);
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadAssets];
   // [UIBarButtonItem barbuttonitem

    //current effects
    faceOn=false;
    flowOn=false;
    colorsOn=false;
    [self updateBools];

    //rotation and acceleration
    currentMaxAccelX = 0;
    currentMaxAccelY = 0;
    currentMaxAccelZ = 0;
    
    currentAccelX = 0;
    currentAccelY = 0;
    currentAccelZ = 0;
    
    currentMaxRotX = 0;
    currentMaxRotY = 0;
    currentMaxRotZ = 0;
    
    currentRotX = 0;
    currentRotY = 0;
    currentRotZ = 0;
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = .2;
    self.motionManager.gyroUpdateInterval = .2;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 [self setAccelertionData:accelerometerData.acceleration];
                                                 if(error){
                                                     
                                                     NSLog(@"%@", error);
                                                 }
                                             }];
    
//    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
//                                    withHandler:^(CMGyroData *gyroData, NSError *error) {
//                                        [self setRotationData:gyroData.rotationRate];
//                                    }];
    
    
    UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    //recognizer.delegate = self.view;
    [self.imageView addGestureRecognizer:recognizer];
    self.imageView.userInteractionEnabled = YES;
    //self.toolbar.userInteractionEnabled = NO;

    tappedX=0;
    tappedY=0;
    
    self.navigationController.toolbarHidden = NO;


    UIDevice *device = [UIDevice currentDevice];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    [device beginGeneratingDeviceOrientationNotifications];
    
    //cvvideocamera
    self.videoCamera = [[CvVideoCamera alloc]
                        initWithParentView:imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition =
    AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset =
    AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation =
    AVCaptureVideoOrientationLandscapeLeft;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.recordVideo = NO;
    self.videoCamera.rotateVideo = NO;
    
    isCapturing = FALSE;
    
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)setAccelertionData:(CMAcceleration)acceleration
{
    self.accX.text = [NSString stringWithFormat:@" %.2fg",acceleration.x];
    if(fabs(acceleration.x) > fabs(currentMaxAccelX))
    {
        currentMaxAccelX = acceleration.x;
    }
    self.accY.text = [NSString stringWithFormat:@" %.2fg",acceleration.y];
    if(fabs(acceleration.y) > fabs(currentMaxAccelY))
    {
        currentMaxAccelY = acceleration.y;
    }
    self.accZ.text = [NSString stringWithFormat:@" %.2fg",acceleration.z];
    if(fabs(acceleration.z) > fabs(currentMaxAccelZ))
    {
        currentMaxAccelZ = acceleration.z;
    }
    
    currentAccelX = acceleration.x;
    currentAccelY = acceleration.y;
    currentAccelZ = acceleration.z;
    
}

-(void)updateBools
{
    
    NSString * faceString = (faceOn) ? @"faceYes" : @"faceNo";
    NSString * flowString = (flowOn) ? @"flowYes" : @"flowNo";
    NSString * colorString = (colorsOn) ? @"colorYes" : @"colorNo";


//    self.faceon.text = faceString;
//    self.flowon.text =flowString;
//    self.coloron.text = colorString;
    
    NSLog(faceString);
    NSLog(flowString);
    NSLog(colorString);

}

-(float) getAccelertionDataX
{
    return currentAccelX;
}

-(float) getAccelertionDataY
{
    return currentAccelY;
}

-(float) getAccelertionDataZ
{
    return currentAccelZ;
}

-(IBAction)startCaptureButtonPressed:(id)sender
{
    [videoCamera start];
    isCapturing = TRUE;
    
    faceAnimator = new FaceAnimator(parameters);
    opticalFlow = new OpticalFlow();

}

-(IBAction)stopCaptureButtonPressed:(id)sender
{
    [videoCamera stop];
    
    //        NSString* relativePath = [videoCamera.videoFileURL relativePath];
    //        UISaveVideoAtPathToSavedPhotosAlbum(relativePath, self, nil, NULL);
    //
    //        //Alert window
    //        UIAlertView *alert = [UIAlertView alloc];
    //        alert = [alert initWithTitle:@"Camera info"
    //                             message:@"The video was saved to the Gallery!"
    //                            delegate:self
    //                   cancelButtonTitle:@"Continue"
    //                   otherButtonTitles:nil];
    //        [alert show];
    faceOn=false;
    flowOn=false;
    colorsOn=false;
    ColorEffectsButton.tintColor= [UIColor whiteColor];
    OpticalFlowButton.tintColor= [UIColor whiteColor];
    FaceButton.tintColor= [UIColor whiteColor];

    isCapturing = FALSE;
}

-(IBAction)toggleCameraButtonPressed:(id)sender
{
	[videoCamera switchCameras];
}


- (IBAction)resetMaxValues:(id)sender {
    
    currentMaxAccelX = 0;
    currentMaxAccelY = 0;
    currentMaxAccelZ = 0;
    
    currentAccelX = 0;
    currentAccelY = 0;
    currentAccelZ = 0;
    
    currentMaxRotX = 0;
    currentMaxRotY = 0;
    currentMaxRotZ = 0;
    
    currentRotX = 0;
    currentRotY = 0;
    currentRotZ = 0;
    
}

-(UIImage*)generateColors: (UIImage*)uiImage
{
    float green = [self getAccelertionDataX];
    float red = [self getAccelertionDataY];
    float blue = [self getAccelertionDataZ];
    float offset=1;
    float newG=offset+offset*green;
    float newR=offset+offset*red;
    float newB=offset+offset*blue;
    NSLog(@"red X - %f",newR);
    NSLog(@"green Y - %f",newG);
    NSLog(@"blue Z - %f",newB);
    float alpha =1;
    
    float aX=alphaXSlider.value;
    float aY=alphaYSlider.value;
    float aZ=alphaZSlider.value;
    float bX=biasXSlider.value;
    float bY=BiasYSlider.value;
    float bZ=BiasZSlider.value;

    
    CIImage *ciImage = [CIImage imageWithCGImage:uiImage.CGImage];
    CIFilter *colors = [CIFilter filterWithName:@"CIColorMatrix"];
    [colors setValue:ciImage forKey:kCIInputImageKey];
    [colors setValue:[CIVector vectorWithX:newR Y:0 Z:0 W:0] forKey:@"inputRVector"];
    [colors setValue:[CIVector vectorWithX:0 Y:newG Z:0 W:0] forKey:@"inputGVector"];
    [colors setValue:[CIVector vectorWithX:0 Y:0 Z:newB W:0] forKey:@"inputBVector"];
    [colors setValue:[CIVector vectorWithX:aX Y:aY Z:aZ W:alpha] forKey:@"inputAVector"];
    [colors setValue:[CIVector vectorWithX:aZ Y:aY Z:aZ W:0.0] forKey:@"inputBiasVector"];
    CIImage *result = [colors valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:result fromRect:[result extent]];
    UIImage *res = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return res;
}


void rotate(cv::Mat& src, double angle, cv::Mat& dst)
{
    int len = std::max(src.cols, src.rows);
    cv::Point2f pt(len/2., len/2.);
    cv::Mat r = cv::getRotationMatrix2D(pt, angle, 1.0);
    cv::warpAffine(src, dst, r, cv::Size(src.rows, src.cols));
}

- (IBAction)FacePressed:(id)sender {
    
    //if off, turn on!
    if(isCapturing==false){
        [videoCamera start];
        isCapturing = TRUE;
        faceAnimator = new FaceAnimator(parameters);
        opticalFlow = new OpticalFlow();
        faceOn=true;
        FaceButton.tintColor= [UIColor greenColor];
        
    }
    //if on, turn off only face
    else if(faceOn==true && (flowOn==true || colorsOn==true))
    {
        faceOn=false;
        FaceButton.tintColor= [UIColor whiteColor];

    }
    //dont turn on the face
    else if(flowOn==true && colorsOn==true)
    {
        faceOn=false;
        FaceButton.tintColor= [UIColor whiteColor];

    }
    else if(flowOn==true || colorsOn==true)
    {
        faceOn=true;
        FaceButton.tintColor= [UIColor greenColor];
    }
    else if(faceOn==false && flowOn==false && colorsOn==false)
    {
        faceOn=true;
        FaceButton.tintColor= [UIColor greenColor];
    }
    else{
        faceOn=false;
//        [videoCamera stop];
//        isCapturing=FALSE;
        FaceButton.tintColor= [UIColor whiteColor];
    }
}

- (IBAction)OpticalFlowPressed:(id)sender {
    
    //if off, turn on!
    if(isCapturing==false){
        [videoCamera start];
        isCapturing = TRUE;
        faceAnimator = new FaceAnimator(parameters);
        opticalFlow = new OpticalFlow();        flowOn=true;
        OpticalFlowButton.tintColor= [UIColor greenColor];

    }
    //if on, turn off only flow
    else if(flowOn==true && (faceOn==true || colorsOn==true))
    {
        flowOn=false;
        OpticalFlowButton.tintColor= [UIColor whiteColor];

    }
    //don't turn on the 3rd
    else if(faceOn==true && colorsOn==true)
    {
        flowOn=false;
        OpticalFlowButton.tintColor= [UIColor whiteColor];

    }
    else if(faceOn==true || colorsOn==true)
    {
        flowOn=true;
        OpticalFlowButton.tintColor= [UIColor greenColor];

    }
    else if(faceOn==false && flowOn==false && colorsOn==false)
    {
        flowOn=true;
        OpticalFlowButton.tintColor= [UIColor greenColor];
    }
    else{
        flowOn=false;
//        [videoCamera stop];
//        isCapturing=FALSE;
        OpticalFlowButton.tintColor= [UIColor whiteColor];
    }
}

- (IBAction)ColorEffectsPressed:(id)sender {
    
    //if off, turn on!
    if(isCapturing==false){
        [videoCamera start];
        isCapturing = TRUE;
        colorsOn=true;
        ColorEffectsButton.tintColor= [UIColor greenColor];
        faceAnimator = new FaceAnimator(parameters);
        opticalFlow = new OpticalFlow();

    }
    //if on, turn off only face
    else if(colorsOn ==true && (faceOn==true || flowOn==true))
    {
        colorsOn=false;
        ColorEffectsButton.tintColor= [UIColor whiteColor];

    }
    else if(faceOn==true && flowOn==true)
    {
        colorsOn=false;
        ColorEffectsButton.tintColor= [UIColor whiteColor];

    }
    else if(faceOn==true || flowOn==true)
    {
        colorsOn=true;
        ColorEffectsButton.tintColor= [UIColor greenColor];
    }
    else if(faceOn==false && flowOn==false && colorsOn==false)
    {
        colorsOn=true;
        ColorEffectsButton.tintColor= [UIColor greenColor];
    }
    else{
        colorsOn=false;
//        [videoCamera stop];
//        isCapturing=FALSE;
        ColorEffectsButton.tintColor= [UIColor whiteColor];
    }
}

-(void)faceDetect:(cv::Mat&) image
{
        cv::Mat dest;
        UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
        int orientation= -1;
    
        if(deviceOrientation== UIDeviceOrientationPortrait)
        {
            rotate(image, 90, dest);
            orientation =0;
            faceAnimator->detectAndAnimateFaces(dest, image, orientation);
            //image=dest;
        }
        else if(deviceOrientation== UIDeviceOrientationLandscapeRight)
        {
            //LandscapeLeft is default but behavior is wrong
            orientation =1;
            faceAnimator->detectAndAnimateFaces(image, image, orientation);
    
        }
        else if(deviceOrientation== UIDeviceOrientationLandscapeLeft)
        {
            rotate(image, 180, dest);
            orientation =2;
            faceAnimator->detectAndAnimateFaces(dest, image, orientation);
    
        }
        else if(deviceOrientation== UIDeviceOrientationPortraitUpsideDown)
        {
            rotate(image, 270, dest);
            orientation =3;
            faceAnimator->detectAndAnimateFaces(dest, image, orientation);
            
        }
    
}

- (void)processImage:(cv::Mat&)image
{
    cv::Mat dest;
    //int64 timeStart = cv::getTickCount();
    int val=0;
    float magnitude=0;
    float slope=0;
    int faceCount=0;
    float centerness=0;
    std::vector<cv::Rect> faces;
    [self updateBools];
    
    if(faceOn==true && colorsOn==false && flowOn==false){
        [self faceDetect:image];
        faceCount=faceAnimator->getFaceCount();
        centerness=faceAnimator->getAvgCenterness();
        faceAnimator->clearFaceRects();
    }
    else if(colorsOn==true && faceOn==false && flowOn==false){
        UIImage *uiImage = UIImageFromCVMat(image);
        UIImage* imageResult = [self generateColors: uiImage];
        image=cvMatFromUIImage(imageResult);
        cvtColor(image, image, CV_BGR2RGB);
    }
    else if(flowOn==true && faceOn==false && colorsOn==false){
        opticalFlow->trackFlow(image, dest, faces, currentAccelX, currentAccelY, currentAccelZ, tappedX, tappedY);
        image=dest;
        cvtColor(image, image, CV_BGR2RGB);
        magnitude = opticalFlow->getAvgMagnitude();
        slope=opticalFlow->getAvgSlope();
        
    }
    else if(faceOn==true && flowOn==true && colorsOn==false){
        [self faceDetect:image];
        faceCount=faceAnimator->getFaceCount();
        centerness=faceAnimator->getAvgCenterness();
        faces=faceAnimator->getFaceRects();
        opticalFlow->trackFlow(image, dest, faces, currentAccelX, currentAccelY, currentAccelZ, tappedX, tappedY);
        image=dest;
        magnitude = opticalFlow->getAvgMagnitude();
        slope=opticalFlow->getAvgSlope();
        cvtColor(image, image, CV_BGR2RGB);
        //faces.clear();
        faceAnimator->clearFaceRects();
    }
    else if(colorsOn==true && faceOn==true && flowOn==false){
        [self faceDetect:image];
        faceCount=faceAnimator->getFaceCount();
        centerness=faceAnimator->getAvgCenterness();
        UIImage *uiImage = UIImageFromCVMat(image);
        UIImage* imageResult = [self generateColors: uiImage];
        image=cvMatFromUIImage(imageResult);
        cvtColor(image, image, CV_BGR2RGB);
        faceAnimator->clearFaceRects();
    }
    else if(colorsOn==true && flowOn==true && faceOn==false){
        //cvtColor(image, image, CV_BGR2RGB);

        opticalFlow->trackFlow(image, dest, faces, currentAccelX, currentAccelY, currentAccelZ, tappedX, tappedY);
        image=dest;
        magnitude = opticalFlow->getAvgMagnitude();
        slope=opticalFlow->getAvgSlope();
        UIImage *uiImage = UIImageFromCVMat(image);
        UIImage* imageResult = [self generateColors: uiImage];
        image=cvMatFromUIImage(imageResult);
        cvtColor(image, image, CV_BGR2RGB);
    }
    else{
        int i=1;
    }
   
    tappedX=0;
    tappedY=0;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (isCapturing) {
        [videoCamera stop];
    }
    faceOn=false;
    flowOn=false;
    colorsOn=false;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if (touch.view  == self.toolbar) {
        return NO;
    }
    return YES;
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer {
    // Get the location of the gesture
    CGPoint location = [recognizer locationInView:self.view];
    
    //for iphone. Fix this hardcoding.
    //w=288, h=352. UImage size is w=320 and h=427.
    float actualH=427;
    tappedX=location.x*.9;
    tappedY=(actualH-location.y)*.82;
    
    NSLog(@"Tapped X - %f",tappedX);
    NSLog(@"Tapped Y - %f",tappedY);

}


@end


