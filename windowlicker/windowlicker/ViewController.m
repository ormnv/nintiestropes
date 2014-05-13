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
    
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                    withHandler:^(CMGyroData *gyroData, NSError *error) {
                                        [self setRotationData:gyroData.rotationRate];
                                    }];
    
    
    UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    //recognizer.delegate = self.view;
    [self.imageView addGestureRecognizer:recognizer];
    self.imageView.userInteractionEnabled = YES;
    //self.toolbar.userInteractionEnabled = NO;

    tappedX=0;
    tappedY=0;
    
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

-(void)setRotationData:(CMRotationRate)rotation
{
    
    self.rotX.text = [NSString stringWithFormat:@" %.2fr/s",rotation.x];
    if(fabs(rotation.x) > fabs(currentMaxRotX))
    {
        currentMaxRotX = rotation.x;
    }
    self.rotY.text = [NSString stringWithFormat:@" %.2fr/s",rotation.y];
    if(fabs(rotation.y) > fabs(currentMaxRotY))
    {
        currentMaxRotY = rotation.y;
    }
    self.rotZ.text = [NSString stringWithFormat:@" %.2fr/s",rotation.z];
    if(fabs(rotation.z) > fabs(currentMaxRotZ))
    {
        currentMaxRotZ = rotation.z;
    }
    
    self.maxRotX.text = [NSString stringWithFormat:@" %.2f",currentMaxRotX];
    self.maxRotY.text = [NSString stringWithFormat:@" %.2f",currentMaxRotY];
    self.maxRotZ.text = [NSString stringWithFormat:@" %.2f",currentMaxRotZ];
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
//
//-(IBAction)FirstPressed:(id)sender{
//    UISegmentedControl *buttons = sender;
//    NSInteger index = [buttons selectedSegmentIndex];
//    NSLog(@"first");
//
////    [videoCamera start];
////    isCapturing = TRUE;
////    
////    faceAnimator = new FaceAnimator(parameters);
////    opticalFlow = new OpticalFlow();
//
//}

//
//-(IBAction)ButtonsPressed:(id)sender
//{
//    //UISegmentedControl *buttons = sender;
//    NSInteger index = [buttons selectedSegmentIndex];
//    NSLog(@"buttons");
//    
//    //    [videoCamera start];
//    //    isCapturing = TRUE;
//    //
//    //    faceAnimator = new FaceAnimator(parameters);
//    //    opticalFlow = new OpticalFlow();
//    NSString* label= [buttons titleForSegmentAtIndex: [buttons selectedSegmentIndex]];
//    NSLog(label);
//    
//    
//}

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
    
    isCapturing = FALSE;
}

-(IBAction)toggleCameraButtonPressed:(id)sender
{
	[videoCamera switchCameras];
}


-(void)generateCVEffects: (cv::Mat&)src, int deviceOrientation
{
    float faceCount = faceAnimator->getFaceCount();
    float avgCenterness = faceAnimator->getAvgCenterness();
    float avgFaceSize = faceAnimator->getAvgFaceSize();
    //cv::Mat imageMatrix = [self cvMatFromUIImage:src];
    cv::GaussianBlur( src, src, cv::Size(3,3), faceCount*3, 0);
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

    
    CIImage *ciImage = [CIImage imageWithCGImage:uiImage.CGImage];
    CIFilter *colors = [CIFilter filterWithName:@"CIColorMatrix"];
    [colors setValue:ciImage forKey:kCIInputImageKey];
    [colors setValue:[CIVector vectorWithX:newR Y:0 Z:0 W:0] forKey:@"inputRVector"];
    [colors setValue:[CIVector vectorWithX:0 Y:newG Z:0 W:0] forKey:@"inputGVector"];
    [colors setValue:[CIVector vectorWithX:0 Y:0 Z:newB W:0] forKey:@"inputBVector"];
    [colors setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:alpha] forKey:@"inputAVector"];
    [colors setValue:[CIVector vectorWithX:1 Y:0 Z:0 W:0.0] forKey:@"inputBiasVector"];
    CIImage *result = [colors valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:result fromRect:[result extent]];
    UIImage *res = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return res;
}

-(UIImage*)generateTwirl: (UIImage*)uiImage
{
    float centerX=150;
    float centerY=150;
    if (tappedX!=0 && tappedY!=0) {
        centerX=tappedX;
        centerY=tappedY;
    }
    
    //all twirl code here
    CIImage *ciImage = [CIImage imageWithCGImage:uiImage.CGImage];
    CIFilter *twirl = [CIFilter filterWithName:@"CITwirlDistortion"];
    [twirl setValue:ciImage forKey:kCIInputImageKey];
    CIVector *vVector = [CIVector vectorWithX:centerX Y:centerY];
    [twirl setValue:vVector forKey:@"inputCenter"];
    [twirl setValue:[NSNumber numberWithFloat:150.0f] forKey:@"inputRadius"];
    [twirl setValue:[NSNumber numberWithFloat:3.14f] forKey:@"inputAngle"];
    CIImage *result = [twirl valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:result fromRect:[result extent]];
    UIImage *res = [UIImage imageWithCGImage:cgImage];
    
    //out of the method just here for reference
    //UIImageToMat(imageResult, image);
    //cvtColor(image, image, CV_BGR2RGB);
    
    //crashes the app with causes memory leak without
    CGImageRelease(cgImage);
    return res;

}


-(UIImage*)generateHole: (UIImage*)uiImage
{
    float centerX=150;
    float centerY=150;
    if (tappedX!=0 && tappedY!=0) {
        centerX=tappedX;
        centerY=tappedY;
    }
    
    //all twirl code here
    CIImage *ciImage = [CIImage imageWithCGImage:uiImage.CGImage];
    CIFilter *hole = [CIFilter filterWithName:@"CIHoleDistortion"];
    [hole setValue:ciImage forKey:kCIInputImageKey];
    CIVector *vVector = [CIVector vectorWithX:centerX Y:centerY];
    [hole setValue:vVector forKey:@"inputCenter"];
    [hole setValue:[NSNumber numberWithFloat:150.0f] forKey:@"inputRadius"];
    CIImage *result = [hole valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:result fromRect:[result extent]];
    UIImage *res = [UIImage imageWithCGImage:cgImage];
    
    //out of the method just here for reference
    //UIImageToMat(imageResult, image);
    //cvtColor(image, image, CV_BGR2RGB);
    
    //crashes the app with causes memory leak without
    CGImageRelease(cgImage);
    return res;
    
}

-(void)generateCoreEffects: (cv::Mat&)src, int deviceOrientation
{
    //    float faceCount = faceAnimator->getFaceCount();
    //    float avgCenterness = faceAnimator->getAvgCenterness();
    //    float avgFaceSize = faceAnimator->getAvgFaceSize();
    //    //cv::Mat imageMatrix = [self cvMatFromUIImage:src];
    //    cv::GaussianBlur( src, src, cv::Size(3,3), faceCount*5);
    
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
    }
    //if on, turn off only face
    else if(faceOn==true && (flowOn==true || colorsOn==true))
    {
        faceOn=false;
    }
    //dont turn on the face
    else if(flowOn==true && colorsOn==true)
    {
        faceOn=false;
    }
    else if(flowOn==true || colorsOn==true)
    {
        faceOn=true;
    }
}

- (IBAction)OpticalFlowPressed:(id)sender {
    
    //if off, turn on!
    if(isCapturing==false){
        [videoCamera start];
        isCapturing = TRUE;
        
        opticalFlow = new OpticalFlow();
        flowOn=true;
    }
    //if on, turn off only flow
    else if(flowOn==true && (faceOn==true || colorsOn==true))
    {
        flowOn=false;
    }
    //don't turn on the 3rd
    else if(faceOn==true && colorsOn==true)
    {
        flowOn=false;
    }
    else if(faceOn==true || colorsOn==true)
    {
        flowOn=true;
    }
}

- (IBAction)ColorEffectsPressed:(id)sender {
    
    //if off, turn on!
    if(isCapturing==false){
        [videoCamera start];
        isCapturing = TRUE;
        
        colorsOn=true;
    }
    //if on, turn off only face
    else if(colorsOn ==true && (faceOn==true || flowOn==true))
    {
        colorsOn=false;
    }
    else if(faceOn==true && flowOn==true)
    {
        colorsOn=false;
    }
    else if(faceOn==true || flowOn==true)
    {
        colorsOn=true;
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
    
    
    if(faceOn==true){
        [self faceDetect:image];
        faceCount=faceAnimator->getFaceCount();
        centerness=faceAnimator->getAvgCenterness();
        faceAnimator->clearFaceRects();
    }
    else if(colorsOn==true){
        UIImage *uiImage = UIImageFromCVMat(image);
        UIImage* imageResult = [self generateColors: uiImage];
        image=cvMatFromUIImage(imageResult);
        cvtColor(image, image, CV_BGR2RGB);
    }
    else if(flowOn==true){
        opticalFlow->trackFlow(image, dest, faces, currentAccelX, currentAccelY, currentAccelZ, tappedX, tappedY);
        image=dest;
        cvtColor(image, image, CV_BGR2RGB);
        magnitude = opticalFlow->getAvgMagnitude();
        slope=opticalFlow->getAvgSlope();
        
    }
    else if(faceOn==true && flowOn==true){
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
    else if(colorsOn==true && faceOn==true){
        [self faceDetect:image];
        faceCount=faceAnimator->getFaceCount();
        centerness=faceAnimator->getAvgCenterness();
        UIImage *uiImage = UIImageFromCVMat(image);
        UIImage* imageResult = [self generateColors: uiImage];
        image=cvMatFromUIImage(imageResult);
        cvtColor(image, image, CV_BGR2RGB);
        faceAnimator->clearFaceRects();
    }
    else if(colorsOn==true && flowOn==true){
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
    
    }
    
    
    
//    switch (val) {
//        case 0:
//        {
//
//
//            break;
//        }
//        case 1:
//        {
//            //faceAnimator->detectAndAnimateFaces(image, dest, 1);
//            [self faceDetect:image];
//            faceCount=faceAnimator->getFaceCount();
//            centerness=faceAnimator->getAvgCenterness();
//            
//            //image=dest;
//            //cvtColor(image, image, CV_BGR2RGB);
//
//            break;
//        }
//        case 2:
//        {
//            UIImage *uiImage = UIImageFromCVMat(image);
//            
//            
//            UIImage* imageResult = [self generateColors: uiImage];
//            
//            
//            image=cvMatFromUIImage(imageResult);
//            
//            cvtColor(image, image, CV_BGR2RGB);
//
//            break;
//        }
//        case 3:
//        {
//            opticalFlow->trackFlow(image, dest, faces, currentAccelX, currentAccelY, currentAccelZ, tappedX, tappedY);
//            image=dest;
//            magnitude = opticalFlow->getAvgMagnitude();
//            slope=opticalFlow->getAvgSlope();
//            
//            UIImage *uiImage = UIImageFromCVMat(image);
//            
//            
//            UIImage* imageResult = [self generateColors: uiImage];
//            
//            
//            image=cvMatFromUIImage(imageResult);
//            
//            cvtColor(image, image, CV_BGR2RGB);
//            break;
//        }
//        case 4:
//        {
//            //faceAnimator->detectAndAnimateFaces(image, dest, 1);
//            [self faceDetect:image];
//            faceCount=faceAnimator->getFaceCount();
//            centerness=faceAnimator->getAvgCenterness();
//            
//            UIImage *uiImage = UIImageFromCVMat(image);
//            
//            UIImage* imageResult = [self generateColors: uiImage];
//            
//            
//            image=cvMatFromUIImage(imageResult);
//            
//            cvtColor(image, image, CV_BGR2RGB);
//
//            break;
//        }
//        case 5:
//        {
//            //faceAnimator->detectAndAnimateFaces(image, dest, 1);
//            [self faceDetect:image];
//            faceCount=faceAnimator->getFaceCount();
//            centerness=faceAnimator->getAvgCenterness();
//            faces=faceAnimator->getFaceRects();
//            
//            opticalFlow->trackFlow(image, dest, faces, currentAccelX, currentAccelY, currentAccelZ, tappedX, tappedY);
//            image=dest;
//            magnitude = opticalFlow->getAvgMagnitude();
//            slope=opticalFlow->getAvgSlope();
//            cvtColor(image, image, CV_BGR2RGB);
//            faces.clear();
//            break;
//        }
//        case 6:
//        {
//            UIImage *uiImage = UIImageFromCVMat(image);
//            
//            
//            UIImage* imageResult = [self generateTwirl: uiImage];
//            
//            
//            image=cvMatFromUIImage(imageResult);
//            
//            cvtColor(image, image, CV_BGR2RGB);
//            break;
//        }
//        case 7:
//        {
//            UIImage *uiImage = UIImageFromCVMat(image);
//            
//            
//            UIImage* imageResult = [self generateHole: uiImage];
//            
//            
//            image=cvMatFromUIImage(imageResult);
//            
//            cvtColor(image, image, CV_BGR2RGB);
//            break;
//        }
//        default:
//            break;
  //  }
    
   // faceAnimator->detectAndAnimateFaces(image, 1);
    
    
//    opticalFlow->trackFlow(image, dest);
//    
//    image=dest;
//    
//   // cvtColor(image, image, CV_BGR2RGB);
//    
//    UIImage *uiImage = UIImageFromCVMat(dest);
//    
//    
//    UIImage* imageResult = [self generateColors: uiImage];
//    
//    
//    image=cvMatFromUIImage(imageResult);
//    
//    cvtColor(image, image, CV_BGR2RGB);

    tappedX=0;
    tappedY=0;
    ///int64 timeEnd = cv::getTickCount();
    //float durationMs =
   // 1000.f * float(timeEnd - timeStart) / cv::getTickFrequency();
    //NSLog(@"Processing time = %.3fms", durationMs);
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

- (IBAction)showGestureForSwipeRecognizer:(UISwipeGestureRecognizer *)recognizer {
    
    CGPoint location = [recognizer locationInView:self.view];
    [self drawImageForGestureRecognizer:recognizer atPoint:location];
    
//    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
//        location.x -= 220.0;
//    }
//    else {
//        location.x += 220.0;
//    }
    
//    [UIView animateWithDuration:0.5 animations:^{
//        self.imageView.alpha = 0.0;
//        self.imageView.center = location;
//    }];
}

- (void)drawImageForGestureRecognizer:(UIGestureRecognizer *)recognizer atPoint:(CGPoint)centerPoint {
        
        NSString *imageName;
        
        if ([recognizer isMemberOfClass:[UITapGestureRecognizer class]]) {
            imageName = @"tap.png";
        }
//        else if ([recognizer isMemberOfClass:[UIRotationGestureRecognizer class]]) {
//            imageName = @"rotation.png";
//        }
//        else if ([recognizer isMemberOfClass:[UISwipeGestureRecognizer class]]) {
//            imageName = @"swipe.png";
//        }
    NSLog(@"tapped");
//        self.imageView.image = [UIImage imageNamed:imageName];
//        self.imageView.center = centerPoint;
//        self.imageView.alpha = 1.0; 
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

    
    // Display an image view at that location
    [self drawImageForGestureRecognizer:recognizer atPoint:location];
    
//    // Animate the image view so that it fades out
//    [UIView animateWithDuration:0.5 animations:^{
//        self.imageView.alpha = 0.0;
//    }];

}


@end


