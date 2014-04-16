//
//  DataCache.m
//  Fast SPoT
//
//  Created by Danny Volz on 10/17/13.
//  Copyright (c) 2013 Rice University. All rights reserved.
//

#import "DataCache.h"


@interface DataCache()

@property (nonatomic, strong)NSURL *dataURL;
@property (nonatomic, strong)NSFileManager *manager;

@end

@implementation DataCache

static NSString *selectedPlane = @"xy";

/********************* Spinner Handler. *********************/
+ (void)enable
{
    /* Add a task. */
    [self networkBusyStatus:1];
}

+ (void)disable
{
    /* Subtract a task. */
    [self networkBusyStatus:-1];
}

+ (void)networkBusyStatus:(NSUInteger)task
{
    /* Count the number of activities. */
    static NSUInteger statusCounter = 0;
    
    static dispatch_queue_t q;
    if (!q) { q = dispatch_queue_create("Network Activity Spinner", NULL); }
    dispatch_sync(q, ^{
        /* If no more tasks, disable spinner. */
        if (statusCounter + task <= 0) {
            /* Turn off spinner. */
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            /* Reset statusCounter. */
            statusCounter = 0;
            
            /* If there are still tasks accessing the network, continue spinning. */
        } else {
            /* Enable spinner. */
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            statusCounter += task;
        }
    });
}
/************************************************************/

+ (void)setSelectedPlane:(NSString *)plane
{
    selectedPlane = plane;
}


- (NSFileManager *)manager
{
    if (!_manager) { _manager = [[NSFileManager alloc] init]; }
    return _manager;
}

- (NSURL *)dataURL
{
    
    if (!_dataURL) {
        _dataURL = [[[self.manager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:selectedPlane isDirectory:YES];
        
    
        if (![self.manager fileExistsAtPath:[_dataURL path] isDirectory:NO]) {
            [self.manager createDirectoryAtURL:_dataURL withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return _dataURL;
}

+ (NSURL *)dataFromURL:(NSURL *)url
{
    if (!url) {
        return nil;
    }
    
    DataCache *dataCache = [[DataCache alloc] init];
    NSURL *cachedUrl = [dataCache.dataURL URLByAppendingPathComponent:[[url path] lastPathComponent]];
    
    
    
    /* Check if file exists. */
    if ([dataCache.manager fileExistsAtPath:[cachedUrl path]]) {
        return cachedUrl;
    }
    return nil;
}

+ (void)dataToCache:(NSData *)data forURL:(NSURL *)url
{
    if (!data) {
        return;
    }
    
    
    
    DataCache *dataCache = [[DataCache alloc] init];
    NSURL *cacheURL = [dataCache.dataURL URLByAppendingPathComponent:[[url path] lastPathComponent]];
    
    /* If file exists in cache, then change its date. */
//    if ([dataCache.manager fileExistsAtPath:[cacheURL path]]) {
//        [dataCache.manager setAttributes:@{NSFileModificationDate:[NSDate date]} ofItemAtPath:[cacheURL path] error:nil];
//    
//    /* File doesn't exist at path so create a file at that path. */
//    } else {
    
        [dataCache.manager createFileAtPath:[cacheURL path] contents:data attributes:nil];
        
        
        /* Check if cache is full.  If it is, trim it down. */
        __block NSInteger directory = 0; //__block used to enable number to be used outside of block.
        NSDate *date;
        NSNumber *size;
        NSMutableArray *files = [NSMutableArray array];
        
        NSDirectoryEnumerator *directoryEnumerator = [dataCache.manager enumeratorAtURL:dataCache.dataURL includingPropertiesForKeys:@[NSURLAttributeModificationDateKey] options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
        
        
        for (NSURL *test in directoryEnumerator) {
            [test getResourceValue:&date forKey:NSURLAttributeModificationDateKey error:nil];
            [test getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
            directory += [size integerValue];
            [files addObject:@{@"date":date, @"size":size, @"url":test}];
        }
        
        /* When directory size is greater than cache size, remove some files from cache to make room. */
        if (directory > CACHE_SIZE) {
            /* Create an array sorted by date. */
            NSArray *sortedArray = [files sortedArrayUsingComparator:
                                    ^NSComparisonResult(id item1, id item2) {
                                        return [item1[@"date"] compare:item2[@"date"]];
                                    }];
            
            [sortedArray enumerateObjectsUsingBlock:
             ^(id obj, NSUInteger index, BOOL *end) {
                 NSError *error;
                 
                 /* Remove the object size from the directory size. */
                 directory -= [obj[@"size"] integerValue];
                 /* Remove the object. */
                 [dataCache.manager removeItemAtURL:obj[@"url"] error:&error];
                 
                 /* End when the directory size is smaller than the cache size or an error is thrown. */
                 *end = (directory < CACHE_SIZE) || error;
             }];
//        }

    }
}

+ (void)clearCache
{
    DataCache *dataCache = [[DataCache alloc] init];
    
    /* Check if cache is full.  If it is, trim it down. */
    __block NSInteger directory = 0; //__block used to enable number to be used outside of block.
    NSDate *date;
    NSNumber *size;
    NSMutableArray *files = [NSMutableArray array];
    
    NSDirectoryEnumerator *directoryEnumerator = [dataCache.manager enumeratorAtURL:dataCache.dataURL includingPropertiesForKeys:@[NSURLAttributeModificationDateKey] options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
    
    
    for (NSURL *url in directoryEnumerator) {
        [url getResourceValue:&date forKey:NSURLAttributeModificationDateKey error:nil];
        [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
        directory += [size integerValue];
        [files addObject:@{@"date":date, @"size":size, @"url":url}];
    }
    
    /* When directory size is greater than cache size, remove some files from cache to make room. */
    
    /* Create an array sorted by date. */
    NSArray *sortedArray = [files sortedArrayUsingComparator:
                            ^NSComparisonResult(id item1, id item2) {
                                return [item1[@"date"] compare:item2[@"date"]];
                            }];
    
    [sortedArray enumerateObjectsUsingBlock:
     ^(id obj, NSUInteger index, BOOL *end) {
         NSError *error;
         
         /* Remove the object size from the directory size. */
         directory -= [obj[@"size"] integerValue];
         /* Remove the object. */
         [dataCache.manager removeItemAtURL:obj[@"url"] error:&error];
         
         /* End when the directory size is smaller than the cache size or an error is thrown. */
         *end = (directory <= 0) || error;
     }];
    
     NSLog(@"Leaving clearCache!");
   
        
}

@end