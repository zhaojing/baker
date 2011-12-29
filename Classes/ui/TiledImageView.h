//
//  TiledImageView.h
//  TiledImage
//
//  Created by Marco Colombo on 29/12/11.
//  Copyright (c) 2011 Marco Natale Colombo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface TiledImageView : UIView
{
    CGImageRef CGimage;
}

- (id)initWithFrame:(CGRect)frame andImage:(UIImage *)image;

@end
