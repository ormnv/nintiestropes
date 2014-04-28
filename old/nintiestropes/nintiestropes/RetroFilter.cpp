#include "RetroFilter.hpp"
#include "opencv2/imgproc/imgproc.hpp"

using namespace cv;

void alphaBlend(Mat src, Mat dst, Mat alpha);
void alphaBlend(Mat src, Mat dst, Mat alpha)
{
    for (int i = 0; i < src.rows; i++)
        for (int j = 0; j < src.cols; j++)
        {
            uchar alpha_value = alpha.at<uchar>(i, j);
            if (alpha_value != 0)
            {
                float text_weight = static_cast<float>(alpha_value) / 255.0f;
                dst.at<uchar>(i, j) = text_weight * src.at<uchar>(i, j) +
                (1 - text_weight) * dst.at<uchar>(i, j);
            }
        }
}

RetroFilter::RetroFilter(Images images) : rng_(time(0))
{
    images_ = images;
    
    multiplier_ = 1.0;
    
    borderColor_.create(images_.frameSize, CV_8UC1);
    scratchColor_.create(images_.frameSize, CV_8UC1);
    
    sepiaH_.create(images_.frameSize, CV_8UC1); sepiaH_.setTo(Scalar(19));
    sepiaS_.create(images_.frameSize, CV_8UC1); sepiaS_.setTo(Scalar(78));
    sepiaPlanes_.resize(3);
    sepiaPlanes_[0] = sepiaH_;
    sepiaPlanes_[1] = sepiaS_;
    
    resize(images_.fuzzyBorder, images_.fuzzyBorder, images_.frameSize);
    
    if (images_.scratches.rows < images_.frameSize.height ||
        images_.scratches.cols < images_.frameSize.width)
    {
        resize(images_.scratches, images_.scratches, images_.frameSize);
    }
}

void RetroFilter::applyToPhoto(const Mat& inputFrame, Mat& retroFrame)
{
    Mat luminance;
    cvtColor(inputFrame, luminance, CV_BGR2GRAY);
    
    // Add scratches
    Scalar meanColor = mean(luminance.row(luminance.rows / 2));
    scratchColor_.setTo(meanColor * 2.0);
    int x = rng_.uniform(0, images_.scratches.cols - luminance.cols);
    int y = rng_.uniform(0, images_.scratches.rows - luminance.rows);
    cv::Rect roi(cv::Point(x, y), luminance.size());
    scratchColor_.copyTo(luminance, images_.scratches(roi));
    
    // Add fuzzy border
    borderColor_.setTo(meanColor * 1.5);
    alphaBlend(borderColor_, luminance, images_.fuzzyBorder);
    
    // Apply sepia-effect
    sepiaPlanes_[2] = luminance + 20;
    Mat hsvFrame;
    merge(sepiaPlanes_, hsvFrame);
    cvtColor(hsvFrame, retroFrame, CV_HSV2RGB);
}

void RetroFilter::applyToVideo(const Mat& inputFrame, Mat& retroFrame)
{
    // Convert to gray with random shift
    cv::Size shift;
    shift.width  = 2 + (rng_.uniform(0, 10) ? 0 : rng_.uniform(-1, 2));
    shift.height = 2 + (rng_.uniform(0, 10) ? 0 : rng_.uniform(-1, 2));
    cv::Rect roiSrc(cv::Point(0, 0), inputFrame.size() - shift);
    cv::Rect roiDst(shift, inputFrame.size() - shift);
    retroFrame.create(inputFrame.size(), CV_8UC1);
    cvtColor(inputFrame(roiSrc), retroFrame(roiDst), CV_BGR2GRAY);
    
    // Add intensity variation
    float sign = pow(-1.f, rng_.uniform(0, 2));
    float value = 1.f + sign * rng_.gaussian(0.2);
    multiplier_ = 0.7 * multiplier_ + 0.3 * value;
    retroFrame *= multiplier_;
    
    Scalar meanColor = mean(retroFrame.row(retroFrame.rows / 2));
    
    // Add scratches
    int x = rng_.uniform(0, images_.scratches.cols - retroFrame.cols);
    int y = rng_.uniform(0, images_.scratches.rows - retroFrame.rows);
    cv::Rect roi(cv::Point(x, y), retroFrame.size());
    if (rng_.uniform(0, 2))
        scratchColor_.setTo(meanColor * 2.0);
    else
        scratchColor_.setTo(meanColor / 2.0);
    alphaBlend(scratchColor_, retroFrame, images_.scratches(roi));
    
    // Add fuzzy border
    borderColor_.setTo(meanColor * 1.5);
    alphaBlend(borderColor_, retroFrame, images_.fuzzyBorder);
    
    // Convert back to 3-channel image
    cvtColor(retroFrame, retroFrame, CV_GRAY2BGR);
}
