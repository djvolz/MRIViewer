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

@property (strong, nonatomic) NSMutableArray *imageData;
@property (strong, nonatomic) NSMutableArray *images;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.images = [[NSMutableArray alloc] init];
    self.imageData = [[NSMutableArray alloc] init];
	[self.scrollView addSubview:self.imageView];
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 10.0;
    self.scrollView.delegate         = self;
    self.viewPlane = @"xy";
    self.serverFolder = @"src";
    self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@/%d.png", SERVER, self.serverFolder,self.viewPlane, 0]];
    NSLog(@"viewDidLoad");
    
    
    
    [self enable];
    for (int i = 0; i <= 43; i++) {
        self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@src/xy/%d.png", SERVER, i]];
        [self cacheImages];
    }
    [self disable];
    
    [self resetImage];
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
    
    NSString *combined = [NSString stringWithFormat:@"%@/%@", self.serverFolder, viewPlane];
    NSLog(@"combined %@", combined);
//    [DataCache setSelectedPlane:combined];
    

//    dispatch_queue_t q = dispatch_queue_create("Cache Clearer", NULL);
//    dispatch_async(q, ^{
    [self enable];
        for (int i = 0; i <= 43; i++) {
            self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@/%d.png", SERVER, self.serverFolder, self.viewPlane, i]];
            [self cacheImages];
        }
    [self disable];
//    });
    
    
    self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@/%d.png", SERVER, self.serverFolder, self.viewPlane, 0]];
    [self resetImage];
}

- (IBAction)didChangeLocationFolderSelector:(UISegmentedControl *)sender {
    
    [self clearViewControllerCache];
    
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
//    [DataCache setSelectedPlane:combined];
    
    
//    dispatch_queue_t q = dispatch_queue_create("Cache Clearer", NULL);
//    dispatch_async(q, ^{
    [self enable];
        for (int i = 0; i <= 43; i++) {
            self.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@/%d.png", SERVER, self.serverFolder,self.viewPlane, i]];
            [self cacheImages];
        }
    [self disable];
//    });

    
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
    
//    NSLog(url);
    self.imageURL = [NSURL URLWithString:url];
    
//    NSLog(@"imageSlider");
    [self resetImage];
}

- (IBAction)didPressClearCacheButton:(UIButton *)sender {
//    dispatch_queue_t q = dispatch_queue_create("Cache Clearer", NULL);
//    dispatch_async(q, ^{
        self.imageSlider.value = 0;
    
        [self clearViewControllerCache];
//        [DataCache clearCache];
//    });
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

//- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
//{
//    if ( UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
//
//    }
//}

- (void)setImageURL:(NSURL *)imageURL
{
//    NSLog(@"setImageURL");
    _imageURL = imageURL;
//    [self resetImage];
}

-(void)cacheImages{
//    NSLog(@"%@", self.imageURL);
    if (self.scrollView) {
        self.scrollView.contentSize = CGSizeZero;
        self.imageView.image = nil;
        
        
        NSUInteger imageIndex = 0;
//        NSURL *imageURL = self.imageURL;
//        dispatch_queue_t q = dispatch_queue_create("Photo Fetcher", NULL);
//        dispatch_async(q, ^{

//            NSURL *cache = [DataCache dataFromURL:imageURL];
            NSData *imageData;
//            if (cache) {
//                imageData = [[NSData alloc]initWithContentsOfURL:cache];
//                [self.imageData addObject:imageData];
//            } else {
//                [DataCache enable];
                imageData = [[NSData alloc] initWithContentsOfURL:self.imageURL];
                [self.imageData addObject:imageData];
//                [DataCache disable];
//            }
//            [DataCache dataToCache:imageData forURL:self.imageURL];
            
//            if (imageURL == self.imageURL) {
            
                    
                imageIndex = [self.imageData indexOfObject:imageData];
                UIImage *image = [[UIImage alloc] initWithData:[self.imageData objectAtIndex:imageIndex]];
                
//                if (image) {
            [self.images addObject:image];
//            [self resetImage];
//                        self.scrollView.zoomScale = 1.0;
//                        self.scrollView.contentSize = image.size;
//                        self.imageView.image = image;
//                        self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
//                        
//                        /* Ensure that photo fills entire screen. */
//                        CGFloat scaleX = self.scrollView.bounds.size.width / self.imageView.image.size.width;
//                        CGFloat scaleY = self.scrollView.bounds.size.height / self.imageView.image.size.height;
//                        self.scrollView.zoomScale = MIN(scaleX, scaleY);
//                }
//            }
//        });
    }
}

- (void)resetImage
{
    if (self.scrollView) {
//        self.scrollView.contentSize = CGSizeZero;
//        self.imageView.image = nil;
        
//        NSURL *imageURL = self.imageURL;
//        dispatch_queue_t q = dispatch_queue_create("Photo Fetcher", NULL);
//        dispatch_async(q, ^{
//            
//            NSURL *cache = [DataCache dataFromURL:imageURL];
//            NSData *imageData;
//            if (cache) {
//                imageData = [[NSData alloc]initWithContentsOfURL:cache];
//            } else {
//                [DataCache enable];
//                imageData = [[NSData alloc] initWithContentsOfURL:self.imageURL];
//                [DataCache disable];
//            }
//            [DataCache dataToCache:imageData forURL:self.imageURL];
        
//            if (imageURL == self.imageURL) {
//                dispatch_async(dispatch_get_main_queue(), ^{
        float sliderValue = self.imageSlider.value;
        UIImage *image;
        if ((int)sliderValue < [self.images count]) {
            image = [self.images objectAtIndex:(int)sliderValue];
            NSLog(@"%d",(int)sliderValue);

        }
        
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
//                });
//            }
//        });
    }
}

-(void)clearViewControllerCache
{
    [self.imageData removeAllObjects];
    [self.images removeAllObjects];
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
