//
//  ViewController.m
//  nintiestropes
//
//  Created by Olga Romanova on 4/23/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//

#import "ViewController.h"
#import "PostcardPrinter.hpp"


static UIImage* MatToUIImage(const cv::Mat& image) {
    
    NSData *data = [NSData dataWithBytes:image.data length:image.elemSize()*image.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(image.cols,                                 //width
                                        image.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * image.elemSize(),                       //bits per pixel
                                        image.step.p[0],                            //bytesPerRow
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

static void UIImageToMat(const UIImage* image, cv::Mat& m, bool alphaExist = false) {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width, rows = image.size.height;
    CGContextRef contextRef;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    if (CGColorSpaceGetModel(colorSpace) == 0)
    {
        m.create(rows, cols, CV_8UC1); // 8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone;
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNone;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace, bitmapInfo);
        NSLog(@"first if");
    }
    else
    {
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace, bitmapInfo);
        NSLog(@"second if");

    }
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
}

@interface ViewController ()

@end

@implementation ViewController

@synthesize imageView;
@synthesize retroButton;
@synthesize postcardButton;
@synthesize saveButton;
@synthesize popoverController;
@synthesize toolbar;
//loading image
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//	// Do any additional setup after loading the view, typically from a nib.
//    
//    //compute path to the resource file
//    NSString* filePath = [[NSBundle mainBundle]
//                          pathForResource:@"fishbowl" ofType:@"jpg"];
//    //read the image
//    UIImage* image = [UIImage imageWithContentsOfFile:filePath];
//    //convert UIImage* to cv::Mat
//    UIImageToMat(image, cvImage);
//    
//    //    //create file handle
//    //    NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:fileName];
//    //    //read contents of the file
//    //    NSData *data = [handle readDataToEndOfFile];
//    //    //read image from the data buffer
//    //    cvImage = cv::imdecode(cv::Mat(1, [data length], CV_8UC1, (void*)data.bytes), CV_LOAD_IMAGE_UNCHANGED);
//    
//    if (!cvImage.empty())
//    {
//        cv::Mat cvGrayImage;
//        //convert the image to the one-channel
//        cv::cvtColor(cvImage, cvGrayImage, CV_RGBA2GRAY);
//        //apply Gaussian filter to remove small edges
//        cv::GaussianBlur(cvGrayImage, cvGrayImage, cv::Size(5, 5), 1.2,
//                         1.2);
//        //calculate edges by applying Canny method
//        cv::Canny(cvGrayImage, cvGrayImage, 0, 50);
//        //set values of all pixels to gray color
//        cvImage.setTo(cv::Scalar::all(255));
//        //change color on edges
//        cvImage.setTo(cv::Scalar(0, 128, 255, 255), cvGrayImage);
//        //convert cv::Mat to UIImage* and show resulted image on imageView component
//        imageView.image = MatToUIImage(cvImage);
//    }
//}
//face detection
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//    
//    //calculate path to the resource file
//    NSString* filename = [[NSBundle mainBundle]
//                          pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
//    //load Haar cascade from the XML file
//    faceCascade.load([filename UTF8String]);
//    
//    //compute path to the resource file
//    NSString* filePath = [[NSBundle mainBundle]
//                          pathForResource:@"olgany" ofType:@"jpg"];
//    //read the image
//    UIImage* image = [UIImage imageWithContentsOfFile:filePath];
//    //convert UIImage* to cv::Mat
//    cv::Mat cvImage;
//    UIImageToMat(image, cvImage);
//    
//    //vector for storing found faces
//    std::vector<cv::Rect> faces;
//    
//    cv::Mat cvGrayImage;
//    //convert the image to the one-channel
//    cvtColor(cvImage, cvGrayImage, CV_BGR2GRAY);
//    //find faces on the image
//    faceCascade.detectMultiScale(cvGrayImage, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30,30));
//    //draw all found faces
//    for(int i = 0; i < faces.size(); i++)
//    {
//        const cv::Rect& currentFace = faces[i];
//        //calculate two corner points to draw a rectangle
//        cv::Point upLeftPoint(currentFace.x, currentFace.y);
//        cv::Point bottomRightPoint = upLeftPoint + cv::Point(currentFace.width, currentFace.height);
//        //draw rectangle around the face
//        cv::rectangle(cvImage, upLeftPoint, bottomRightPoint, cv::Scalar(255,0,255), 4, 8, 0);
//    }
//    //show resulted image on imageView component
//    imageView.image = MatToUIImage(cvImage);
//}

//

//ch 5
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//    
//    PostcardPrinter::Images images;
//    NSString* filePath = [[NSBundle mainBundle]
//                          pathForResource:@"olgany" ofType:@"jpg"];
//    UIImage* image = [UIImage imageWithContentsOfFile:filePath];
//    UIImageToMat(image, images.face);
//    
//    //FIXME: delete this
//    resize(images.face, images.face, cv::Size(512, 512));
//    
//    filePath = [[NSBundle mainBundle]
//                pathForResource:@"texture" ofType:@"jpg"];
//    image = [UIImage imageWithContentsOfFile:filePath];
//    UIImageToMat(image, images.texture);
//    cvtColor(images.texture, images.texture, CV_RGBA2RGB);
//    
//    filePath = [[NSBundle mainBundle]
//                pathForResource:@"text" ofType:@"png"];
//    image = [UIImage imageWithContentsOfFile:filePath];
//    UIImageToMat(image, images.text, true);
//    
//    PostcardPrinter postcardPrinter(images);
//    
//    cv::Mat postcard;
//    int64 timeStart = cv::getTickCount();
//    postcardPrinter.print(postcard);
//    int64 timeEnd = cv::getTickCount();
//    
//    float durationMs =
//    1000.f * float(timeEnd - timeStart) / cv::getTickFrequency();
//    NSLog(@"Printing time = %.3fms", durationMs);
//    
//    if (!postcard.empty())
//        imageView.image = MatToUIImage(postcard);
//}

//@end


//ch 6 
- (NSInteger)supportedInterfaceOrientations
{
    //only portrait orientation
    return UIInterfaceOrientationMaskPortrait;
}
//ch7
- (UIImage*)applyFilter:(UIImage*)image;
{
    NSString* filePath = [[NSBundle mainBundle]
                          pathForResource:@"scratches" ofType:@"png"];
    UIImage* resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, images.scratches);
    
    filePath = [[NSBundle mainBundle]
                pathForResource:@"fuzzyBorder" ofType:@"png"];
    UIImage* resImage1 = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage1, images.fuzzyBorder);
    
    cv::Size frameSize(image.size.width, image.size.height);
    images.frameSize = frameSize;
    
    cv::Mat frame, finalFrame;
    UIImageToMat(image, frame);
    
    RetroFilter retroFilter(images);
    retroFilter.applyToPhoto(frame, finalFrame);

    UIImage* resImage2 = MatToUIImage(finalFrame);
    
    return resImage2;
}

- (UIImage*)printPostcard:(UIImage*)image;
{
    cv::Mat cvImage;
    //convert input image to cv::Mat object
    UIImageToMat(image, cvImage);
    
    cv::Mat cvGrayImage;
    //convert the image to the one-channel
    cvtColor(cvImage, cvGrayImage, CV_BGR2GRAY);
    
    //vector for storing found faces
    std::vector<cv::Rect> faces;
    //find faces on the image
    int64 fdTimeStart = cv::getTickCount();
    faceCascade.detectMultiScale(cvGrayImage, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(100,100));
    int64 fdTimeEnd = cv::getTickCount();
    float fdDurationMs =
    1000.f * float(fdTimeEnd - fdTimeStart) / cv::getTickFrequency();
    NSLog(@"Face detecting time = %.3fms", fdDurationMs);
    
    //select the largest rectangle
    cv::Rect faceRect(0,0,0,0);
    for(int i = 0; i < faces.size(); i++)
    {
        const cv::Rect& currentFace = faces[i];
        if (currentFace.area() > faceRect.area()) {
            faceRect = currentFace;
        }
    }

    PostcardPrinter::Images images;
    
    NSString* filePath;
    UIImage* resImage;
    if (!faces.size()) {
        filePath = [[NSBundle mainBundle]
                    pathForResource:@"olgany" ofType:@"jpg"];
        resImage = [UIImage imageWithContentsOfFile:filePath];
        UIImageToMat(resImage, images.face);
    }
    else
    {
        UIImageToMat(image, images.face);
        
        //increase the largest rectangle twice
        faceRect.x -= faceRect.width/2;
        faceRect.y -= faceRect.height/2;
        faceRect.width *= 2;
        faceRect.height *= 2;
        cv::Rect imageRect(0,0,images.face.cols, images.face.rows);
        faceRect = faceRect & imageRect;
        
        images.face = images.face(faceRect);
    }
    
    //FIXME: delete this
    resize(images.face, images.face, cv::Size(512, 512));
    
    filePath = [[NSBundle mainBundle]
                pathForResource:@"texture" ofType:@"jpg"];
    resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, images.texture);
    cvtColor(images.texture, images.texture, CV_RGBA2RGB);
    
    filePath = [[NSBundle mainBundle]
                pathForResource:@"text" ofType:@"png"];
    resImage = [UIImage imageWithContentsOfFile:filePath];
    UIImageToMat(resImage, images.text, true);
    
    PostcardPrinter postcardPrinter(images);
    
    cv::Mat postcard;
    int64 timeStart = cv::getTickCount();
    postcardPrinter.print(postcard);
    int64 timeEnd = cv::getTickCount();
    
    float durationMs =
    1000.f * float(timeEnd - timeStart) / cv::getTickFrequency();
    NSLog(@"Printing time = %.3fms", durationMs);
    
    return MatToUIImage(postcard);
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [popoverController dismissPopoverAnimated:YES];
    }
    else
    {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    UIImage* temp = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
//    image = [self printPostcard:temp];
    image = [self applyFilter:temp];
    imageView.image = image;
    [saveButton setEnabled:YES];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [popoverController dismissPopoverAnimated:YES];
    }
    else
    {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)loadButtonPressed:(id)sender {
    UIImagePickerController* picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    
    if (![UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypePhotoLibrary])
        return;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    NSLog(@"made it ");
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if ([self.popoverController isPopoverVisible])
        {
            [self.popoverController dismissPopoverAnimated:YES];
        }
        else
        {
            if ([UIImagePickerController isSourceTypeAvailable:
                 UIImagePickerControllerSourceTypePhotoLibrary])
            {
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                self.popoverController = [[UIPopoverController alloc]
                                          initWithContentViewController:picker];
                
                popoverController.delegate = self;
                
                [self.popoverController
                 presentPopoverFromBarButtonItem:sender
                 permittedArrowDirections:UIPopoverArrowDirectionUp
                 animated:YES];
            }
        }
    }
    else
    {
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (IBAction)saveButtonPressed:(id)sender {
    if (image != nil)
    {
        UIImageWriteToSavedPhotosAlbum(image, self, nil, NULL);
        //Alert window
        UIAlertView *alert = [UIAlertView alloc];
        alert = [alert initWithTitle:@"Gallery info"
                             message:@"The image was saved to the Gallery!"
                            delegate:self
                   cancelButtonTitle:@"Continue"
                   otherButtonTitles:nil];
        [alert show];
    }
}

//ch7
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib
//
//    NSString* filePath = [[NSBundle mainBundle]
//                          pathForResource:@"scratches" ofType:@"png"];
//    UIImage* resImage = [UIImage imageWithContentsOfFile:filePath];
//    UIImageToMat(resImage, images.scratches);
//    
//    filePath = [[NSBundle mainBundle]
//                pathForResource:@"fuzzy_border" ofType:@"png"];
//    resImage = [UIImage imageWithContentsOfFile:filePath];
//    UIImageToMat(resImage, images.fuzzyBorder);

    //ch6
    //calculate path to the resource file
        NSString* filename = [[NSBundle mainBundle]
                              pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
        //load Haar cascade from the XML file
        faceCascade.load([filename UTF8String]);

    
    [saveButton setEnabled:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
