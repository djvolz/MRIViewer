//
//  DataCache.h
//  Fast SPoT
//
//  Created by Danny Volz on 10/17/13.
//  Copyright (c) 2013 Rice University. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define CACHE_SIZE 2048576 // Made shorter so it's easier to test.
//#define CACHE_SIZE 10485760 // 10Mb
#define CACHE_SIZE 5242880 


@interface DataCache : NSObject

/* Spinner Handler. */
/* Add a task. */
+ (void)enable;
/* Subtract a task. */
+ (void)disable;
/********************/

+ (void)setSelectedPlane:(NSString *) plane;
+ (NSURL *)dataFromURL:(NSURL *)url;
+ (void)dataToCache:(NSData *)data forURL:(NSURL *)url;
+ (void)clearCache;

@end