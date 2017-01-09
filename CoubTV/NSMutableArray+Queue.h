//
//  NSMutableArray+Queue.h
//  CoubTV
//
//  Created by George on 2/6/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Queue)
- (id) dequeue;
- (void) enqueue:(id)obj;
@end
