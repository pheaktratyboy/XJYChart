//
//  SingleLineChartTableViewCell.m
//  RecordLife
//
//  Created by JunyiXie on 2017/11/25.
//  Copyright © 2017年 谢俊逸. All rights reserved.
//

#import "SingleLineChartTableViewCell.h"

#import <XJYChart/XChart.h>

@implementation SingleLineChartTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        
        // XJYChart init Design for muti line
        // So @[oneitem] draw one line
 
        NSMutableArray *numberArray = [NSMutableArray new];
        for (int i = 0; i < 5; i++) {
            int num = [[XRandomNumerHelper shareRandomNumberHelper] randomNumberSmallThan:14] * [[XRandomNumerHelper shareRandomNumberHelper] randomNumberSmallThan:14];
            NSNumber *number = [NSNumber numberWithInt:num];
            [numberArray addObject:number];
        }
        XLineChartItem *item = [[XLineChartItem alloc] initWithDataNumberArray:numberArray color:[UIColor seafoamColor]];
        XLineChart *lineChart = [[XLineChart alloc] initWithFrame:CGRectMake(0, 0, 375, 200) dataItemArray:[NSMutableArray arrayWithObject:item] dataDiscribeArray:[NSMutableArray arrayWithArray:@[@"January", @"February", @"March", @"April", @"May"]] topNumber:@200 bottomNumber:@0  graphMode:MutiLineGraph];
        
        lineChart.lineMode = CurveLine;
        [self.contentView addSubview:lineChart];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

@end
