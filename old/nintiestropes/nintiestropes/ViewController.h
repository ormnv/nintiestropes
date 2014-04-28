//
//  ViewController.h
//  nintiestropes
//
//  Created by Olga Romanova on 4/23/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RetroFilter.hpp"

//@interface ViewController : UIViewController {
//    cv::Mat cvImage;
//}

@interface ViewController : UIViewController<UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UIPopoverControllerDelegate> {
    UIPopoverController *popoverController;
    UIImageView *imageView;
    UIImage* image;
    cv::Mat cvImage;
    RetroFilter::Images images;
    cv::CascadeClassifier faceCascade;
}
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loadButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *postcardButton;

-(IBAction)loadButtonPressed:(id)sender;
-(IBAction)saveButtonPressed:(id)sender;

- (UIImage*)printPostcard:(UIImage*)image;

@end

