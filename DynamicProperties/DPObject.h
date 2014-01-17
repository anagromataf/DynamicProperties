//
//  DPObject.h
//  DynamicProperties
//
//  Created by Tobias Kräntzer on 14.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DPObject : NSObject

@property (nonatomic, readonly) NSMutableDictionary *values;

- (id)dynamicValueForKey:(NSString *)key;
- (void)setDynamicValue:(id)value forKey:(NSString *)key;

@end
