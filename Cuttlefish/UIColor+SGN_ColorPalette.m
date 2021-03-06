//
//  _____ _           _____
// |   __| |_ ___ ___|   __|_ _ ___
// |__   |   | . | . |  |  | | |   |
// |_____|_|_|___|  _|_____|___|_|_|
//               |_|
//
//  Copyright (c) 2015 ShopGun. All rights reserved.


#import "UIColor+SGN_ColorPalette.h"


CGFloat sgn_getModifiedHueForShade(CGFloat baseHue, SGN_ColorPaletteShade shade)
{
    // darker shade - decrease hue
    if (shade > 500)
    {
        CGFloat hueAt900 = (1.003*baseHue) - 0.016;
        
        // lerp shade 500->900
        return ((hueAt900 - baseHue)/(900-500))*(shade-500) + baseHue;
    }
    else
    {
        return baseHue;
    }
}
CGFloat sgn_getModifiedSaturationForShade(CGFloat baseSaturation, SGN_ColorPaletteShade shade)
{
    // lighter shade - decrease saturation
    if (shade < 500)
    {
        // get the saturation target @ 50:
        // clamp to 0.0
        CGFloat satAt50 = MAX((0.136 * baseSaturation) - 0.025, 0.0);
        
        // lerp shade 500->900
        return ((baseSaturation - satAt50)/(500-50))*(shade-50) + satAt50;
    }
    // darker shade - increase saturation
    else if (shade > 500)
    {
        // get the saturation target @ 900:
        // quick inaccurate version:
        // 110% of the base saturation (clamped to 1.0)
        //            CGFloat satAt900 = MIN(baseSaturation * 1.10, 1.0);
        
        // expensive(?) accurate version
        CGFloat satAt900 = MIN((-1.019*baseSaturation*baseSaturation)+(2.283*baseSaturation)-0.281, 1.0);
        
        // lerp shade 500->900
        return ((satAt900 - baseSaturation)/(900-500))*(shade-500) + baseSaturation;
    }
    else
    {
        return baseSaturation;
    }
}

CGFloat sgn_getModifiedLightnessForShade(CGFloat baseLightness, SGN_ColorPaletteShade shade)
{
    CGFloat lightnessPercentage = 0;
    
    // We have modifier-percentages that map to shades.
    // Use this list to find the matching percentage, or lerp if the shade is not on a x100 bounds
    NSArray* percentageRanges = @[@1.06, //0 - lerp from 50&100
                                  //@0.88, //50
                                  @0.70, //100
                                  @0.50, //200
                                  @0.30, //300
                                  @0.15, //400
                                  @0.00, //500
                                  @-0.10, //600
                                  @-0.25, //700
                                  @-0.42, //800
                                  @-0.59, //900
                                  ];
    
    CGFloat indexFloat = ((CGFloat)shade)/100.0;
    
    NSInteger lowerIndex = MIN(MAX((NSInteger)floor(indexFloat), 0), percentageRanges.count-1);
    NSInteger upperIndex = MIN(MAX((NSInteger)ceil(indexFloat), 0), percentageRanges.count-1);
    
    CGFloat lowerPercentage = [percentageRanges[lowerIndex] floatValue];
    
    if (lowerIndex!=upperIndex)
    {
        CGFloat upperPercentage = [percentageRanges[upperIndex] floatValue];
        
        // lerp the index
        lightnessPercentage = lowerPercentage + ((upperPercentage-lowerPercentage) / ((CGFloat)upperIndex-(CGFloat)lowerIndex)) * (indexFloat-(CGFloat)lowerIndex);
    }
    else
    {
        lightnessPercentage = lowerPercentage;
    }
    
    
    // lighter shade
    if (shade < 500)
    {
        return baseLightness + ((1.0-baseLightness)*lightnessPercentage);
    }
    // darker shade
    else if (shade > 500)
    {
        return baseLightness + (baseLightness*lightnessPercentage);
    }
    else
    {
        return baseLightness;
    }
}




@implementation UIColor (SGN_ColorPalette)

- (UIColor*) sgn_colorForShade:(SGN_ColorPaletteShade)shade
{
    if (shade == 500)
        return self;
    
    CGFloat baseHue, baseLightness, baseSaturation, baseAlpha;
    [self getHue:&baseHue saturation:&baseSaturation brightness:&baseLightness alpha:&baseAlpha];
    
    // generate new saturation
    CGFloat hue = sgn_getModifiedHueForShade(baseHue, shade);
    CGFloat sat = sgn_getModifiedSaturationForShade(baseSaturation, shade);
    CGFloat light = sgn_getModifiedLightnessForShade(baseLightness, shade);
    
    UIColor* modifiedColor = [UIColor colorWithHue:hue saturation:sat brightness:light alpha:baseAlpha];
    return modifiedColor;
}



// depending on the brightness of the color, either black or white text with varying alpha values
- (UIColor*) sgn_primaryTextColor
{
    // (0, 0, 0, 0.87) or (1, 1, 1, 1)
    return [self sgn_isLightColor] ? [UIColor colorWithWhite:0 alpha:0.87] : [UIColor colorWithWhite:1 alpha:1.0];
}
- (UIColor*) sgn_secondaryTextColor
{
    // (0, 0, 0, 0.54) or (1, 1, 1, 0.7)
    return [self sgn_isLightColor] ? [UIColor colorWithWhite:0 alpha:0.54] : [UIColor colorWithWhite:1 alpha:0.7];
}
- (UIColor*) sgn_disabledTextColor
{
    // (0, 0, 0, 0.38) or (1, 1, 1, 0.3)
    return [self sgn_isLightColor] ? [UIColor colorWithWhite:0 alpha:0.38] : [UIColor colorWithWhite:1 alpha:0.3];
}



- (BOOL) sgn_isLightColor
{
    return self.sgn_luminance > 0.64;
}


- (CGFloat) sgn_luminance
{
    CGFloat r,g,b;
    if (![self getRed:&r green:&g blue:&b alpha:nil])
        return 0.0f;
    
    // http://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
    // http://en.wikipedia.org/wiki/Luma_(video)
    // Y = 0.2126 R + 0.7152 G + 0.0722 B
    
    return r*0.2126f + g*0.7152f + b*0.0722f;
}


- (BOOL) sgn_isEqualToColor:(UIColor *)otherColor
{
#if CGFLOAT_IS_DOUBLE
    CGFloat tolerance = DBL_EPSILON;
#else
    CGFloat tolerance = FLT_EPSILON;
#endif
    return [self sgn_isEqualToColor:otherColor withTolerance:tolerance];
}

- (BOOL) sgn_isEqualToColor:(UIColor *)otherColor withTolerance:(CGFloat)tolerance
{
    if (self == otherColor)
        return YES;
    
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    [self getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [otherColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    return fabs(r1 - r2) <= tolerance &&
    fabs(g1 - g2) <= tolerance &&
    fabs(b1 - b2) <= tolerance &&
    fabs(a1 - a2) <= tolerance;
}



@end
