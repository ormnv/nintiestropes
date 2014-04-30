//
//  GlowFilter.cpp
//  nintiestropes1
//
//  Created by Olga Romanova on 4/30/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//

#include "GlowFilter.h"

#include <iostream>

GlowFilter::GlowFilter()
: erosion_elem(0)
, erosion_size(8)
{
    registerOption("Erodsion element is ", "", &erosion_elem, 0, 2);
    registerOption("Erosion size is", "",   &erosion_size, 0, 21);
}

std::string GlowFilter::getName() const
{
    return "Glow filter";
}

std::string GlowFilter::getDescription() const
{
    return "This sample creates a soft, glowing blur.";
}

bool GlowFilter::processFrame(const cv::Mat& inputFrame, cv::Mat& outputFrame)
{
    cv::cvtColor(inputFrame, bgr, CV_BGRA2BGR);
    
    cv::Mat element = getStructuringElement( cv::MORPH_CROSS,
                                            cv::Size( 2*erosion_size + 1, 2*erosion_size+1 ),
                                            cv::Point( erosion_size, erosion_size ) );
    cv::erode( bgr, bgr, element );
    
    cv::cvtColor(bgr, outputFrame, CV_BGR2BGRA);
    
    return true;
}