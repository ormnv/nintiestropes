//
//  DetailViewController.h
//  nintiestropes
//
//  Built using https://github.com/BloodAxe/OpenCV-Tutorial as a template.
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
