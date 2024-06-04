//
//  OpenCVWrapper.h
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 04.06.24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface OpenCVWrapper : NSObject

+ (UIImage*) processImageWithOpenCV: (UIImage*) inputImage;

@end
NS_ASSUME_NONNULL_END
