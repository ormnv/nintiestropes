//
//  BaseSampleViewController.h
//  nintiestropes
//
//  Built using https://github.com/BloodAxe/OpenCV-Tutorial as a template.
//


#import <UIKit/UIKit.h>

#import "SampleBase.h"
#import "SampleFacade.h"

typedef void (^TweetImageCompletionHandler)(); 
typedef void (^SaveImageCompletionHandler)(); 

#define kSaveImageActionTitle  @"Save image"
#define kComposeTweetWithImage @"Tweet image"

@interface BaseSampleViewController : UIViewController

@property (readonly) SampleFacade * currentSample;

- (void) configureView;
- (void) setSample:(SampleFacade*) sample;
- (void) tweetImage:(UIImage*) image withCompletionHandler: (TweetImageCompletionHandler) handler;
- (void) saveImage:(UIImage*) image  withCompletionHandler: (SaveImageCompletionHandler) handler;

@end
