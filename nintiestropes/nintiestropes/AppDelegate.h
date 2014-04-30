//
//  AppDelegate.h
//  nintiestropes
//
//  Built using https://github.com/BloodAxe/OpenCV-Tutorial as a template.
//

#import <UIKit/UIKit.h>
#import "SampleBase.h"
#import "SampleFacade.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
@public
    std::vector<SampleFacade*> allSamples;
}
@property (strong, nonatomic) UIWindow *window;

@end

