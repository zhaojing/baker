//
//  TiledImageView.m
//  TiledImage
//
//  Created by Marco Colombo on 29/12/11.
//  Copyright (c) 2011 Marco Natale Colombo. All rights reserved.
//

#import "TiledImageView.h"

@implementation TiledImageView

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame andImage:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self)
    {
        CGimage = CGImageRetain(image.CGImage);
        
        CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
        
        // levelsOfDetail and levelsOfDetailBias determine how the layer is rendered at different zoom levels.
        // This only matters while the view is zooming, since once the view is done zooming
        // a new PDFPage is created at the correct size and scale.
        
        tiledLayer.levelsOfDetail = 1;
        tiledLayer.levelsOfDetailBias = 0;
        tiledLayer.tileSize = CGSizeMake(self.frame.size.width / 4, self.frame.size.height);
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    CGImageRelease(CGimage);
    [super dealloc];
}

#pragma mark - Drawing management


+ (Class)layerClass
{
    return [CATiledLayer class];
}
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // UIView uses the existence of -drawRect: to determine if should allow its CALayer to be invalidated,
    // which would then lead to the layer creating a backing store and -drawLayer:inContext: being called.
    // By implementing an empty -drawRect: method, we allow UIKit to continue to implement this logic,
    // while doing our real drawing work inside of -drawLayer:inContext:
}
- (void)drawLayer:(CALayer*)layer inContext:(CGContextRef)ctx
{
    CGContextScaleCTM(ctx, 1, -1);
    CGContextDrawTiledImage(ctx, self.frame, CGimage);
}


@end
