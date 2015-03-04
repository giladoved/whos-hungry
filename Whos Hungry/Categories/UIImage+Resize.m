//
//  UIImage+Resize.m
//  Who's Hungry
//
//  Created by Gilad Oved on 10/21/14.
//  Copyright (c) 2014 Who's Hungry. All rights reserved.
//

#import "UIImage+Resize.h"


//http://ajourneywithios.blogspot.com/2012/03/resizing-uiimage-in-ios.html
@implementation UIImage (Resize)

+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
