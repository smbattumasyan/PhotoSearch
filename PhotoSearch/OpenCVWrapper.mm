//
//  OpenCVWrapper.m
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 04.06.24.
//

#import "OpenCVWrapper.h"
#import "UIImage+OpenCV.h"
#import "lines.h"
#import "UIImage+Rotate.h"


@implementation OpenCVWrapper

+(UIImage*) processImageWithOpenCV: (UIImage*) inputImage
{
    if ([inputImage isKindOfClass: [UIImage class]]) {
        /*
         All images taken with the iPhone/iPa cameras are LANDSCAPE LEFT orientation. The  UIImage imageOrientation flag is an instruction to the OS to transform the image during display only. When we feed images into openCV, they need to be the actual orientation that we expect them to be for stitching. So we rotate the actual pixel matrix here if required.
         */
        UIImage* rotatedImage = [inputImage rotateToImageOrientation];
        cv::Mat matImage = [rotatedImage CVMat3];
        cv::Mat matLines = lines(matImage);
        UIImage* result = [UIImage imageWithCVMat:matLines];
        return result;
    }
    return nullptr;
}

@end
