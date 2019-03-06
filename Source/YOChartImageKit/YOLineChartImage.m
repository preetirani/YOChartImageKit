#import "YOLineChartImage.h"

@implementation YOLineChartImage

- (instancetype)init {
    self = [super init];
    if (self) {
        _strokeWidth = 1.0;
        _strokeColor = [UIColor whiteColor];
        _smooth = YES;
    }
    return self;
}

- (NSNumber *) maxValue {
    return _maxValue ? _maxValue : [NSNumber numberWithFloat:[[_values valueForKeyPath:@"@max.floatValue"] floatValue]];
}

- (UIImage *)drawImage:(CGRect)frame scale:(CGFloat)scale {
    NSAssert(_values.count > 0, @"YOLineChartImage // must assign values property which is an array of NSNumber");
    
    NSUInteger valuesCount = _values.count;
    CGFloat pointX = frame.size.width / (valuesCount - 1);
    NSMutableArray<NSValue *> *points = [NSMutableArray array];
    CGFloat maxValue = self.maxValue.floatValue;

    [_values enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *_) {
        CGFloat ratioY = number.floatValue / maxValue;
        CGFloat offsetY = ratioY == 0.0 ? -self.strokeWidth / 2 : self.strokeWidth / 2;
        NSValue *pointValue = [NSValue valueWithCGPoint:(CGPoint){
            (float)idx * pointX,
            frame.size.height * (1 - ratioY) + offsetY
        }];
        [points addObject:pointValue];
    }];

    UIGraphicsBeginImageContextWithOptions(frame.size, false, scale);

    UIBezierPath *linePath = [self linePathWithPoints :points frame:frame];
    linePath.lineWidth = self.strokeWidth;
    
    if (_strokeColor) {
        [_strokeColor setStroke];
        [linePath stroke];
    }
    
    if (_gradientFill) {
        UIBezierPath *gradientPath = [self filledCurvedPathWithPoints :points frame:frame];
        [self fillGradientInPath:gradientPath frame:frame];
    } else if (_fillColor) {
        UIBezierPath *filledPath = [self filledCurvedPathWithPoints :points frame:frame];
        [self fillSolidColorInPath:filledPath];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Path generator
- (UIBezierPath *)linePathWithPoints:(NSArray *)points frame:(CGRect)frame {
    UIBezierPath *linePath = [[UIBezierPath alloc] init];
    
    __block CGPoint p1 = [points[0] CGPointValue];
    [linePath moveToPoint:p1];
    
    if (points.count == 2) {
        CGPoint p2 = [points[1] CGPointValue];
        [linePath addLineToPoint:p2];
    } else {
        [points enumerateObjectsUsingBlock:^(NSValue *value, NSUInteger idx, BOOL *_) {
            CGPoint p2 = value.CGPointValue;
            
            if (self.smooth) {
                CGFloat deltaX = p2.x - p1.x;
                CGFloat controlPointX = p1.x + (deltaX / 2);
                CGPoint controlPoint1 = (CGPoint){controlPointX, p1.y};
                CGPoint controlPoint2 = (CGPoint){controlPointX, p2.y};
                
                [linePath addCurveToPoint:p2 controlPoint1:controlPoint1 controlPoint2:controlPoint2];
            } else {
                [linePath addLineToPoint:p2];
            }
            
            p1 = p2;
        }];
    }
    return linePath;
}

- (UIBezierPath *)filledCurvedPathWithPoints:(NSArray *)points frame:(CGRect)frame {
    UIBezierPath *filledPath = [[UIBezierPath alloc] init];
    
    CGPoint startPoint = (CGPoint){0, frame.size.height};
    CGPoint endPoint = (CGPoint){frame.size.width, frame.size.height};
    
    [filledPath moveToPoint:endPoint];
    [filledPath addLineToPoint:startPoint];
    
    __block CGPoint p1 = [points[0] CGPointValue];
    [filledPath addLineToPoint:p1];
    
    if (points.count == 2) {
        CGPoint p2 = [points[1] CGPointValue];
        [filledPath addLineToPoint:p2];
    } else {
        [points enumerateObjectsUsingBlock:^(NSValue *value, NSUInteger idx, BOOL *_) {
            CGPoint p2 = value.CGPointValue;
            
            if (self.smooth) {
                CGFloat deltaX = p2.x - p1.x;
                CGFloat controlPointX = p1.x + (deltaX / 2);
                CGPoint controlPoint1 = (CGPoint){controlPointX, p1.y};
                CGPoint controlPoint2 = (CGPoint){controlPointX, p2.y};
                
                [filledPath addCurveToPoint:p2 controlPoint1:controlPoint1 controlPoint2:controlPoint2];
            } else {
                [filledPath addLineToPoint:p2];
            }
            
            p1 = p2;
        }];
    }
    
    return filledPath;
}

-   (void)fillGradientInPath:(UIBezierPath *)path frame:(CGRect)frame {
    NSArray<UIColor *>* colorsArray = _gradientColors;
    CGFloat colors [] = {
        1.0, 1.0, 1.0, 1.0,
        0.0, 0.0, 0.0, 1.0
    };
    CGFloat locations [] = { 0.0, 1.0 };
    
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, locations, 2);
    CGColorSpaceRelease(baseSpace);
    baseSpace = NULL;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextAddPath(context, path.CGPath);
    CGContextClip(context);
    
    CGPoint gradientStartPoint = (CGPoint){0, frame.size.height};
    CGPoint gradientEndPoint = (CGPoint){0, 0};
    CGContextDrawLinearGradient(context, gradient, gradientEndPoint, gradientStartPoint, 0);
    CGGradientRelease(gradient);
    gradient = NULL;
}

-   (void)fillSolidColorInPath:(UIBezierPath *)path {
    if (_fillColor) {
        [_fillColor setFill];
        [path fill];
    }
}


@end
