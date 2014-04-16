//
//  ViewController.h
//  MRIViewer
//
//  Created by DJ Volz on 2/22/14.
//  Copyright (c) 2014 Rice University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataCache.h"

static NSString *SERVER = @"http://skinny-pete.local/~Danny/Dropbox/riceMRI/development/c_projects/demo/slices/";

@interface ViewController : UIViewController

@property (nonatomic, strong) NSURL *imageURL;

@property (nonatomic, strong) NSString *viewPlane;
@property (nonatomic, strong) NSString *serverFolder;



/* Spinner Handler. */
/* Add a task. */
-(void)enable;
/* Subtract a task. */
-(void)disable;
/********************/

@end
