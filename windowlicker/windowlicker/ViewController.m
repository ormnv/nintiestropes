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


static UIImage* MatToUIImage(const cv::Mat& image)
{
    NSData *data = [NSData dataWithBytes:image.data
                                  length:image.elemSize()*image.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(image.cols,
                                        image.rows,
                                        8,
                                        8 * image.elemSize(),
                                        image.step.p[0],
                                        colorSpace,
                                        kCGImageAlphaNone|
                                        kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return finalImage;
}

static void UIImageToMat(const UIImage* image, cv::Mat& m,
                         bool alphaExist = false)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width, rows = image.size.height;
    CGContextRef contextRef;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    if (CGColorSpaceGetModel(colorSpace) == 0)
    {
        m.create(rows, cols, CV_8UC1);
        //8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone;
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNone;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    else
    {
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
            kCGBitmapByteOrderDefault;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows),
                       image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
}

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

    currentMaxAccelX = 0;
    currentMaxAccelY = 0;
    currentMaxAccelZ = 0;
    
    currentMaxRotX = 0;
    currentMaxRotY = 0;
    currentMaxRotZ = 0;
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = .2;
    self.motionManager.gyroUpdateInterval = .2;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 [self outputAccelertionData:accelerometerData.acceleration];
                                                 if(error){
                                                     
                                                     NSLog(@"%@", error);
                                                 }
                                             }];
    
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                    withHandler:^(CMGyroData *gyroData, NSError *error) {
                                        [self outputRotationData:gyroData.rotationRate];
                                    }];
    

    
    UIDevice *device = [UIDevice currentDevice];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    [device beginGeneratingDeviceOrientationNotifications];

	// Do any additional setup after loading the view, typically from a nib.

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

-(void)outputAccelertionData:(CMAcceleration)acceleration
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
    
    self.maxAccX.text = [NSString stringWithFormat:@" %.2f",currentMaxAccelX];
    self.maxAccY.text = [NSString stringWithFormat:@" %.2f",currentMaxAccelY];
    self.maxAccZ.text = [NSString stringWithFormat:@" %.2f",currentMaxAccelZ];
    
    
}
-(void)outputRotationData:(CMRotationRate)rotation
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

-(IBAction)startCaptureButtonPressed:(id)sender
{
    [videoCamera start];
    isCapturing = TRUE;
    
    faceAnimator = new FaceAnimator(parameters);
}

-(IBAction)stopCaptureButtonPressed:(id)sender
{
    [videoCamera stop];

//    NSString* relativePath = [videoCamera.videoFileURL relativePath];
//    UISaveVideoAtPathToSavedPhotosAlbum(relativePath, self, nil, NULL);
//    
//    //Alert window
//    UIAlertView *alert = [UIAlertView alloc];
//    alert = [alert initWithTitle:@"Camera info"
//                         message:@"The video was saved to the Gallery!"
//                        delegate:self
//               cancelButtonTitle:@"Continue"
//               otherButtonTitles:nil];
//    [alert show];
    
    isCapturing = FALSE;
}

-(IBAction)toggleCameraButtonPressed:(id)sender
{
	[videoCamera switchCameras];
}

-(IBAction)savevideoButtonPressed:(id)sender
{
	//[videoCamera saveVideo];
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
    
    currentMaxRotX = 0;
    currentMaxRotY = 0;
    currentMaxRotZ = 0;
    
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
    //cv::warpAffine(src, dst, r, cv::Size(len, len));

    cv::warpAffine(src, dst, r, cv::Size(src.rows, src.cols));
}

- (void)processImage:(cv::Mat&)image
{

    UIDevice *device = [UIDevice currentDevice];
    //UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    int orientation= -1;
    
    cv::Mat dest;
    int64 timeStart = cv::getTickCount();

//    if(deviceOrientation== UIDeviceOrientationPortrait)
//    {
//        rotate(image, 90, dest);
//        faceAnimator->detectAndAnimateFaces(dest, image, 0);
//        orientation =0;
//    }
//    else if(deviceOrientation== UIDeviceOrientationLandscapeRight)
//    {
//        //LandscapeLeft is default but behavior is wrong
//        faceAnimator->detectAndAnimateFaces(image, image, 1);
//        orientation =1;
//
//    }
//    else if(deviceOrientation== UIDeviceOrientationLandscapeLeft)
//    {
//        rotate(image, 180, dest);
//        faceAnimator->detectAndAnimateFaces(dest, image, 2);
//        orientation =2;
//
//    }
//    else if(deviceOrientation== UIDeviceOrientationPortraitUpsideDown)
//    {
//        rotate(image, 270, dest);
//        faceAnimator->detectAndAnimateFaces(dest, image, 3);
//        orientation =3;
//    }
//    
//    [self generateCVEffects:image, orientation];
    
        //faceAnimator->detectAndAnimateFaces(image, 1);
        UIImage *uiImage = MatToUIImage(image);
        CIImage *ciImage = [CIImage imageWithCGImage:uiImage.CGImage];
        CIContext *context = [CIContext contextWithOptions:nil];
    //    //CIImage *inputImage = [CIImage imageWithCGImage:[[UIImage imageNamed:@"vespa"] CGImage]];
    //
    //     //hue filter
    //    CIFilter *hueFilter = [CIFilter filterWithName:@"CIHueAdjust"];
    //    [hueFilter setValue:ciImage forKey:kCIInputImageKey];
    //    [hueFilter setValue:[NSNumber numberWithDouble:-2*M_PI/4] forKey:@"inputAngle"];
    //    CIImage *result = [hueFilter outputImage];
    
    //    CGImageRelease(cgImage);
    //    [imageView setImage:imageResult];
    
    //    CIFilter *filterColorMatrix = [CIFilter filterWithName:@"CIColorMatrix"];
    //    [filterColorMatrix setValue:ciImage forKey:kCIInputImageKey];
    //    CIVector *greenVector = [CIVector vectorWithX:1 Y:0 Z:0 W:0];
    //    [filterColorMatrix setValue:greenVector forKey:@"inputGVector"];
    //    CIImage *result = [filterColorMatrix valueForKey:kCIOutputImageKey];
    
    //    CIFilter *affline = [CIFilter filterWithName:@"CIAffineTile"];
    //    [affline setValue:ciImage forKey:kCIInputImageKey];
    //    [affline setValue:[NSNumber numberWithFloat:5.0f] forKey:@"inputRadius"];
    //    [affline setValue:[NSNumber numberWithFloat:2.0f] forKey:@"inputIntensity"];
    //    CIImage *result = [filterBloom valueForKey:kCIOutputImageKey];
    
    //filter looks weird
    //    CIFilter *filterBloom = [CIFilter filterWithName:@"CIBloom"];
    //    [filterBloom setValue:ciImage forKey:kCIInputImageKey];
    //    [filterBloom setValue:[NSNumber numberWithFloat:5.0f] forKey:@"inputRadius"];
    //    [filterBloom setValue:[NSNumber numberWithFloat:2.0f] forKey:@"inputIntensity"];
    //    CIImage *result = [filterBloom valueForKey:kCIOutputImageKey];
    
    
    //CITwirlDistortion
        CIFilter *twirl = [CIFilter filterWithName:@"CITwirlDistortion"];
        [twirl setValue:ciImage forKey:kCIInputImageKey];
        CIVector *vVector = [CIVector vectorWithX:150 Y:150];
        [twirl setValue:vVector forKey:@"inputCenter"];
        [twirl setValue:[NSNumber numberWithFloat:300.0f] forKey:@"inputRadius"];
        [twirl setValue:[NSNumber numberWithFloat:3.14f] forKey:@"inputAngle"];
        CIImage *result = [twirl valueForKey:kCIOutputImageKey];
    
    
    //bump not in iOS
    //    CIFilter *kHole = [CIFilter filterWithName:@"CIBumpDistortion"];
    //    [kHole setValue:ciImage forKey:kCIInputImageKey];
    //    CIVector *vVector = [CIVector vectorWithX:150 Y:150];
    //    [kHole setValue:vVector forKey:@"inputCenter"];
    //    [kHole setValue:[NSNumber numberWithDouble:300.0] forKey:@"inputRadius"];
    //    [kHole setValue:[NSNumber numberWithDouble:.5] forKey:@"inputScale"];
    //    CIImage *result = [kHole valueForKey:kCIOutputImageKey];
    //    CIImage *result = [kHole outputImage];
    
        CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    
        UIImage *imageResult = [UIImage imageWithCGImage:cgImage];
        //CGImageRelease(cgImage);
        UIImageToMat(imageResult, image);
    cvtColor(image, image, CV_BGR2RGB);

   // image = dest;
    int64 timeEnd = cv::getTickCount();
    float durationMs =
    1000.f * float(timeEnd - timeStart) / cv::getTickFrequency();
    NSLog(@"Processing time = %.3fms", durationMs);
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
}

@end
