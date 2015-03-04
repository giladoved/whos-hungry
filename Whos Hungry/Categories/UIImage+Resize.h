//
//  UIImage+Resize.h
//  Who's Hungry
//
//  Created by Gilad Oved on 10/21/14.
//  Copyright (c) 2014 Who's Hungry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize;

@end
