//
//  GlowFilter.h
//  nintiestropes1
//
//  Created by Olga Romanova on 4/30/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//

#ifndef nintiestropes1_GlowFilter_h
#define nintiestropes1_GlowFilter_h

#include "SampleBase.h"

class GlowFilter : public SampleBase
{
public:
    GlowFilter();
    
    //! Gets a sample name
    virtual std::string getName() const;
    
    //! Returns a detailed sample description
    virtual std::string getDescription() const;
    
    //! Processes a frame and returns output image
    virtual bool processFrame(const cv::Mat& inputFrame, cv::Mat& outputFrame);
    
private:
    float sp;
    float sr;
    int erosion_elem;
    int erosion_size;
    
    cv::Mat gray, edges;
    cv::Mat hsv;
    
    cv::Mat bgr, img0;
    cv::Mat edgesBgr;
    
};


#endif
