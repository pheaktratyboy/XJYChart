//
//  XLineContainerView.m
//  RecordLife
//
//  Created by 谢俊逸 on 17/03/2017.
//  Copyright © 2017 谢俊逸. All rights reserved.
//
// MAC OS  和 iOS 的坐标系问题

#import "XLineContainerView.h"
#import "XAuxiliaryCalculationHelper.h"
#import "XColor.h"
#import "XAnimationLabel.h"
#import "XAnimation.h"
#import "XPointDetect.h"
#import "CALayer+XLayerSelectHelper.h"
#import "CAShapeLayer+XLayerHelper.h"
#pragma mark - Macro

#define LineWidth 3.0
#define PointDiameter 7.0

// Control Touch Area
CGFloat touchLineWidth = 20;

@interface XLineContainerView ()
@property(nonatomic, strong) CABasicAnimation* pathAnimation;

@property(nonatomic, strong) CAShapeLayer* coverLayer;
/**
 All lines points
 */
@property(nonatomic, strong)
    NSMutableArray<NSMutableArray<NSValue*>*>* pointsArrays;
@property(nonatomic, strong) NSMutableArray<CAShapeLayer*>* shapeLayerArray;
@property(nonatomic, strong) NSMutableArray<XAnimationLabel*>* labelArray;
@property(nonatomic, strong) NSMutableArray<CAShapeLayer*>* pointLayerArray;

@end

@implementation XLineContainerView

- (instancetype)initWithFrame:(CGRect)frame
                dataItemArray:(NSMutableArray<XLineChartItem*>*)dataItemArray
                    topNumber:(NSNumber*)topNumber
                 bottomNumber:(NSNumber*)bottomNumber
                configuration:(XNormalLineChartConfiguration*)configuration {
  if (self = [super initWithFrame:frame]) {
    self.configuration = configuration;
    self.backgroundColor = self.configuration.chartBackgroundColor;

    self.coverLayer = [CAShapeLayer layer];
    self.shapeLayerArray = [NSMutableArray new];
    self.pointsArrays = [NSMutableArray new];
    self.labelArray = [NSMutableArray new];
    self.pointLayerArray = [NSMutableArray new];

    self.dataItemArray = dataItemArray;
    self.top = topNumber;
    self.bottom = bottomNumber;
    self.lineMode = BrokenLine;
    self.colorMode = Random;
  }
  return self;
}

#pragma mark - Draw

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];
  CGContextRef contextRef = UIGraphicsGetCurrentContext();
  [self cleanPreDrawLayerAndData];
  [self strokeAuxiliaryLineInContext:contextRef];
  [self strokeLineChart];
  [self strokePointInContext:contextRef];
}

/// Stroke Auxiliary
- (void)strokeAuxiliaryLineInContext:(CGContextRef)context {
  CGContextSaveGState(context);
  CGFloat lengths[2] = {5.0, 5.0};
  CGContextSetLineDash(context, 0, lengths, 2);
  CGContextSetLineWidth(context, 0.3);
  for (int i = 0; i < 11; i++) {
    CGContextMoveToPoint(
        context, 5, self.frame.size.height - (self.frame.size.height) / 11 * i);
    CGContextAddLineToPoint(
        context, self.frame.size.width,
        self.frame.size.height - ((self.frame.size.height) / 11) * i);
    CGContextStrokePath(context);
  }
  CGContextRestoreGState(context);

  CGContextSaveGState(context);
  CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
  // ordinate
  CGContextMoveToPoint(context, 5, 0);
  CGContextAddLineToPoint(context, 5, self.frame.size.height);
  CGContextStrokePath(context);

  // abscissa
  CGContextMoveToPoint(context, 5, self.frame.size.height);
  CGContextAddLineToPoint(context, self.frame.size.width,
                          self.frame.size.height);
  CGContextStrokePath(context);

  // arrow
  UIBezierPath* arrow = [[UIBezierPath alloc] init];
  arrow.lineWidth = 0.7;
  [arrow moveToPoint:CGPointMake(0, 8)];
  [arrow addLineToPoint:CGPointMake(5, 0)];
  [arrow moveToPoint:CGPointMake(5, 0)];
  [arrow addLineToPoint:CGPointMake(10, 8)];
  [[UIColor blackColor] setStroke];
  arrow.lineCapStyle = kCGLineCapRound;
  [arrow stroke];
  CGContextRestoreGState(context);
}

- (void)cleanPreDrawLayerAndData {
  [self.coverLayer removeFromSuperlayer];
  [self.shapeLayerArray
      enumerateObjectsUsingBlock:^(CAShapeLayer* _Nonnull obj, NSUInteger idx,
                                   BOOL* _Nonnull stop) {
        [obj removeFromSuperlayer];
      }];
  [self.labelArray
      enumerateObjectsUsingBlock:^(XAnimationLabel* _Nonnull obj,
                                   NSUInteger idx, BOOL* _Nonnull stop) {
        [obj removeFromSuperview];
      }];
  
  [self.pointLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    [obj removeFromSuperlayer];
  }];

  [self.pointsArrays removeAllObjects];
  [self.shapeLayerArray removeAllObjects];
  [self.labelArray removeAllObjects];
  [self.pointLayerArray removeAllObjects];
}

/// Stroke Point
- (void)strokePointInContext:(CGContextRef)context {
  self.pointsArrays = [self getPointsArrays];
  [self.pointsArrays enumerateObjectsUsingBlock:^(NSMutableArray* _Nonnull obj,
                                                  NSUInteger idx,
                                                  BOOL* _Nonnull stop) {
    UIColor* pointColor = [[XColor shareXColor] randomColorInColorArray];
    [obj enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx,
                                      BOOL* _Nonnull stop) {
      NSValue* pointValue = obj;
      CGPoint point = pointValue.CGPointValue;

      /// Change To CALayer
      CAShapeLayer* pointLayer = [CAShapeLayer pointLayerWithDiameter:PointDiameter color:pointColor center:point];
      [self.pointLayerArray addObject:pointLayer];
      [self.layer addSublayer:pointLayer];

    }];
  }];
}

/// Stroke Line
- (void)strokeLineChart {
  self.pointsArrays = [self getPointsArrays];
  [self.pointsArrays enumerateObjectsUsingBlock:^(NSMutableArray* _Nonnull obj,
                                                  NSUInteger idx,
                                                  BOOL* _Nonnull stop) {
    if (self.colorMode == Random) {
      [self.shapeLayerArray
          addObject:[self lineShapeLayerWithPoints:obj
                                            colors:[[XColor shareXColor]
                                                       randomColorInColorArray]
                                          lineMode:self.lineMode]];
    } else {
      [self.shapeLayerArray
          addObject:[self lineShapeLayerWithPoints:obj
                                            colors:self.dataItemArray[idx].color
                                          lineMode:self.lineMode]];
    }
  }];

  [self.shapeLayerArray
      enumerateObjectsUsingBlock:^(CAShapeLayer* _Nonnull obj, NSUInteger idx,
                                   BOOL* _Nonnull stop) {
        [self.layer addSublayer:obj];
      }];
}

// compute Points Arrays
- (NSMutableArray<NSMutableArray<NSValue*>*>*)getPointsArrays {
  // 避免重复计算
  if (self.pointsArrays.count > 0) {
    return self.pointsArrays;
  } else {
    NSMutableArray* pointsArrays = [NSMutableArray new];
    // Get Points
    [self.dataItemArray enumerateObjectsUsingBlock:^(
                            XLineChartItem* _Nonnull obj, NSUInteger idx,
                            BOOL* _Nonnull stop) {
      NSMutableArray* numberArray = obj.numberArray;
      NSMutableArray* linePointArray = [NSMutableArray new];
      [obj.numberArray enumerateObjectsUsingBlock:^(NSNumber* _Nonnull obj,
                                                    NSUInteger idx,
                                                    BOOL* _Nonnull stop) {
        CGPoint point = [self calculateDrawablePointWithNumber:obj
                                                           idx:idx
                                                         count:numberArray.count
                                                        bounds:self.bounds];
        NSValue* pointValue = [NSValue valueWithCGPoint:point];
        [linePointArray addObject:pointValue];
      }];
      [pointsArrays addObject:linePointArray];
    }];
    return pointsArrays;
  }
}

#pragma mark Helper
/**
 计算点通过 数值 和 idx

 @param number number
 @param idx like 0.1.2.3...
 @return CGPoint
 */
// Calculate -> Point
- (CGPoint)calculateDrawablePointWithNumber:(NSNumber*)number
                                        idx:(NSUInteger)idx
                                      count:(NSUInteger)count
                                     bounds:(CGRect)bounds {
  CGFloat percentageH = [[XAuxiliaryCalculationHelper shareCalculationHelper]
      calculateTheProportionOfHeightByTop:self.top.doubleValue
                                   bottom:self.bottom.doubleValue
                                   height:number.doubleValue];
  CGFloat percentageW = [[XAuxiliaryCalculationHelper shareCalculationHelper]
      calculateTheProportionOfWidthByIdx:(idx)
                                   count:count];
  CGFloat pointY = percentageH * bounds.size.height;
  CGFloat pointX = percentageW * bounds.size.width;
  CGPoint point = CGPointMake(pointX, pointY);
  CGPoint rightCoordinatePoint =
      [[XAuxiliaryCalculationHelper shareCalculationHelper]
          changeCoordinateSystem:point
                  withViewHeight:self.frame.size.height];
  return rightCoordinatePoint;
}

- (CAShapeLayer*)lineShapeLayerWithPoints:
                     (NSMutableArray<NSValue*>*)pointsValueArray
                                   colors:(UIColor*)color
                                 lineMode:(XXLineMode)lineMode {
  UIBezierPath* line = [[UIBezierPath alloc] init];

  CAShapeLayer* chartLine = [CAShapeLayer layer];
  chartLine.lineCap = kCALineCapRound;
  chartLine.lineJoin = kCALineJoinRound;
  chartLine.lineWidth = LineWidth;

  for (int i = 0; i < pointsValueArray.count - 1; i++) {
    CGPoint point1 = pointsValueArray[i].CGPointValue;

    CGPoint point2 = pointsValueArray[i + 1].CGPointValue;
    [line moveToPoint:point1];

    if (lineMode == BrokenLine) {
      [line addLineToPoint:point2];
    } else if (lineMode == CurveLine) {
      CGPoint midPoint = [[XAuxiliaryCalculationHelper shareCalculationHelper]
          midPointBetweenPoint1:point1
                      andPoint2:point2];
      [line addQuadCurveToPoint:midPoint
                   controlPoint:[[XAuxiliaryCalculationHelper
                                    shareCalculationHelper]
                                    controlPointBetweenPoint1:midPoint
                                                    andPoint2:point1]];
      [line addQuadCurveToPoint:point2
                   controlPoint:[[XAuxiliaryCalculationHelper
                                    shareCalculationHelper]
                                    controlPointBetweenPoint1:midPoint
                                                    andPoint2:point2]];
    } else {
      [line addLineToPoint:point2];
    }

    //当前线段的四个点
    CGPoint rectPoint1 =
        CGPointMake(point1.x - LineWidth / 2, point1.y - LineWidth / 2);
    NSValue* value1 = [NSValue valueWithCGPoint:rectPoint1];
    CGPoint rectPoint2 =
        CGPointMake(point1.x - LineWidth / 2, point1.y + LineWidth / 2);
    NSValue* value2 = [NSValue valueWithCGPoint:rectPoint2];
    CGPoint rectPoint3 =
        CGPointMake(point2.x + LineWidth / 2, point2.y - LineWidth / 2);
    NSValue* value3 = [NSValue valueWithCGPoint:rectPoint3];
    CGPoint rectPoint4 =
        CGPointMake(point2.x + LineWidth / 2, point2.y + LineWidth / 2);
    NSValue* value4 = [NSValue valueWithCGPoint:rectPoint4];

    //当前线段的矩形组成点
    NSMutableArray<NSValue*>* segementPointsArray = [NSMutableArray new];
    [segementPointsArray addObject:value1];
    [segementPointsArray addObject:value2];
    [segementPointsArray addObject:value3];
    [segementPointsArray addObject:value4];

    //把当前线段的矩形组成点数组添加到 数组中
    if (chartLine.segementPointsArrays == nil) {
      chartLine.segementPointsArrays = [[NSMutableArray alloc] init];
      [chartLine.segementPointsArrays addObject:segementPointsArray];
    } else {
      [chartLine.segementPointsArrays addObject:segementPointsArray];
    }
  }

  chartLine.path = line.CGPath;
  chartLine.strokeStart = 0.0;
  chartLine.strokeEnd = 1.0;
  chartLine.opacity = 0.6;
  chartLine.strokeColor = color.CGColor;
  chartLine.fillColor = [UIColor clearColor].CGColor;
  // selectedStatus
  chartLine.selectStatusNumber = [NSNumber numberWithBool:NO];
  [chartLine addAnimation:self.pathAnimation forKey:@"strokeEndAnimation"];

  return chartLine;
}

- (CAShapeLayer*)coverShapeLayerWithPath:(CGPathRef)path color:(UIColor*)color {
  CAShapeLayer* chartLine = [CAShapeLayer layer];
  chartLine.lineCap = kCALineCapRound;
  chartLine.lineJoin = kCALineJoinRound;
  chartLine.lineWidth = LineWidth * 1.5;
  chartLine.path = path;
  chartLine.strokeStart = 0.0;
  chartLine.strokeEnd = 1.0;
  chartLine.strokeColor = color.CGColor;
  chartLine.fillColor = [UIColor clearColor].CGColor;
  chartLine.opacity = 0.8;

  // Remove ANimation
  //    CASpringAnimation *springAnimation = [XAnimation
  //    getLineChartSpringAnimationWithLayer:chartLine];
  //    [chartLine addAnimation:springAnimation forKey:@"position.y"];

  return chartLine;
}

- (CABasicAnimation*)pathAnimation {
  _pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
  _pathAnimation.duration = 3.0;
  _pathAnimation.timingFunction = [CAMediaTimingFunction
      functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  _pathAnimation.fromValue = @0.0f;
  _pathAnimation.toValue = @1.0f;
  return _pathAnimation;
}

#pragma mark - Touch

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  //根据 点击的x坐标 只找在x 坐标区域内的 线段进行判断
  //坐标系转换
  CGPoint __block point = [[touches anyObject] locationInView:self];

  //找到小的区域
  int areaIdx = 0;
  NSArray<NSValue*>* points = self.pointsArrays.lastObject;
  for (int i = 0; i < points.count - 1; i++) {
    if (point.x >= points[i].CGPointValue.x &&
        point.x <= points[i + 1].CGPointValue.x) {
      areaIdx = i;
    }
  }

  __block BOOL isContain = false;
  for (int i = 0; i < 5; i++) {
    //遍历每一条线时，只判断在 areaIdx 的 线段 是否包含 该点
    [self.shapeLayerArray enumerateObjectsUsingBlock:^(
                              CAShapeLayer* _Nonnull obj, NSUInteger idx,
                              BOOL* _Nonnull stop) {

      NSMutableArray<NSMutableArray<NSValue*>*>* segementPointsArrays =
          obj.segementPointsArrays;

      //找到这一段上的点s
      NSMutableArray<NSValue*>* points = segementPointsArrays[areaIdx];

      /// Mutiline optimize
      /// 找到最扩展最近的点
      isContain = [XPointDetect
           point:point
          inArea:[XPointDetect expandRectArea:points expandLength:20 * i]];

      if (isContain == YES) {
        NSUInteger shapeLayerIndex = idx;
        // 点击的是高亮的Line
        if (self.coverLayer.selectStatusNumber.boolValue == YES) {
          // remove pre layer and label
          [self.coverLayer removeFromSuperlayer];
          [self.labelArray enumerateObjectsUsingBlock:^(
                               XAnimationLabel* _Nonnull obj, NSUInteger idx,
                               BOOL* _Nonnull stop) {
            [obj removeFromSuperview];
          }];
          [self.labelArray removeAllObjects];
          self.coverLayer.selectStatusNumber = [NSNumber numberWithBool:NO];
        }
        // 点击的是非高亮的Line
        else {
          // remove pre layer and label
          [self.labelArray enumerateObjectsUsingBlock:^(
                               XAnimationLabel* _Nonnull obj, NSUInteger idx,
                               BOOL* _Nonnull stop) {
            [obj removeFromSuperview];
          }];
          [self.labelArray removeAllObjects];
          [self.coverLayer removeFromSuperlayer];

          self.coverLayer = [self
              coverShapeLayerWithPath:self.shapeLayerArray[shapeLayerIndex].path
                                color:[UIColor tomatoColor]];
          self.coverLayer.selectStatusNumber = [NSNumber numberWithBool:YES];
          [self.layer addSublayer:self.coverLayer];

          [self.pointsArrays[shapeLayerIndex]
              enumerateObjectsUsingBlock:^(
                  NSValue* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
                CGPoint point = obj.CGPointValue;
                XAnimationLabel* label =
                    [XAnimationLabel topLabelWithPoint:point
                                                  text:@"0"
                                             textColor:XJYBlack
                                             fillColor:[UIColor clearColor]];
                CGFloat textNum = self.dataItemArray[shapeLayerIndex]
                                      .numberArray[idx]
                                      .doubleValue;
                [self.labelArray addObject:label];
                [self addSubview:label];
                [label countFromCurrentTo:textNum duration:0.5];
              }];
        }
        *stop = YES;
      }

      if (isContain) {
        *stop = YES;
      }
    }];
    if (isContain) {
      return;
    }
  }
}

- (XNormalLineChartConfiguration *)configuration {
  if (_configuration == nil) {
    _configuration = [[XNormalLineChartConfiguration alloc] init];
  }
  return _configuration;
}

@end
