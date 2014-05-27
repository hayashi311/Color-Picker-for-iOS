//
//  HRBenchmarksViewController.m
//  Hayashi311ColorPickerSample
//
//  Created by hayashi311 on 5/26/14.
//  Copyright (c) 2014 Hayashi Ryota. All rights reserved.
//

#import "HRBenchmarksViewController.h"

@interface HRBenchmarksViewController ()

@end

@implementation HRBenchmarksViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    uint64_t n = dispatch_benchmark(10000,^{
//        NSMutableArray* array = [NSMutableArray array];
//        [array addObject:@"hoge"];
//    });
//    NSLog(@"n = %llu [ns]",n);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
