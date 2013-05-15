//
//  DPObject.m
//  DynamicProperties
//
//  Created by Tobias Kräntzer on 14.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <objc/runtime.h>

#import "DPObject.h"

@interface DPObject ()
@property (nonatomic, readonly) NSDictionary *propertyGetters;
@property (nonatomic, readonly) NSDictionary *propertySetters;
@property (nonatomic, readonly) NSDictionary *propertyTypes;
@end

@implementation DPObject

- (id)init
{
    self = [super init];
    if (self) {
        
        NSMutableDictionary *propertyGetters = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *propertySetters = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *propertyTypes   = [[NSMutableDictionary alloc] init];
        
        Class _class = [self class];
        while (_class != [NSObject class]) {
            
            unsigned int outCount, i;
            objc_property_t *properties = class_copyPropertyList(_class, &outCount);
            for (i = 0; i < outCount; i++) {
                objc_property_t property = properties[i];
                
                // Check if the property is dynamic (@dynamic).
                char *dynamic = property_copyAttributeValue(property, "D");
                if (dynamic) {
                    free(dynamic);
                    
                    // Get the name of the property
                    NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
                    
                    // Get the selector for the getter
                    char *getterName = property_copyAttributeValue(property, "G");
                    if (getterName) {
                        [propertyGetters setObject:propertyName forKey:[NSString stringWithUTF8String:getterName]];
                        free(getterName);
                    } else {
                        [propertyGetters setObject:propertyName forKey:propertyName];
                    }
                    
                    // Check if the property is read-only
                    char *readonly = property_copyAttributeValue(property, "R");
                    if (readonly) {
                        free(readonly);
                    } else {
                        
                        // Get the selector for the setter
                        char *setterName = property_copyAttributeValue(property, "S");
                        if (setterName) {
                            [propertySetters setObject:propertyName forKey:[NSString stringWithUTF8String:setterName]];
                            free(setterName);
                        } else {
                            NSString *selectorString = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                                                             withString:[[propertyName substringToIndex:1] uppercaseString]];
                            selectorString = [NSString stringWithFormat:@"set%@:", selectorString];
                            [propertySetters setObject:propertyName forKey:selectorString];
                        }
                    }
                    
                    // Get the type encoding of the property
                    char *type = property_copyAttributeValue(property, "T");
                    if (type) {
                        [propertyTypes setObject:[NSString stringWithUTF8String:type] forKey:propertyName];
                        free(type);
                    }
                    
                }
            }
            free(properties);
            
            _class = [_class superclass];
        }
        
        _propertyGetters = propertyGetters;
        _propertySetters = propertySetters;
        _propertyTypes   = propertyTypes;
        
        _values = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)dynamicValueForKey:(NSString *)key;
{
    return [self.values objectForKey:key];
}

- (void)setDynamicValue:(id)value forKey:(NSString *)key;
{
    if (value == nil) {
        [self.values removeObjectForKey:key];
    } else {
        [self.values setObject:value forKey:key];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSString *selectorAsString = NSStringFromSelector(aSelector);
    NSString *propertyName = nil;
    
    // Getter
    propertyName = [self.propertyGetters objectForKey:selectorAsString];
    if (propertyName) {
        NSString *propertyType = [self.propertyTypes objectForKey:propertyName];
        return [NSMethodSignature signatureWithObjCTypes:
                [[NSString stringWithFormat:@"%@@:", propertyType] UTF8String]];
    }
    
    // Setter
    propertyName = [self.propertySetters objectForKey:selectorAsString];
    if (propertyName) {
        NSString *propertyType = [self.propertyTypes objectForKey:propertyName];
        return [NSMethodSignature signatureWithObjCTypes:
                [[NSString stringWithFormat:@"v@:%@", propertyType] UTF8String]];
    }
    
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSString *selectorAsString = NSStringFromSelector([anInvocation selector]);
    NSString *propertyName = nil;
    
    // Getter
    propertyName = [self.propertyGetters objectForKey:selectorAsString];
    if (propertyName) {
        NSString *propertyType = [self.propertyTypes objectForKey:propertyName];
    
        NSAssert([propertyType hasPrefix:@"@"], @"Properties with type %@ are not supported.", propertyType);
        
        id value = [self dynamicValueForKey:propertyName];
        
        [anInvocation setReturnValue:&value];
        [anInvocation retainArguments];
        
        return;
    }
    
    // Setter
    propertyName = [self.propertySetters objectForKey:selectorAsString];
    if (propertyName) {
        NSString *propertyType = [self.propertyTypes objectForKey:propertyName];
        
        NSAssert([propertyType hasPrefix:@"@"], @"Properties with type %@ are not supported.", propertyType);
        
        __unsafe_unretained id value = nil;
        [anInvocation getArgument:&value atIndex:2];
        
        [self setDynamicValue:value forKey:propertyName];
        
        return;
    }
    
    [super forwardInvocation:anInvocation];
}

@end
