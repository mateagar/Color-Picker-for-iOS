//
//  ColorPickerController.mm
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

#import "ColorPickerController.h"
#import <QuartzCore/QuartzCore.h>

#pragma Constants

#define BACKGROUND_WHITE_COMPONENT 0.9f
#define BACKGROUND_ALPHA_COMPONENT 1.0f

#define DEFAULT_MARGIN 10.0f
#define LABEL_MARGIN 5.0f

#define LABEL_HEIGHT 21.0f
#define LABEL_WIDTH 35.0f

#define TEXT_FIELD_HEIGHT 31.0f

#define COLOR_VIEW_CORNER_RADIUS 5.0f
#define COLOR_VIEW_HEIGHT 103.0f

#define HEXADECIMAL_TEXT_FIELD_WDITH LABEL_WIDTH * 2.0f + LABEL_MARGIN

#define GRADIENT_HEIGHT 37.0f

#define HUE_SATURATION_IMAGE_FILE_NAME @"HueSaturationGradient.png"
#define HORIZONTAL_SELECTOR_IMAGE_FILE_NAME @"HorizontalSelector.png"
#define CROSSHAIR_SELECTOR_IMAGE_FILE_NAME @"CrosshairSelector.png"

#define COLOR_COMPONENT_RED_INDEX 0
#define COLOR_COMPONENT_GREEN_INDEX 1
#define COLOR_COMPONENT_BLUE_INDEX 2
#define COLOR_COMPONENT_SCALE_FACTOR 255.0f
#define COMPONENT_DOMAIN_DEGREES 60.0f
#define COMPONENT_MAXIMUM_DEGREES 360.0f
#define COMPONENT_OFFSET_DEGREES_GREEN 120.0f
#define COMPONENT_OFFSET_DEGREES_BLUE 240.0f
#define COMPONENT_PERCENTAGE 100.0f

#define INTEGER_FORMAT_STRING @"%i"
#define HEXADECIMAL_FORMAT_STRING @"%02X%02X%02X"
#define HEXADECIMAL_LENGTH 6
#define INTEGER_LENGTH 3

#define ANIMATION_DURATION 0.5f

#define HEXADECIMAL_CHARACTERS @"0123456789ABCDEF"
#define DECIMAL_CHARACTERS @"0123456789"

#define HEXADECIMAL_RED_LOCATION 0
#define HEXADECIMAL_GREEN_LOCATION 2
#define HEXADECIMAL_BLUE_LOCATION 4
#define HEXADECIMAL_COMPONENT_LENGTH 2

#pragma Private Method Declarations

@interface ColorPickerController ()

+ (NSString *)hexValueFromRgbColor:(RgbColor)color;
+ (HsvColor)hsvColorFromRgbColor:(RgbColor)color;
+ (BOOL)stringIsValid:(NSString *)string 
      forCharacterSet:(NSCharacterSet *)characters;
- (void)setColorValues;
- (void)moveSelectors;
- (void)cancelButtonPressed;
- (void)saveButtonPressed;
- (void)evaluateTouchForHueSaturation:(UITouch *)touch;
- (void)evaluateTouchForBrightness:(UITouch *)touch;

@end

#pragma Implementation

@implementation ColorPickerController

@dynamic selectedColor;
@synthesize delegate = _delegate;

#pragma Class Methods

+ (HsvColor)hsvColorFromColor:(UIColor *)color {
    RgbColor rgbColor = [ColorPickerController rgbColorFromColor:color];
    return [ColorPickerController hsvColorFromRgbColor:rgbColor];
}

+ (RgbColor)rgbColorFromColor:(UIColor *)color {
    RgbColor rgbColor;
    
    CGColorRef cgColor = [color CGColor];
    const CGFloat *colorComponents = CGColorGetComponents(cgColor);
    rgbColor.red = colorComponents[COLOR_COMPONENT_RED_INDEX];
    rgbColor.green = colorComponents[COLOR_COMPONENT_GREEN_INDEX];
    rgbColor.blue = colorComponents[COLOR_COMPONENT_BLUE_INDEX];
    
    rgbColor.redValue = (int)(rgbColor.red * COLOR_COMPONENT_SCALE_FACTOR);
    rgbColor.greenValue = (int)(rgbColor.green * COLOR_COMPONENT_SCALE_FACTOR);
    rgbColor.blueValue = (int)(rgbColor.blue * COLOR_COMPONENT_SCALE_FACTOR);

    return rgbColor;
}

+ (NSString *)hexValueFromColor:(UIColor *)color {
    RgbColor rgbColor = [ColorPickerController rgbColorFromColor:color];
    return [ColorPickerController hexValueFromRgbColor:rgbColor];
}

+ (UIColor *)colorFromHexValue:(NSString *)hexValue {
    UIColor *color = [UIColor blackColor];
    
    NSRange componentRange = NSMakeRange(HEXADECIMAL_RED_LOCATION, 
                                         HEXADECIMAL_COMPONENT_LENGTH);
    NSString *redComponent = [hexValue substringWithRange:componentRange];
    
    componentRange.location = HEXADECIMAL_GREEN_LOCATION;
    NSString *greenComponent = [hexValue substringWithRange:componentRange];
    
    componentRange.location = HEXADECIMAL_BLUE_LOCATION;
    NSString *blueComponent = [hexValue substringWithRange:componentRange];
    
    uint red = 0;
    uint green = 0;
    uint blue = 0;
    [[NSScanner scannerWithString:redComponent] scanHexInt:&red];
    [[NSScanner scannerWithString:greenComponent] scanHexInt:&green];
    [[NSScanner scannerWithString:blueComponent] scanHexInt:&blue];
    
    color = [UIColor colorWithRed:red / COLOR_COMPONENT_SCALE_FACTOR
                            green:green / COLOR_COMPONENT_SCALE_FACTOR
                             blue:blue / COLOR_COMPONENT_SCALE_FACTOR
                            alpha:1.0f];
    
    return color;
}

+ (BOOL)isValidHexValue:(NSString *)hexValue {
    BOOL isValid = NO;
    
    NSString *trimmedString = 
        [hexValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedString.length == HEXADECIMAL_LENGTH) {
        NSCharacterSet *hexadecimalCharacters = 
        [NSCharacterSet characterSetWithCharactersInString:HEXADECIMAL_CHARACTERS];
        if ([ColorPickerController stringIsValid:trimmedString
                                 forCharacterSet:hexadecimalCharacters]) {
            isValid = YES;
        }
    }
    
    return isValid;
}

+ (NSString *)hexValueFromRgbColor:(RgbColor)color {
    return [NSString stringWithFormat:HEXADECIMAL_FORMAT_STRING,
                                      color.redValue,
                                      color.greenValue,
                                      color.blueValue];
}

+ (HsvColor)hsvColorFromRgbColor:(RgbColor)color {
    HsvColor hsvColor;
    
    CGFloat maximumValue = MAX(color.red, color.green);
    maximumValue = MAX(maximumValue, color.blue);
    CGFloat minimumValue = MIN(color.red, color.green);
    minimumValue = MIN(minimumValue, color.blue);
    CGFloat range = maximumValue - minimumValue;
    
    hsvColor.hueValue = 0;
    if (maximumValue == minimumValue) {
        // continue
    }
    else if (maximumValue == color.red) {
        hsvColor.hueValue = 
            (int)roundf(COMPONENT_DOMAIN_DEGREES * (color.green - color.blue) / range);
        if (hsvColor.hueValue < 0) {
            hsvColor.hueValue += COMPONENT_MAXIMUM_DEGREES;
        }
    }
    else if (maximumValue == color.green) {
        hsvColor.hueValue = 
            (int)roundf(((COMPONENT_DOMAIN_DEGREES * (color.blue - color.red) / range) + 
                         COMPONENT_OFFSET_DEGREES_GREEN));
    }
    else if (maximumValue == color.blue) {
        hsvColor.hueValue = 
            (int)roundf(((COMPONENT_DOMAIN_DEGREES * (color.red - color.green) / range) + 
                         COMPONENT_OFFSET_DEGREES_BLUE));
    }
    
    hsvColor.saturationValue = 0;
    if (maximumValue == 0.0f) {
        // continue
    }
    else {
        hsvColor.saturationValue = 
            (int)roundf(((1.0f - (minimumValue / maximumValue)) * COMPONENT_PERCENTAGE));
    }
    
    hsvColor.brightnessValue = (int)roundf((maximumValue * COMPONENT_PERCENTAGE));
    
    hsvColor.hue = (float)hsvColor.hueValue / COMPONENT_MAXIMUM_DEGREES;
    hsvColor.saturation = (float)hsvColor.saturationValue / COMPONENT_PERCENTAGE;
    hsvColor.brightness = (float)hsvColor.brightnessValue / COMPONENT_PERCENTAGE;
    
    return hsvColor;
}

+ (BOOL)stringIsValid:(NSString *)string 
      forCharacterSet:(NSCharacterSet *)characters {
    BOOL isValid = YES;
    
    for (int counter = 0; counter < string.length; counter++) {
        unichar currentCharacter = [string characterAtIndex:counter];
        if ([characters characterIsMember:currentCharacter]) {
            // continue
        }
        else {
            isValid = NO;
            break;
        }
    }
    
    return isValid;
}

#pragma Properties

- (UIColor *)selectedColor {
    return _selectedColor;
}

- (void)setSelectedColor:(UIColor *)selectedColor {
    [_selectedColor autorelease];
    _selectedColor = [selectedColor retain];
    [self setColorValues];
}

#pragma Initializers

- (id)initWithColor:(UIColor *)color andTitle:(NSString *)title {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _selectedColor = [color retain];
        _delegate = nil;
        _entryField = nil;
        _movingView = nil;
        _hexadecimalCharacters = 
            [[NSCharacterSet characterSetWithCharactersInString:HEXADECIMAL_CHARACTERS] retain];
        _decimalCharacters = 
            [[NSCharacterSet characterSetWithCharactersInString:DECIMAL_CHARACTERS] retain];
        
        self.navigationItem.title = title;
    }

    return self;
}

#pragma Overrides

- (void)dealloc {
    [_selectedColor release];
    [_hexadecimalCharacters release];
    [_decimalCharacters release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadView {
    CGRect viewBounds = self.parentViewController.view.bounds;
    UIView *backgroundView = [[UIView alloc] initWithFrame:viewBounds];
    backgroundView.backgroundColor = [UIColor colorWithWhite:BACKGROUND_WHITE_COMPONENT
                                                       alpha:BACKGROUND_ALPHA_COMPONENT];
    backgroundView.autoresizesSubviews = YES;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | 
                                      UIViewAutoresizingFlexibleHeight;
    self.view = [backgroundView autorelease];
    
    UIBarButtonItem *cancelButton = 
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self 
                                                      action:@selector(cancelButtonPressed)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    
    UIBarButtonItem *saveButton = 
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                      target:self
                                                      action:@selector(saveButtonPressed)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];
    
    UILabel *hueSaturationValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    hueSaturationValueLabel.text = 
        NSLocalizedString(@"HueSaturationValueLabelText", @"");
    hueSaturationValueLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    hueSaturationValueLabel.frame = CGRectMake(DEFAULT_MARGIN, 
                                               DEFAULT_MARGIN + LABEL_MARGIN, 
                                               LABEL_WIDTH, 
                                               LABEL_HEIGHT);
    hueSaturationValueLabel.autoresizingMask = UIViewAutoresizingNone;
    hueSaturationValueLabel.textAlignment = UITextAlignmentRight;
    hueSaturationValueLabel.backgroundColor = [UIColor clearColor];
    [backgroundView addSubview:hueSaturationValueLabel];
    [hueSaturationValueLabel release];
    
    CGFloat labelRightEdge = DEFAULT_MARGIN + LABEL_WIDTH;
    
    _hueField = [[UITextField alloc] initWithFrame:CGRectZero];
    _hueField.frame = CGRectMake(labelRightEdge + LABEL_MARGIN, 
                                 DEFAULT_MARGIN, 
                                 LABEL_WIDTH, 
                                 TEXT_FIELD_HEIGHT);
    _hueField.autoresizingMask = UIViewAutoresizingNone;
    _hueField.textAlignment = UITextAlignmentCenter;
    _hueField.borderStyle = UITextBorderStyleLine;
    _hueField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _hueField.returnKeyType = UIReturnKeyDone;
    _hueField.autocorrectionType = UITextAutocorrectionTypeNo;
    _hueField.backgroundColor = [UIColor whiteColor];
    _hueField.delegate = self;
    [backgroundView addSubview:_hueField];
    [_hueField release];
    
    labelRightEdge += LABEL_WIDTH + LABEL_MARGIN;
    
    _saturationField = [[UITextField alloc] initWithFrame:CGRectZero];
    _saturationField.frame = CGRectMake(labelRightEdge + LABEL_MARGIN, 
                                        DEFAULT_MARGIN, 
                                        LABEL_WIDTH, 
                                        TEXT_FIELD_HEIGHT);
    _saturationField.autoresizingMask = UIViewAutoresizingNone;
    _saturationField.textAlignment = UITextAlignmentCenter;
    _saturationField.borderStyle = UITextBorderStyleLine;
    _saturationField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _saturationField.returnKeyType = UIReturnKeyDone;
    _saturationField.autocorrectionType = UITextAutocorrectionTypeNo;
    _saturationField.backgroundColor = [UIColor whiteColor];
    _saturationField.delegate = self;
    [backgroundView addSubview:_saturationField];
    [_saturationField release];
    
    labelRightEdge += LABEL_WIDTH + LABEL_MARGIN;
    
    _brightnessField = [[UITextField alloc] initWithFrame:CGRectZero];
    _brightnessField.frame = CGRectMake(labelRightEdge + LABEL_MARGIN,
                                       DEFAULT_MARGIN, 
                                       LABEL_WIDTH, 
                                       TEXT_FIELD_HEIGHT);
    _brightnessField.autoresizingMask = UIViewAutoresizingNone;
    _brightnessField.textAlignment = UITextAlignmentCenter;
    _brightnessField.borderStyle = UITextBorderStyleLine;
    _brightnessField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _brightnessField.returnKeyType = UIReturnKeyDone;
    _brightnessField.autocorrectionType = UITextAutocorrectionTypeNo;
    _brightnessField.backgroundColor = [UIColor whiteColor];
    _brightnessField.delegate = self;
    [backgroundView addSubview:_brightnessField];
    [_brightnessField release];

    labelRightEdge += LABEL_WIDTH + LABEL_MARGIN;

    _colorView = [[UIView alloc] initWithFrame:CGRectZero];
    _colorView.layer.cornerRadius = COLOR_VIEW_CORNER_RADIUS;
    _colorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    CGFloat colorViewLeftEdge = labelRightEdge + DEFAULT_MARGIN;
    _colorView.frame = CGRectMake(colorViewLeftEdge, 
                                  DEFAULT_MARGIN, 
                                  viewBounds.size.width - DEFAULT_MARGIN - colorViewLeftEdge, 
                                  COLOR_VIEW_HEIGHT);
    [backgroundView addSubview:_colorView];
    [_colorView release];
    
    CGFloat textFieldBottomEdge = DEFAULT_MARGIN + TEXT_FIELD_HEIGHT + LABEL_MARGIN;
    
    UILabel *redGreenBlueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    redGreenBlueLabel.text = 
        NSLocalizedString(@"RedGreenBlueLabelText", @"");
    redGreenBlueLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    redGreenBlueLabel.frame = CGRectMake(DEFAULT_MARGIN, 
                                         textFieldBottomEdge + LABEL_MARGIN, 
                                         LABEL_WIDTH, 
                                         LABEL_HEIGHT);
    redGreenBlueLabel.autoresizingMask = UIViewAutoresizingNone;
    redGreenBlueLabel.textAlignment = UITextAlignmentRight;
    redGreenBlueLabel.backgroundColor = [UIColor clearColor];
    [backgroundView addSubview:redGreenBlueLabel];
    [redGreenBlueLabel release];
    
    labelRightEdge = DEFAULT_MARGIN + LABEL_WIDTH;
    
    _redField = [[UITextField alloc] initWithFrame:CGRectZero];
    _redField.frame = CGRectMake(labelRightEdge + LABEL_MARGIN, 
                                 textFieldBottomEdge, 
                                 LABEL_WIDTH, 
                                 TEXT_FIELD_HEIGHT);
    _redField.autoresizingMask = UIViewAutoresizingNone;
    _redField.textAlignment = UITextAlignmentCenter;
    _redField.borderStyle = UITextBorderStyleLine;
    _redField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _redField.returnKeyType = UIReturnKeyDone;
    _redField.autocorrectionType = UITextAutocorrectionTypeNo;
    _redField.backgroundColor = [UIColor whiteColor];
    _redField.delegate = self;
    [backgroundView addSubview:_redField];
    [_redField release];
    
    labelRightEdge += LABEL_WIDTH + LABEL_MARGIN;
    
    _greenField = [[UITextField alloc] initWithFrame:CGRectZero];
    _greenField.frame = CGRectMake(labelRightEdge + LABEL_MARGIN, 
                                   textFieldBottomEdge, 
                                   LABEL_WIDTH, 
                                   TEXT_FIELD_HEIGHT);
    _greenField.autoresizingMask = UIViewAutoresizingNone;
    _greenField.textAlignment = UITextAlignmentCenter;
    _greenField.borderStyle = UITextBorderStyleLine;
    _greenField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _greenField.returnKeyType = UIReturnKeyDone;
    _greenField.autocorrectionType = UITextAutocorrectionTypeNo;
    _greenField.backgroundColor = [UIColor whiteColor];
    _greenField.delegate = self;
    [backgroundView addSubview:_greenField];
    [_greenField release];
    
    labelRightEdge += LABEL_WIDTH + LABEL_MARGIN;
    
    _blueField = [[UITextField alloc] initWithFrame:CGRectZero];
    _blueField.frame = CGRectMake(labelRightEdge + LABEL_MARGIN,
                                  textFieldBottomEdge, 
                                  LABEL_WIDTH, 
                                  TEXT_FIELD_HEIGHT);
    _blueField.autoresizingMask = UIViewAutoresizingNone;
    _blueField.textAlignment = UITextAlignmentCenter;
    _blueField.borderStyle = UITextBorderStyleLine;
    _blueField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _blueField.returnKeyType = UIReturnKeyDone;
    _blueField.autocorrectionType = UITextAutocorrectionTypeNo;
    _blueField.backgroundColor = [UIColor whiteColor];
    _blueField.delegate = self;
    [backgroundView addSubview:_blueField];
    [_blueField release];

    textFieldBottomEdge += TEXT_FIELD_HEIGHT + LABEL_MARGIN;
    
    UILabel *hexadecimalLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    hexadecimalLabel.text = 
        NSLocalizedString(@"HexadecimalLabelText", @"");
    hexadecimalLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    hexadecimalLabel.frame = CGRectMake(DEFAULT_MARGIN, 
                                        textFieldBottomEdge + LABEL_MARGIN, 
                                        LABEL_WIDTH, 
                                        LABEL_HEIGHT);
    hexadecimalLabel.autoresizingMask = UIViewAutoresizingNone;
    hexadecimalLabel.textAlignment = UITextAlignmentRight;
    hexadecimalLabel.backgroundColor = [UIColor clearColor];
    [backgroundView addSubview:hexadecimalLabel];
    [hexadecimalLabel release];
    
    labelRightEdge = DEFAULT_MARGIN + LABEL_WIDTH;
    
    _hexField = [[UITextField alloc] initWithFrame:CGRectZero];
    _hexField.frame = CGRectMake(labelRightEdge + LABEL_MARGIN, 
                                 textFieldBottomEdge, 
                                 HEXADECIMAL_TEXT_FIELD_WDITH, 
                                 TEXT_FIELD_HEIGHT);
    _hexField.autoresizingMask = UIViewAutoresizingNone;
    _hexField.textAlignment = UITextAlignmentCenter;
    _hexField.borderStyle = UITextBorderStyleLine;
    _hexField.keyboardType = UIKeyboardTypeASCIICapable;
    _hexField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    _hexField.autocorrectionType = UITextAutocorrectionTypeNo;
    _hexField.returnKeyType = UIReturnKeyDone;
    _hexField.backgroundColor = [UIColor whiteColor];
    _hexField.delegate = self;
    [backgroundView addSubview:_hexField];
    [_hexField release];
    
    textFieldBottomEdge += TEXT_FIELD_HEIGHT + DEFAULT_MARGIN;
    
    CGRect gradientFrame = CGRectMake(DEFAULT_MARGIN, 
                                      viewBounds.size.height - DEFAULT_MARGIN - GRADIENT_HEIGHT, 
                                      viewBounds.size.width - 2.0f * DEFAULT_MARGIN, 
                                      GRADIENT_HEIGHT);
    _brightnessView = [[GradientView alloc] initWithFrame:gradientFrame];
    _brightnessView.colors = [NSArray arrayWithObjects:_selectedColor,
                                                       [UIColor colorWithRed:0.0f 
                                                                       green:0.0f 
                                                                        blue:0.0f 
                                                                       alpha:1.0f],
                                                       nil];
    _brightnessView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                               UIViewAutoresizingFlexibleTopMargin;
    [backgroundView addSubview:_brightnessView];
    [_brightnessView release];

    UIImage *horizontalSelectorImage = 
        [UIImage imageNamed:HORIZONTAL_SELECTOR_IMAGE_FILE_NAME];
    _horizontalSelector = [[UIImageView alloc] initWithImage:horizontalSelectorImage];
    _horizontalSelector.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    CGRect selectorFrame = _horizontalSelector.frame;
    selectorFrame.origin.x = gradientFrame.origin.x;
    selectorFrame.origin.y = gradientFrame.origin.y;
    _horizontalSelector.frame = selectorFrame;
    [backgroundView addSubview:_horizontalSelector];
    [_horizontalSelector release];
    
    
    CGFloat hueSaturationHeight = viewBounds.size.height - 
                                  2.0f * DEFAULT_MARGIN - 
                                  GRADIENT_HEIGHT - 
                                  textFieldBottomEdge;
    CGRect hueSaturationFrame = CGRectMake(DEFAULT_MARGIN, 
                                           textFieldBottomEdge, 
                                           viewBounds.size.width - 2.0f * DEFAULT_MARGIN, 
                                           hueSaturationHeight);
    UIView *hueSaturationBackgroundView = 
        [[UIView alloc] initWithFrame:hueSaturationFrame];
    hueSaturationBackgroundView.backgroundColor = [UIColor blackColor];
    hueSaturationBackgroundView.autoresizingMask = 
        UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    hueSaturationBackgroundView.autoresizesSubviews = YES;
    hueSaturationBackgroundView.clipsToBounds = YES;
    [backgroundView addSubview:hueSaturationBackgroundView];
    [hueSaturationBackgroundView release];

    UIImage *hueSaturationImage = [UIImage imageNamed:HUE_SATURATION_IMAGE_FILE_NAME];
    _hueSaturationView = [[UIImageView alloc] initWithImage:hueSaturationImage];
    _hueSaturationView.contentMode = UIViewContentModeScaleToFill;
    _hueSaturationView.autoresizingMask = UIViewAutoresizingFlexibleHeight | 
                                          UIViewAutoresizingFlexibleWidth;
    _hueSaturationView.frame = hueSaturationBackgroundView.bounds;
    _hueSaturationView.opaque = NO;
    [hueSaturationBackgroundView addSubview:_hueSaturationView];
    [_hueSaturationView release];

    UIImage *crosshairSelectorImage =
        [UIImage imageNamed:CROSSHAIR_SELECTOR_IMAGE_FILE_NAME];
    _crosshairSelector = [[UIImageView alloc] initWithImage:crosshairSelectorImage];
    [hueSaturationBackgroundView addSubview:_crosshairSelector];
    [_crosshairSelector release];

    [self setColorValues];
}

- (void)viewDidAppear:(BOOL)animated {
    [self moveSelectors];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
                                         duration:(NSTimeInterval)duration {
    [self moveSelectors];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    if (_entryField) {
        if (CGRectContainsPoint(_entryField.frame, touchPoint)) {
            // continue
        }
        else {
            [_entryField resignFirstResponder];
        }
    }
    else if (CGRectContainsPoint(_hueSaturationView.frame, touchPoint)) {
        _movingView = _crosshairSelector;
        [self evaluateTouchForHueSaturation:touch];
        [self moveSelectors];
    }
    else if (CGRectContainsPoint(_brightnessView.frame, touchPoint)) {
        _movingView = _horizontalSelector;
        [self evaluateTouchForBrightness:touch];
        [self moveSelectors];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (_movingView == _crosshairSelector) {
        [self evaluateTouchForHueSaturation:touch];
        [self moveSelectors];
    }
    else if (_movingView == _horizontalSelector) {
        [self evaluateTouchForBrightness:touch];
        [self moveSelectors];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (_movingView == _crosshairSelector) {
        [self evaluateTouchForHueSaturation:touch];
        [self moveSelectors];
    }
    else if (_movingView == _horizontalSelector) {
        [self evaluateTouchForBrightness:touch];
        [self moveSelectors];
    }
    
    _movingView = nil;
}

#pragma Private Methods

- (void)setColorValues {
    if (_colorView) {
        _colorView.backgroundColor = _selectedColor;
        
        RgbColor rgbColor = 
            [ColorPickerController rgbColorFromColor:_selectedColor];
        _redField.text = [NSString stringWithFormat:INTEGER_FORMAT_STRING, 
                                                    rgbColor.redValue];
        _greenField.text = [NSString stringWithFormat:INTEGER_FORMAT_STRING,
                                                      rgbColor.greenValue];
        _blueField.text = [NSString stringWithFormat:INTEGER_FORMAT_STRING,
                                                     rgbColor.blueValue];
        
        _hexField.text = [ColorPickerController hexValueFromRgbColor:rgbColor];
        
        _hsvColor = [ColorPickerController hsvColorFromRgbColor:rgbColor];
        _hueField.text = [NSString stringWithFormat:INTEGER_FORMAT_STRING,
                                                    _hsvColor.hueValue];
        _saturationField.text = [NSString stringWithFormat:INTEGER_FORMAT_STRING,
                                                           _hsvColor.saturationValue];
        _brightnessField.text = [NSString stringWithFormat:INTEGER_FORMAT_STRING,
                                                           _hsvColor.brightnessValue];
        
        _brightnessView.colors = 
            [NSArray arrayWithObjects:[UIColor colorWithHue:_hsvColor.hue
                                                 saturation:_hsvColor.saturation 
                                                 brightness:1.0f
                                                      alpha:1.0f],  
                                      [UIColor colorWithRed:0.0f 
                                                      green:0.0f 
                                                       blue:0.0f 
                                                      alpha:1.0f], 
                                      nil];
        
        _hueSaturationView.alpha = _hsvColor.brightness;
    }
}

- (void)moveSelectors {
    CGRect hueSaturationBounds = _hueSaturationView.bounds;
    CGPoint crosshairCenter = 
    CGPointMake(_hsvColor.hue * hueSaturationBounds.size.width, 
                (1.0f - _hsvColor.saturation) * hueSaturationBounds.size.height);
    
    CGRect brightnessFrame = _brightnessView.frame;
    CGPoint horizontalCenter = 
    CGPointMake(brightnessFrame.origin.x + (1.0f - _hsvColor.brightness) * brightnessFrame.size.width, 
                brightnessFrame.origin.y + (brightnessFrame.size.height / 2.0f));
    
    _crosshairSelector.center = crosshairCenter;
    _horizontalSelector.center = horizontalCenter;
}

- (void)cancelButtonPressed {
    if (_delegate) {
        [_delegate colorPickerCancelled:self];
    }
}

- (void)saveButtonPressed {
    if (_delegate) {
        [_delegate colorPickerSaved:self];
    }
}

- (void)evaluateTouchForHueSaturation:(UITouch *)touch {
    CGPoint touchPoint = [touch locationInView:_hueSaturationView];
    CGRect viewBounds = _hueSaturationView.bounds;
    
    CGFloat hue = touchPoint.x / viewBounds.size.width;
    if (hue < 0.0f) {
        hue = 0.0f;
    }
    else if (hue > 1.0f) {
        hue = 1.0f;
    }
    
    CGFloat saturation = 
        (viewBounds.size.height - touchPoint.y) / viewBounds.size.height;
    if (saturation < 0.0f) {
        saturation = 0.0f;
    }
    else if (saturation > 1.0f) {
        saturation = 1.0f;
    }
    
    self.selectedColor = [UIColor colorWithHue:hue
                                    saturation:saturation
                                    brightness:_hsvColor.brightness 
                                         alpha:1.0f];
}

- (void)evaluateTouchForBrightness:(UITouch *)touch {
    CGPoint touchPoint = [touch locationInView:_brightnessView];
    CGRect viewBounds = _brightnessView.bounds;
    
    CGFloat brightness = 
        (viewBounds.size.width - touchPoint.x) / viewBounds.size.width;
    if (brightness < 0.0f) {
        brightness = 0.0f;
    }
    else if (brightness > 1.0f) {
        brightness = 1.0f;
    }
    
    self.selectedColor = [UIColor colorWithHue:_hsvColor.hue 
                                    saturation:_hsvColor.saturation
                                    brightness:brightness 
                                         alpha:1.0f];
}

#pragma UITextField Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _entryField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.text.length == 0) {
        self.selectedColor = _selectedColor;
    }
    else if (textField == _hexField) {
        NSString *hexadecimalColor = textField.text;
        if ([ColorPickerController isValidHexValue:hexadecimalColor]) {
            self.selectedColor = 
                [ColorPickerController colorFromHexValue:hexadecimalColor];
            [self moveSelectors];
        }
        else {
            self.selectedColor = _selectedColor;
        }
    }
    else if (textField == _redField || 
             textField == _greenField ||
             textField == _blueField) {
        CGFloat redValue = [_redField.text floatValue];
        CGFloat greenValue = [_greenField.text floatValue];
        CGFloat blueValue = [_blueField.text floatValue];
        self.selectedColor = [UIColor colorWithRed:redValue / COLOR_COMPONENT_SCALE_FACTOR
                                             green:greenValue / COLOR_COMPONENT_SCALE_FACTOR
                                              blue:blueValue / COLOR_COMPONENT_SCALE_FACTOR
                                             alpha:1.0f];
        [self moveSelectors];
    }
    else {
        CGFloat hueValue = [_hueField.text floatValue];
        CGFloat saturationValue = [_saturationField.text floatValue];
        CGFloat brightnessValue = [_brightnessField.text floatValue];
        self.selectedColor = [UIColor colorWithHue:hueValue / COMPONENT_MAXIMUM_DEGREES
                                        saturation:saturationValue / COMPONENT_PERCENTAGE 
                                        brightness:brightnessValue / COMPONENT_PERCENTAGE
                                             alpha:1.0f];
        [self moveSelectors];
    }
    
    _entryField = nil;
}

-             (BOOL)textField:(UITextField *)textField 
shouldChangeCharactersInRange:(NSRange)range 
            replacementString:(NSString *)string {
    BOOL replace = YES;
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range 
                                                                withString:string];
    
    if (textField == _hexField) {
        if (newText.length > HEXADECIMAL_LENGTH) {
            replace = NO;
        }
        else {
            replace = [ColorPickerController stringIsValid:newText 
                                           forCharacterSet:_hexadecimalCharacters];
        }
    }
    else {
        if (newText.length > INTEGER_LENGTH) {
            replace = NO;
        }
        else {
            int integerValue = [newText intValue];
            if (textField == _hueField && integerValue > COMPONENT_MAXIMUM_DEGREES) {
                replace = NO; 
            }
            else if ((textField == _saturationField || textField == _brightnessField) &&
                     integerValue > COMPONENT_PERCENTAGE) {
                replace = NO;
            }
            else if ((textField == _redField || 
                      textField == _greenField || 
                      textField == _blueField) && 
                     integerValue > COLOR_COMPONENT_SCALE_FACTOR) {
                replace = NO;
            }
            
            if (replace) {
                replace = [ColorPickerController stringIsValid:newText 
                                               forCharacterSet:_decimalCharacters];
            }
        }
    }
    
    return replace;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end
