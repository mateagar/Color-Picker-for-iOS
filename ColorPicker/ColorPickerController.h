//
//  ColorPickerController.h
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

#import <UIKit/UIKit.h>
#import "GradientView.h"

@class ColorPickerController;

@protocol ColorPickerDelegate <NSObject>

- (void)colorPickerSaved:(ColorPickerController *)controller;
- (void)colorPickerCancelled:(ColorPickerController *)controller;

@end

typedef struct {
    int hueValue;
    int saturationValue;
    int brightnessValue;
    CGFloat hue;
    CGFloat saturation;
    CGFloat brightness;
} HsvColor;

typedef struct {
    int redValue;
    int greenValue;
    int blueValue;
    CGFloat red;
    CGFloat green;
    CGFloat blue;
} RgbColor;

@interface ColorPickerController : UIViewController 
                                  <UITextFieldDelegate>
{
    
@private
    UIColor *_selectedColor;
    UIView *_colorView;
    UIImageView *_hueSaturationView;
    GradientView *_brightnessView;
    UIImageView *_horizontalSelector;
    UIImageView *_crosshairSelector;
    UITextField *_hueField;
    UITextField *_saturationField;
    UITextField *_brightnessField;
    UITextField *_redField;
    UITextField *_greenField;
    UITextField *_blueField;
    UITextField *_hexField;
    HsvColor _hsvColor;
    id<ColorPickerDelegate> _delegate;
    UITextField *_entryField;
    UIImageView *_movingView;
    NSCharacterSet *_hexadecimalCharacters;
    NSCharacterSet *_decimalCharacters;
    
}

+ (HsvColor)hsvColorFromColor:(UIColor *)color;
+ (RgbColor)rgbColorFromColor:(UIColor *)color;
+ (NSString *)hexValueFromColor:(UIColor *)color;
+ (UIColor *)colorFromHexValue:(NSString *)hexValue;
+ (BOOL)isValidHexValue:(NSString *)hexValue;

@property (nonatomic, readwrite, retain) UIColor *selectedColor;
@property (nonatomic, readwrite, assign) id<ColorPickerDelegate> delegate;

- (id)initWithColor:(UIColor *)color andTitle:(NSString *)title;

@end
