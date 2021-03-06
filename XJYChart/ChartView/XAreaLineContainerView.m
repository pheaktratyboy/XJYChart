//
//  XAreaLineContainerView.m
//  RecordLife
//
//  Created by 谢俊逸 on 09/05/2017.
//  Copyright © 2017 谢俊逸. All rights reserved.
//

#import "XAreaLineContainerView.h"
#import "XAuxiliaryCalculationHelper.h"
#import "XColor.h"
#import "XAnimationLabel.h"
#import "XAnimation.h"
#import "XAnimator.h"
#import "CAShapeLayer+XLayerHelper.h"

#pragma mark - Macro

#define LineWidth 6.0
#define PointDiameter 11.0

// Animation start ratio
#define StartRatio 0.3

#define mark -XGraphAnimationNode

/**
 Contain Point in CADisplayLink Animation Information.

 CurrentPoint: Use it to draw.
 EndPoint: Save final view point.
 */
@interface XGraphAnimationNode : NSObject

@property(nonatomic, assign) CGPoint graphAnimationEndPoint;
@property(nonatomic, assign) CGPoint graphAnimationCurrentPoint;

- (instancetype)initWithAnimationEndPoint:(CGPoint)endPoint;
- (CGFloat)getAnimationNodeX;
- (CGFloat)getAnimationNodeEndY;
- (CGFloat)getAnimationNodeCurrentY;

@end

@implementation XGraphAnimationNode

- (instancetype)initWithAnimationEndPoint:(CGPoint)endPoint {
  if (self = [super init]) {
    self.graphAnimationEndPoint = endPoint;
    self.graphAnimationCurrentPoint = endPoint;
  }
  return self;
}

- (CGFloat)getAnimationNodeX {
  return self.graphAnimationEndPoint.x;
}

- (CGFloat)getAnimationNodeEndY {
  return self.graphAnimationEndPoint.y;
}

- (CGFloat)getAnimationNodeCurrentY {
  return self.graphAnimationCurrentPoint.y;
}

@end

/**
 Manager points.
 Draw layer use.
 */

@interface XAreaAnimationManager : NSObject

/// area nodes. Used to draw up the closed graph
@property(nonatomic, strong) NSMutableArray<XGraphAnimationNode*>* areaNodes;
/// animation needs nodes
@property(nonatomic, strong)
    NSMutableArray<XGraphAnimationNode*>* animationNodes;

@end

@implementation XAreaAnimationManager
- (instancetype)init {
  if (self = [super init]) {
  }
  return self;
}

- (instancetype)initWithAreaNodes:(NSMutableArray<XGraphAnimationNode*>*)nodes {
  if (self = [super init]) {
    self.areaNodes = nodes;
  }
  return self;
}

- (NSMutableArray<XGraphAnimationNode*>*)animationNodes {
  NSMutableArray* nodes = [self.areaNodes mutableCopy];
  [nodes removeObjectAtIndex:0];
  [nodes removeLastObject];
  return nodes;
}

@end

/**
 Animation :
 Using CADisplayLink animation.
 By Adding the CALayer In The View.
 Change Shape And Readding.

 EnterAnimaton:
 when UIApplicationDidBecomeActiveNotification add Animation.
 When UIApplicationDidEnterBackgroundNotification. Reset View Will Make
 Animation More coordination.
 */
@interface XAreaLineContainerView ()

@property(nonatomic, strong) UIColor* areaColor;

@property(nonatomic, strong) CAGradientLayer* gradientLayer;

@property(nonatomic, strong) NSMutableArray<XAnimationLabel*>* labelArray;

@property(nonatomic, strong) XAreaAnimationManager* areaAnimationManager;

@property(nonatomic, strong) NSMutableArray<CAShapeLayer*>* pointLayerArray;

@end

@implementation XAreaLineContainerView

- (instancetype)initWithFrame:(CGRect)frame
                dataItemArray:(NSMutableArray<XLineChartItem*>*)dataItemArray
                    topNumber:(NSNumber*)topNumber
                 bottomNumber:(NSNumber*)bottomNumber
                configuration:(XAreaLineChartConfiguration*)configuration {
  if (self = [super initWithFrame:frame]) {
    self.congifuration = configuration;
    self.backgroundColor = self.congifuration.chartBackgroundColor;

    self.pointLayerArray = [NSMutableArray new];
    self.labelArray = [NSMutableArray new];
    self.dataItemArray = dataItemArray;

    self.top = topNumber;
    self.bottom = bottomNumber;
    self.lineMode = BrokenLine;

    // 数据处理，集中管理
    self.areaAnimationManager = [self makeAreaAnimationManager];

#pragma mark Register Notifications

    // App Alive Animation Notification
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(becomeAlive)
               name:UIApplicationDidBecomeActiveNotification
             object:nil];

    // App Resign Set Animation Start State
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(enterBackground)
               name:UIApplicationDidEnterBackgroundNotification
             object:nil];
  }
  return self;
}

/// 数据 ---> AreaManager
- (XAreaAnimationManager*)makeAreaAnimationManager {
  NSMutableArray<XGraphAnimationNode*>* areaNodes =
      [self getAreaDrawableAnimationNodes];
  XAreaAnimationManager* manager =
      [[XAreaAnimationManager alloc] initWithAreaNodes:[areaNodes mutableCopy]];
  return manager;
}

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];
  CGContextRef context = UIGraphicsGetCurrentContext();

  [self strokeAuxiliaryLineInContext:context];
  [self startAnimation];
}

// Start Animation
- (void)startAnimation {
  XAnimator* animator = [[XAnimator alloc] init];
  [animator
      AnimatorDuration:2
        timingFuncType:XQuarticEaseInOut
        animationBlock:^(CGFloat percentage) {
          [self.areaAnimationManager
                  .areaNodes enumerateObjectsUsingBlock:^(
                                 XGraphAnimationNode* _Nonnull node,
                                 NSUInteger idx, BOOL* _Nonnull stop) {
            node.graphAnimationCurrentPoint = CGPointMake(
                node.getAnimationNodeX,
                [[XAuxiliaryCalculationHelper shareCalculationHelper]
                    getOriginYIncreaseInFilpCoordinateSystemWithBoundsH:
                        self.bounds.size.height
                                                                targetY:
                                                                    node.getAnimationNodeEndY
                                                             percentage:
                                                                 percentage
                                                             startRatio:
                                                                 StartRatio]);
          }];
          [self refreshView];
        }];
}

- (void)refreshView {
  // remove pre data and layer
  [self cleanPreDrawAndDataCache];
  // Add SubLayers
  [self strokeLine];
  [self strokePointInContext];
}

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  [self startAnimation];
}

/// Stroke Auxiliary
- (void)strokeAuxiliaryLineInContext:(CGContextRef)context {
  CGContextSetStrokeColorWithColor(
      context, [UIColor colorWithWhite:1 alpha:0.5].CGColor);
  CGFloat lengths[2] = {5, 5};
  CGContextSetLineDash(context, 0, lengths, 2);

  NSInteger count = self.areaAnimationManager.animationNodes.count;
  for (int i = 0; i < count; i++) {
    CGContextMoveToPoint(
        context,
        [self.areaAnimationManager.animationNodes[i] getAnimationNodeX], 0);
    CGContextAddLineToPoint(
        context,
        [self.areaAnimationManager.animationNodes[i] getAnimationNodeX],
        self.frame.size.height);
    CGContextStrokePath(context);

    CGContextMoveToPoint(
        context,
        [self.areaAnimationManager.animationNodes[i] getAnimationNodeX], 0);
    CGContextAddLineToPoint(
        context,
        [self.areaAnimationManager.animationNodes[i] getAnimationNodeX],
        self.frame.size.height);
    CGContextStrokePath(context);
  }
}

- (void)strokePointInContext {
  [self.areaAnimationManager.animationNodes
      enumerateObjectsUsingBlock:^(XGraphAnimationNode* _Nonnull node,
                                   NSUInteger idx, BOOL* _Nonnull stop) {
        CGPoint center = node.graphAnimationCurrentPoint;
        
        CAShapeLayer* pointLayer = [CAShapeLayer pointLayerWithDiameter:PointDiameter color:self.congifuration.pointColor center:center];

        [self.pointLayerArray addObject:pointLayer];
        [self.layer addSublayer:pointLayer];
      }];
}

- (void)cleanPreDrawAndDataCache {
  [self.gradientLayer removeFromSuperlayer];

  [self.pointLayerArray
      enumerateObjectsUsingBlock:^(CAShapeLayer* _Nonnull obj, NSUInteger idx,
                                   BOOL* _Nonnull stop) {
        [obj removeFromSuperlayer];
      }];
  [self.pointLayerArray removeAllObjects];

  [self.labelArray
      enumerateObjectsUsingBlock:^(XAnimationLabel* _Nonnull obj,
                                   NSUInteger idx, BOOL* _Nonnull stop) {
        [obj removeFromSuperview];
      }];

  [self.labelArray removeAllObjects];
}

/// line mask cashape layer
- (void)strokeLine {
  // animation end layer
  NSMutableArray* currentPointArray = [NSMutableArray new];
  [self.areaAnimationManager.areaNodes
      enumerateObjectsUsingBlock:^(XGraphAnimationNode* _Nonnull obj,
                                   NSUInteger idx, BOOL* _Nonnull stop) {
        [currentPointArray
            addObject:[NSValue
                          valueWithCGPoint:obj.graphAnimationCurrentPoint]];
      }];
  CGPoint leftConerPoint = CGPointMake(
      self.frame.origin.x, self.frame.origin.y + self.frame.size.height);
  CGPoint rightConerPoint =
      CGPointMake(self.frame.origin.x + self.frame.size.width,
                  self.frame.origin.y + self.frame.size.height);
  CAShapeLayer* lineLayer = [self getLineShapeLayerWithPoints:currentPointArray
                                               leftConerPoint:leftConerPoint
                                              rightConerPoint:rightConerPoint];

  self.gradientLayer = [CAGradientLayer layer];
  self.gradientLayer.colors = self.congifuration.gradientColors;
  self.gradientLayer.frame = self.frame;
  self.gradientLayer.mask = lineLayer;

  [self.layer addSublayer:self.gradientLayer];
}

#pragma mark data Handling
- (NSMutableArray<XGraphAnimationNode*>*)getAreaDrawableAnimationNodes {
  NSMutableArray<NSValue*>* drawablePoints = [self getDrawablePoints];

  // Make Close Points
  CGPoint temfirstPoint = drawablePoints[0].CGPointValue;
  CGPoint temlastPoint = drawablePoints.lastObject.CGPointValue;
  CGPoint firstPoint = CGPointMake(0, temfirstPoint.y);
  CGPoint lastPoint = CGPointMake(self.frame.size.width, temlastPoint.y);

  // AreaDrawablePoints
  NSMutableArray<XGraphAnimationNode*>* areaNodes = [NSMutableArray new];
  [drawablePoints
      enumerateObjectsUsingBlock:^(NSValue* _Nonnull pointValue, NSUInteger idx,
                                   BOOL* _Nonnull stop) {
        [areaNodes
            addObject:[[XGraphAnimationNode alloc]
                          initWithAnimationEndPoint:pointValue.CGPointValue]];
      }];
  [areaNodes insertObject:[[XGraphAnimationNode alloc]
                              initWithAnimationEndPoint:firstPoint]
                  atIndex:0];
  [areaNodes addObject:[[XGraphAnimationNode alloc]
                           initWithAnimationEndPoint:lastPoint]];

  return areaNodes;
}

- (NSMutableArray<NSValue*>*)getDrawablePoints {
  NSMutableArray* linePointArray = [NSMutableArray new];
  XLineChartItem* item = self.dataItemArray[0];

  // Get Points
  NSMutableArray* numberArray = item.numberArray;
  [item.numberArray
      enumerateObjectsUsingBlock:^(NSNumber* _Nonnull obj, NSUInteger idx,
                                   BOOL* _Nonnull stop) {
        CGPoint point = [self calculateDrawablePointWithNumber:obj
                                                           idx:idx
                                                   numberArray:numberArray
                                                        bounds:self.bounds];
        NSValue* pointValue = [NSValue valueWithCGPoint:point];
        [linePointArray addObject:pointValue];
      }];
  return linePointArray;
}

#pragma mark ShapeLayerDrawer

- (CAShapeLayer*)getLineShapeLayerWithPoints:(NSArray<NSValue*>*)points
                              leftConerPoint:(CGPoint)leftConerPoint
                             rightConerPoint:(CGPoint)rightConerPoint {
  CAShapeLayer* lineLayer = [CAShapeLayer layer];
  UIBezierPath* line = [[UIBezierPath alloc] init];

  // line
  for (int i = 0; i < points.count - 1; i++) {
    CGPoint point1 = points[i].CGPointValue;
    CGPoint point2 = points[i + 1].CGPointValue;
    if (i == 0) {
      [line moveToPoint:point1];
    }
    if (self.lineMode == CurveLine) {
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
  }
  // closePoint
  [line addLineToPoint:rightConerPoint];
  [line addLineToPoint:leftConerPoint];
  [line addLineToPoint:points[0].CGPointValue];
  lineLayer.path = line.CGPath;
  lineLayer.strokeColor = [UIColor clearColor].CGColor;
  lineLayer.fillColor = [UIColor whiteColor].CGColor;
  lineLayer.opacity = self.congifuration.lineAreaOpacity;
  lineLayer.lineWidth = 4;
  lineLayer.lineCap = kCALineCapRound;
  lineLayer.lineJoin = kCALineJoinRound;
  return lineLayer;
}

#pragma mark Observerhelper

#pragma mark Notification Action
- (void)becomeAlive {
  [self startAnimation];
}

- (void)enterBackground {
  [self.areaAnimationManager.areaNodes enumerateObjectsUsingBlock:^(
                                           XGraphAnimationNode* _Nonnull node,
                                           NSUInteger idx,
                                           BOOL* _Nonnull stop) {
    node.graphAnimationCurrentPoint = CGPointMake(
        node.getAnimationNodeX,
        [[XAuxiliaryCalculationHelper shareCalculationHelper]
            getOriginYIncreaseInFilpCoordinateSystemWithBoundsH:self.bounds.size
                                                                    .height
                                                        targetY:
                                                            node.getAnimationNodeEndY
                                                     percentage:0
                                                     startRatio:StartRatio]);
  }];
  [self refreshView];
}

#pragma mark - Control Point Compute

#pragma mark - Help Methods
// Calculate -> Point
- (CGPoint)calculateDrawablePointWithNumber:(NSNumber*)number
                                        idx:(NSUInteger)idx
                                numberArray:(NSMutableArray*)numberArray
                                     bounds:(CGRect)bounds {
  CGFloat percentageH = [[XAuxiliaryCalculationHelper shareCalculationHelper]
      calculateTheProportionOfHeightByTop:self.top.doubleValue
                                   bottom:self.bottom.doubleValue
                                   height:number.doubleValue];
  CGFloat percentageW = [[XAuxiliaryCalculationHelper shareCalculationHelper]
      calculateTheProportionOfWidthByIdx:(idx)
                                   count:numberArray.count];
  CGFloat pointY = percentageH * bounds.size.height;
  CGFloat pointX = percentageW * bounds.size.width;
  CGPoint point = CGPointMake(pointX, pointY);
  CGPoint rightCoordinatePoint =
      [[XAuxiliaryCalculationHelper shareCalculationHelper]
          changeCoordinateSystem:point
                  withViewHeight:self.frame.size.height];
  return rightCoordinatePoint;
}

#pragma mark GET
- (XAreaLineChartConfiguration*)congifuration {
  if (_congifuration == nil) {
    _congifuration = [[XAreaLineChartConfiguration alloc] init];
  }
  return _congifuration;
}


@end
