//
//  FDMacros.h
//  HUANGBO
//
//  Created by HUANGBO on 15/3/31.
//  Copyright (c) 2015年 YY.COM All rights reserved.
//

#ifndef pengmi_FDMacros_h
#define pengmi_FDMacros_h

//NSCachesDirectory
//NSDocumentDirectory
#define AUDIORECORDFILEPATH(FILENAME) [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"AudioRecord/%@", FILENAME]]


#define AUDIODOWNLOADFILEPATH(FILENAME) [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"download/%@", FILENAME]]


#ifndef	weakify
#if __has_feature(objc_arc)
#define weakify( x )	autoreleasepool{} __weak __typeof__(x) __weak_##x##__ = x;
#else	// #if __has_feature(objc_arc)
#define weakify( x )	autoreleasepool{} __block __typeof__(x) __block_##x##__ = x;
#endif	// #if __has_feature(objc_arc)
#endif	// #ifndef	weakify

#ifndef	strongify
#if __has_feature(objc_arc)
#define strongify( x )	try{} @finally{} __typeof__(x) x = __weak_##x##__;
#else	// #if __has_feature(objc_arc)
#define strongify( x )	try{} @finally{} __typeof__(x) x = __block_##x##__;
#endif	// #if __has_feature(objc_arc)
#endif	// #ifndef	@normalize


#define KT_HEXCOLOR(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1]

/**
 * 最大录音时长
 */
#define RECORDER_DURATION 300        //默认录音最大时长


#endif
