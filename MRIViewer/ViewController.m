//
//  ViewController.m
//  MRIViewer
//
//  Created by DJ Volz on 2/22/14.
//  Copyright (c) 2014 Rice University. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) NSMutableDictionary *downloadedImages;
@property (strong, nonatomic) UIImageView *imageView;

@property (strong, nonatomic) IBOutlet UISlider *imageSlider;
@property (strong, nonatomic) IBOutlet UISegmentedControl *planeSelector;
@property (strong, nonatomic) IBOutlet UISegmentedControl *locationFolderSelector;

@property (strong, nonatomic) NSMutableArray *imageData_src;
@property (strong, nonatomic) NSMutableArray *imageData_ref;
@property (strong, nonatomic) NSMutableArray *imageData_registered;
@property (strong, nonatomic) NSMutableArray *imageData_checker;

@property (strong, nonatomic) NSMutableArray *images_src;
@property (strong, nonatomic) NSMutableArray *images_ref;
@property (strong, nonatomic) NSMutableArray *images_registered;
@property (strong, nonatomic) NSMutableArray *images_checker;


@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.images_src           = [[NSMutableArray alloc] init];
    self.images_ref           = [[NSMutableArray alloc] init];
    self.images_registered    = [[NSMutableArray alloc] init];
    self.images_checker       = [[NSMutableArray alloc] init];
    
    
    self.imageData_src        = [[NSMutableArray alloc] init];
    self.imageData_ref        = [[NSMutableArray alloc] init];
    self.imageData_registered = [[NSMutableArray alloc] init];
    self.imageData_checker    = [[NSMutableArray alloc] init];
    
	[self.scrollView addSubview:self.imageView];
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 10.0;
    self.scrollView.delegate         = self;
    self.viewPlane = @"xy";
    self.serverFolder = @"src";
    self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@/%d.png", SERVER, self.serverFolder,self.viewPlane, 0]];
    NSLog(@"viewDidLoad");
    
    
    [self fillCache];
    
    [self resetImage];
}

- (void)fillCache {
    [self enable];
    for (int i = 0; i <= 43; i++) {
        self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@checker/%@/%d.png", SERVER, self.viewPlane, i]];
        [self cacheImages:@"checker"];
    }
    [self disable];
    
    [self enable];
    for (int i = 0; i <= 43; i++) {
        self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@ref/%@/%d.png", SERVER, self.viewPlane, i]];
        [self cacheImages:@"ref"];
    }
    [self disable];
    
    [self enable];
    for (int i = 0; i <= 43; i++) {
        self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@registered/%@/%d.png", SERVER, self.viewPlane, i]];
        [self cacheImages:@"registered"];
    }
    [self disable];
    
    [self enable];
    for (int i = 0; i <= 43; i++) {
        self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@src/%@/%d.png", SERVER, self.viewPlane, i]];
        [self cacheImages:@"src"];
    }
    [self disable];

}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    /* Ensure that photo fills entire screen. */
    CGFloat scaleX = self.scrollView.bounds.size.width / self.imageView.image.size.width;
    CGFloat scaleY = self.scrollView.bounds.size.height / self.imageView.image.size.height;
    self.scrollView.zoomScale = MIN(scaleX, scaleY);
}

- (IBAction)didChangePlaneSelector:(UISegmentedControl *)sender {
    
    [self clearViewControllerCache];
    
    NSString *viewPlane;
    
    switch (self.planeSelector.selectedSegmentIndex) {
        case 0:
            viewPlane = @"xy";
            break;
        case 1:
            viewPlane = @"xz";
            break;
        case 2:
            viewPlane = @"yz";
            break;
        default:
            break;
    }
    
    self.viewPlane = viewPlane;
    self.imageSlider.value = 0;
    
    [self fillCache];
    
    
    self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@/%d.png", SERVER, self.serverFolder, self.viewPlane, 0]];
    [self resetImage];
}

- (IBAction)didChangeLocationFolderSelector:(UISegmentedControl *)sender {
    
    NSString *serverFolder;
    
    switch (self.locationFolderSelector.selectedSegmentIndex) {
        case 0:
            serverFolder = @"src";
            break;
        case 1:
            serverFolder = @"ref";
            break;
        case 2:
            serverFolder = @"registered";
            break;
        case 3:
            serverFolder = @"checker";
            break;
        default:
            break;
    }
    
    self.imageSlider.value = 0;
    
    self.serverFolder = serverFolder;
    
    NSString *combined = [NSString stringWithFormat:@"%@/%@", serverFolder, self.viewPlane];
    NSLog(@"combined %@", combined);

    self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@/%d.png", SERVER, self.serverFolder,self.viewPlane, 0]];
    [self resetImage];
}

- (IBAction)didChangeImageSlider:(UISlider *)sender {
    float sliderValue = self.imageSlider.value;
    
    NSString *viewPlane;
    
    switch (self.planeSelector.selectedSegmentIndex) {
        case 0:
            viewPlane = @"xy";
            break;
        case 1:
            viewPlane = @"xz";
            break;
        case 2:
            viewPlane = @"yz";
            break;
        default:
            break;
    }
    
    if (!viewPlane)
        return;
    
    NSString *url = [NSString stringWithFormat:@"%@%@/%@/%d.png", SERVER, self.serverFolder, self.viewPlane, (int)sliderValue];
    
    self.imageURL = [NSURL URLWithString:url];
    
    [self resetImage];
}

- (IBAction)didPressClearCacheButton:(UIButton *)sender {

    self.imageSlider.value = 0;
    
    [self clearViewControllerCache];
}

- (UIImageView *)imageView
{
    if (!_imageView)    _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    return _imageView;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}


- (void)setImageURL:(NSURL *)imageURL
{
    _imageURL = imageURL;
}

-(void)cacheImages:(NSString *)serverFolder
{
    if (self.scrollView) {
        self.scrollView.contentSize = CGSizeZero;
        self.imageView.image = nil;
        
        
        NSUInteger imageIndex = 0;
        
        NSData *imageData;
        
        imageData = [[NSData alloc] initWithContentsOfURL:self.imageURL];
        
        UIImage *image;
        if ([serverFolder isEqualToString:@"src"]) {
            [self.imageData_src addObject:imageData];
            imageIndex = [self.imageData_src indexOfObject:imageData];
            image = [[UIImage alloc] initWithData:[self.imageData_src objectAtIndex:imageIndex]];
            [self.images_src addObject:image];
        } else if ([serverFolder isEqualToString:@"ref"]) {
            [self.imageData_ref addObject:imageData];
            imageIndex = [self.imageData_ref indexOfObject:imageData];
            image = [[UIImage alloc] initWithData:[self.imageData_ref objectAtIndex:imageIndex]];
            [self.images_ref addObject:image];
        } else if ([serverFolder isEqualToString:@"registered"]) {
            [self.imageData_registered addObject:imageData];
            imageIndex = [self.imageData_registered indexOfObject:imageData];
            image = [[UIImage alloc] initWithData:[self.imageData_registered objectAtIndex:imageIndex]];
            [self.images_registered addObject:image];
        } else {
            [self.imageData_checker addObject:imageData];
            imageIndex = [self.imageData_checker indexOfObject:imageData];
            image = [[UIImage alloc] initWithData:[self.imageData_checker objectAtIndex:imageIndex]];
            [self.images_checker addObject:image];
        }
    }
}

- (void)resetImage
{
    if (self.scrollView) {

        float sliderValue = self.imageSlider.value;
        UIImage *image;
        
        
        if ([self.serverFolder isEqualToString:@"src"]) {
            if ((int)sliderValue < [self.images_src count])
                image = [self.images_src objectAtIndex:(int)sliderValue];
        } else if ([self.serverFolder isEqualToString:@"ref"]) {
            if ((int)sliderValue < [self.images_ref count])
                image = [self.images_ref objectAtIndex:(int)sliderValue];
        } else if ([self.serverFolder isEqualToString:@"registered"]) {
            if ((int)sliderValue < [self.images_registered count])
                image = [self.images_registered objectAtIndex:(int)sliderValue];
        } else {
            if ((int)sliderValue < [self.images_checker count])
                image = [self.images_checker objectAtIndex:(int)sliderValue];
        }
        NSLog(@"%d",(int)sliderValue);
        
        
        
        if (image) {
            self.scrollView.zoomScale = 1.0;
            self.scrollView.contentSize = image.size;
            self.imageView.image = image;
            self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
            
            /* Ensure that photo fills entire screen. */
            CGFloat scaleX = self.scrollView.bounds.size.width / self.imageView.image.size.width;
            CGFloat scaleY = self.scrollView.bounds.size.height / self.imageView.image.size.height;
            self.scrollView.zoomScale = MIN(scaleX, scaleY);
        }

    }
}

-(void)clearViewControllerCache
{
    [self.imageData_src        removeAllObjects];
    [self.imageData_ref        removeAllObjects];
    [self.imageData_registered removeAllObjects];
    [self.imageData_checker    removeAllObjects];
    
    [self.images_src removeAllObjects];
    [self.images_ref removeAllObjects];
    [self.images_registered removeAllObjects];
    [self.images_checker removeAllObjects];
}





/********************* Spinner Handler. *********************/
-(void)enable
{
    /* Add a task. */
    [self networkBusyStatus:1];
}

-(void)disable
{
    /* Subtract a task. */
    [self networkBusyStatus:-1];
}


- (void)showProgress{
    
    [self.activitySpinner startAnimating];
    
}

-(void)networkBusyStatus:(NSUInteger)task
{
    /* Count the number of activities. */
    static NSUInteger statusCounter = 0;
    
    
    
    dispatch_queue_t q = dispatch_queue_create("Network Activity Spinner", NULL);
    dispatch_sync(q, ^{
        /* If no more tasks, disable spinner. */
        if (statusCounter + task <= 0) {
            /* Turn off spinner. */
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self.activitySpinner stopAnimating];
            
            /* Reset statusCounter. */
            statusCounter = 0;
            
            /* If there are still tasks accessing the network, continue spinning. */
        } else {
            NSLog(@"start animating");
            /* Enable spinner. */
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            
            NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(showProgress) object:nil];
            [thread start];
            
            statusCounter += task;
        }
    });
}
/************************************************************/

@end
