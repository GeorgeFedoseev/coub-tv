//
//  NSString+MD5.m
//  CoubTV
//
//  Created by George on 2/6/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString(MD5)

- (NSString*)MD5

{
    
    // Creating the pointer to the string as UTF8String
    
    const char *ptr = [self UTF8String];
    
    // Creating byte array of unsigned characters
    
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Creating 16 byte MD5 hash value and storing it in buffer
    
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Converting MD5 value from the buffer to NSString of hex values
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    //Returning the string hex values
    
    return output;
    
}

@end