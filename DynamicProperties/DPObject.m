//
//  DPObject.m
//  DynamicProperties
//
//  Created by Tobias Kräntzer on 14.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <objc/runtime.h>

#import "DPObjectProperty.h"

#import "DPObject.h"

@interface DPObject ()
@property (nonatomic, readonly) NSDictionary *propertyGetters;
@property (nonatomic, readonly) NSDictionary *propertySetters;
@property (nonatomic, readonly) NSDictionary *propertyDeclarations;
@end

@implementation DPObject

- (id)init
{
    self = [super init];
    if (self) {
        
        NSMutableDictionary *propertyGetters = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *propertySetters = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *propertyDeclarations   = [[NSMutableDictionary alloc] init];
        
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
                    
                    DPObjectProperty *op = [DPObjectProperty propertyWithDeclaration:property];
                    [propertyDeclarations setObject:op forKey:op.name];
                    [propertyGetters setObject:op.name forKey:NSStringFromSelector(op.getterSelector)];
                    if (!op.readonly) {
                        [propertySetters setObject:op.name forKey:NSStringFromSelector(op.setterSelector)];
                    }
                }
            }
            free(properties);
            
            _class = [_class superclass];
        }
        
        _propertyGetters        = propertyGetters;
        _propertySetters        = propertySetters;
        _propertyDeclarations   = propertyDeclarations;
        
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

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([[self.propertyDeclarations allKeys] containsObject:key]) {
        [self setDynamicValue:value forKey:key];
    } else {
        [super setValue:value forKey:key];
    }
}

- (id)valueForUndefinedKey:(NSString *)key
{
    if ([[self.propertyDeclarations allKeys] containsObject:key]) {
        return [self dynamicValueForKey:key];
    } else {
        return [super valueForUndefinedKey:key];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSString *selectorAsString = NSStringFromSelector(aSelector);
    NSString *propertyName = nil;
    
    // Getter
    propertyName = [self.propertyGetters objectForKey:selectorAsString];
    if (propertyName) {
        DPObjectProperty *property = [self.propertyDeclarations objectForKey:propertyName];
        NSString *propertyType = property.encoding;
        return [NSMethodSignature signatureWithObjCTypes:
                [[NSString stringWithFormat:@"%@@:", propertyType] UTF8String]];
    }
    
    // Setter
    propertyName = [self.propertySetters objectForKey:selectorAsString];
    if (propertyName) {
        DPObjectProperty *property = [self.propertyDeclarations objectForKey:propertyName];
        NSString *propertyType = property.encoding;
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
        DPObjectProperty *property = [self.propertyDeclarations objectForKey:propertyName];
        NSString *propertyType = property.encoding;
    
        NSAssert([propertyType hasPrefix:@"@"], @"Properties with type %@ are not supported.", propertyType);
        
        id value = [self dynamicValueForKey:propertyName];
        
        [anInvocation setReturnValue:&value];
        [anInvocation retainArguments];
        
        return;
    }
    
    // Setter
    propertyName = [self.propertySetters objectForKey:selectorAsString];
    if (propertyName) {
        DPObjectProperty *property = [self.propertyDeclarations objectForKey:propertyName];
        NSString *propertyType = property.encoding;
        
        NSAssert([propertyType hasPrefix:@"@"], @"Properties with type %@ are not supported.", propertyType);
        
        __unsafe_unretained id value = nil;
        [anInvocation getArgument:&value atIndex:2];
        
        [self setDynamicValue:value forKey:propertyName];
        
        return;
    }
    
    [super forwardInvocation:anInvocation];
}

@end
