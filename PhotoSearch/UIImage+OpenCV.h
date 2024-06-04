//
//  UIImage+OpenCV.h
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 04.06.24.
//

#import <UIKit/UIKit.h>

@interface UIImage (OpenCV)

    //cv::Mat to UIImage
+ (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat;
- (id)initWithCVMat:(const cv::Mat&)cvMat;

    //UIImage to cv::Mat
- (cv::Mat)CVMat;
- (cv::Mat)CVMat3;  // no alpha channel
- (cv::Mat)CVGrayscaleMat;

@end
