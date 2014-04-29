//
//  AppDelegate.h
//  nintiestropes
//
//  Created by Olga Romanova on 4/28/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
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

