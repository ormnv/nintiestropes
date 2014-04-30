//
//  GLESView.h
//  nintiestropes
//
//  Built using https://github.com/BloodAxe/OpenCV-Tutorial as a template.
//


#import <UIKit/UIKit.h>

@interface GLESImageView : UIView

- (void)drawFrame:(const cv::Mat&) bgraFrame;


@end
