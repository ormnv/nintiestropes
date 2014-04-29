//
//  DetailViewController.h
//  nintiestropes
//
//  Created by Olga Romanova on 4/28/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "SampleFacade.h"

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>
{
    SampleFacade* currentSample;
    UIImagePickerController * imagePicker;
}

@property (weak, nonatomic) IBOutlet UIImageView *sampleIconView;
@property (weak, nonatomic) IBOutlet UITextView *sampleDescriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton *runOnImageButton;
@property (weak, nonatomic) IBOutlet UIButton *runOnVideoButton;

- (void) setDetailItem:(SampleFacade*) sample;
- (void) configureView;

@end
