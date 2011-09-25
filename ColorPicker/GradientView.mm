//
//  GradientView.mm
//  ColorPicker
//
//  Created by Matthew Eagar on 9/23/11.
//  Copyright 2011 ThinkFlood Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy 
//  of this software and associated documentation files (the "Software"), to deal 
//  in the Software without restriction, including without limitation the rights 
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
//  copies of the Software, and to permit persons to whom the Software is furnished 
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all 
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
//  SOFTWARE.

#import "GradientView.h"

#pragma mark Constants

#define COLOR_COMPONENT_RED_INDEX 0
#define COLOR_COMPONENT_GREEN_INDEX 1
#define COLOR_COMPONENT_BLUE_INDEX 2

#define COLOR_COMPONENT_ALPHA_VALUE 1.0f

#define COLOR_COMPONENT_COUNT 4

#define GRADIENT_DRAWING_OPTIONS_NONE 0

#pragma mark -
#pragma mark Implementation

@implementation GradientView

#pragma mark -
#pragma mark Properties

@dynamic colors;

- (NSArray *)colors {
    return _colors;
}

- (void)setColors:(NSArray *)colors {
    if (colors == _colors) {
        // continue
    }
    else if (colors.count > 1) {
        if (_colors) {
            [_colors release];
            CGGradientRelease(_gradient);
        }
        
        _colors = [colors copy];
        
        int componentCount = colors.count * COLOR_COMPONENT_COUNT;
        CGFloat gradientColors[componentCount];
        int counter = 0;
        for (UIColor *color in colors) {
            CGColorRef currentColor = [color CGColor];
            const CGFloat *colorComponents = CGColorGetComponents(currentColor);
            gradientColors[counter] = colorComponents[COLOR_COMPONENT_RED_INDEX];
            counter++;
            gradientColors[counter] = colorComponents[COLOR_COMPONENT_GREEN_INDEX];
            counter++;
            gradientColors[counter] = colorComponents[COLOR_COMPONENT_BLUE_INDEX];
            counter++;
            gradientColors[counter] = COLOR_COMPONENT_ALPHA_VALUE;
            counter++;
        }
        
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        
        size_t colorArraySize = 
            sizeof(gradientColors) / (sizeof(gradientColors[0]) * COLOR_COMPONENT_COUNT);
        _gradient = CGGradientCreateWithColorComponents(rgbColorSpace, 
                                                        gradientColors, 
                                                        NULL, 
                                                        colorArraySize);
        
        CGColorSpaceRelease(rgbColorSpace);
        
        [self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark Initializers

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _colors = nil;
        _gradient = nil;
    }
    
    return self;
}

#pragma mark -
#pragma mark Overrides

- (void)dealloc {
    if (_colors) {
        [_colors release];
        CGGradientRelease(_gradient);
    }
    
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);

    CGRect viewBounds = self.bounds;
    CGContextClipToRect(context, viewBounds);
	
	CGPoint startPoint = CGPointMake(0.0f, 0.0f);
	CGPoint endPoint = CGPointMake(viewBounds.size.width, 0.0f);
	CGContextDrawLinearGradient(context, 
                                _gradient, 
                                startPoint, 
                                endPoint, 
                                GRADIENT_DRAWING_OPTIONS_NONE);
	CGContextRestoreGState(context);
	CGContextSaveGState(context);
    
    [super drawRect:rect];
}

@end
