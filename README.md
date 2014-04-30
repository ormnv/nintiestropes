OpenCV App

The app uses an existing tutorial of opencv examples from 2012 found here https://github.com/BloodAxe/OpenCV-Tutorial. My version of the app uses the UI as a base while making my own samples that mimic 90s music video effects. To make the tutorial work on arm64, I removed cvneon.h, cvneon.cpp and made the file extensions mm. For the time being, neon is not used to enhance perofrmance since the methods need to be replaced. It may be possible to implement the methods dependent on getGray to use neon for arm64 within the individual sample files themselves. OpenCv for iOS by Kornyakov and Shishkov contains an example where a filter is optimized by neon. Since this project will be using filters, the version provided there can be used. Comparing the original version of the app in the tutorial running with cvneon to my version running on arm64 without neon, there is no noticable difference in rendering the effects. The app is faster for some effects on arm64 even without cvneon. The Object Tracking sample does not with in the old version nor the new version. The original tutorial did not use automatic reference counting, so this current example is updated to use it. 

TODO:

-Update UI 

-Fix toolbar alignment

-Integrate CoreImage filters  

-Get Assets 

-Change dimensions of UIImage displayed. Looks stretched out. Does it save stretched out? 

-Update methods converting to and from mat to be simular to this? The example has cvMatFromUIImage, cvMatGrayFromUIImage, and UIImageFromCVMat for images. 
	http://docs.opencv.org/doc/tutorials/ios/image_manipulation/image_manipulation.html#opencviosimagemanipulation

- Incorporate #import <opencv2/highgui/cap_ios.h>, which is not used in the original tutorial from 2012? 
	http://docs.opencv.org/doc/tutorials/ios/video_processing/video_processing.html#opencviosvideoprocessing

-CVNEON 
The cvneon class that was part of the original OpenCV iOS tutorial does not work with the arm64 architecture. The registers are different for arm64, so the old code won't work. For the time being, the cvneon methods were replaced by Specfically affecting: 

cvneon.cpp
	The error occurs in static void neon_asm_convert which is called by neon_cvtColorBGRA2GRAY.
	The error occurs in static void neon_asm_mat4_vec4_mul which is called by neon_transform_bgra. 

ImageFilterSample.cpp 
	ImageFiltersSample::sepia calls cv::neon_transform_bgra	
	ImageFiltersSample::contrastAndBrightnessAdjust calls cv::neon_transform_bgra	

SampleBase.cpp
	SampleBase::getGray which calls cv::neon_cvtColorBGRA2GRAY(input, gray)

CartoonFilter.cpp
ContourDetectionSample.cpp
EdgeDetectionSample.cpp
FeatureDetectionSample.cpp
ObjectTrackingSample.cpp
VideoTracking.cpp
	all call getGray


Resources:
	-OpenCv iOS Tutorial
	-Explanation of grey conversion with cvneon from 2012
	http://computer-vision-talks.com/articles/2012-11-06-maximizing-performance-grayscale-color-conversion-using-neon-and-cvparallel_for/
	-OpenCV docs 
	http://docs.opencv.org/doc/tutorials/ios/table_of_content_ios/table_of_content_ios.html
	-OpenCV for iOS 
	http://www.packtpub.com/to-build-real-time%20computer%20vision%20applications%20for-ios-using-opencv/book
