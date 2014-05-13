//
//  OpticalFlow.h
//  windowlicker
//
//  Created by Olga Romanova on 5/2/14.
//  Copyright (c) 2014 Olga Romanova. All rights reserved.
//

#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
//#include "Processing.hpp"


class OpticalFlow
{
public:

     OpticalFlow();
//    virtual ~OpticalFlow() {};
    
//    int getNumPoints();
//    void setNumPoints(int points);

    //get avg position
    //get velocity ?
    
    //globals
    bool computeObject;
    bool detectObject;
    bool trackObject;
    
    //! Processes a frame and returns output image
//    bool getFlow(const cv::Mat& inputFrame, cv::Mat& outputFrame);
    
    // set maxcorners
    void setMaxCorners(int maxCorners);
    float getAvgMagnitude();

    float getAvgSlope();

    bool trackFlow(const cv::Mat& inputFrame, cv::Mat& outputFrame, std::vector<cv::Rect> faces, double accelX, double accelY, double accelZ, float tapX, float tapY);

    // initialise tracker
    void init(cv::Mat& image, // output image
              cv::Mat& image1, // source image
              std::vector<cv::Point2f>& points1); // points array

    
private:
    //remove paramaters?
//    Parameters parameters_;
    int maxCorners;
    double qualityLevel;
    double minDistance;
    int blockSize;
    bool useHarrisDetector;
    double k;
    cv::Size subPixWinSize, winSize;
    cv::TermCriteria termcrit;
    int maxLevel;
    int flags;
    double minEigThreshold;
    int m_maxNumberOfPoints;
    float avgSpeed;
    float avgVelocity;
    int pointNum;
    float avgMagnitude;
    float avgSlope;
    
    //from sample
    
    cv::Mat imageNext, imagePrev;
    std::vector<uchar> status;
    std::vector<float> err;
    std::string m_algorithmName;
    cv::vector<cv::Point2f> pointsPrev, pointsNext;
    
    //fomr videotracking

    cv::Mat m_prevImg;
    cv::Mat m_nextImg;
    cv::Mat m_mask;
    
    std::vector<cv::Point2f>  m_prevPts;
    std::vector<cv::Point2f>  m_nextPts;
    
    std::vector<cv::KeyPoint> m_prevKeypoints;
    std::vector<cv::KeyPoint> m_nextKeypoints;
    
    cv::Mat                   m_prevDescriptors;
    cv::Mat                   m_nextDescriptors;
    
    std::vector<unsigned char> m_status;
    std::vector<float>         m_error;
    
    cv::ORB       m_orbFeatureEngine;
    cv::BFMatcher m_orbMatcher;
    
    cv::GridAdaptedFeatureDetector m_fastDetector;
    cv::BriefDescriptorExtractor m_briefExtractor;
    cv::BFMatcher                m_briefMatcher;
    
    cv::Ptr<cv::FeatureDetector> m_detector;
    std::string m_activeTrackingAlgorithm;

};
