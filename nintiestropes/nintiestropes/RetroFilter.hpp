#pragma once

#include "opencv2/core/core.hpp"

class RetroFilter
{
public:
    struct Images
    {
        cv::Size frameSize;
        cv::Mat fuzzyBorder;
        cv::Mat scratches;
    };
    
    RetroFilter(Images images);
    void applyToPhoto(const cv::Mat& inputFrame, cv::Mat& retroFrame);
    void applyToVideo(const cv::Mat& inputFrame, cv::Mat& retroFrame);
    
private:
    Images images_;
    
    cv::RNG rng_;
    float multiplier_;
    
    cv::Mat borderColor_;
    cv::Mat scratchColor_;
    
    std::vector<cv::Mat> sepiaPlanes_;
    cv::Mat sepiaH_;
    cv::Mat sepiaS_;
};
