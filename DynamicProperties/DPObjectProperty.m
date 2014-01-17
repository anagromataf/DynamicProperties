//
//  DPObjectProperty.m
//  DynamicProperties
//
//  Created by Tobias Kräntzer on 17.01.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "DPObjectProperty.h"

@implementation DPObjectProperty

+ (instancetype)propertyWithDeclaration:(objc_property_t)property
{
    return [[self alloc] initWithDeclaration:property];
}

#pragma mark Life-cycle

- (id)initWithDeclaration:(objc_property_t)property
{
    self = [super init];
    if (self) {
        // Get the name of the property
        _name = [NSString stringWithUTF8String:property_getName(property)];
        
        // Get the selector for the getter
        char *getterName = property_copyAttributeValue(property, "G");
        if (getterName) {
            _getterSelector = NSSelectorFromString([NSString stringWithUTF8String:getterName]);
            free(getterName);
        } else {
            _getterSelector = NSSelectorFromString(_name);
        }
        
        // Check if the property is read-only
        char *readonly = property_copyAttributeValue(property, "R");
        if (readonly) {
            _readonly = YES;
            free(readonly);
        } else {
            
            // Get the selector for the setter
            char *setterName = property_copyAttributeValue(property, "S");
            if (setterName) {
                _setterSelector = NSSelectorFromString([NSString stringWithUTF8String:setterName]);
                free(setterName);
            } else {
                NSString *selectorString = [_name stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                                          withString:[[_name substringToIndex:1] uppercaseString]];
                selectorString = [NSString stringWithFormat:@"set%@:", selectorString];
                _setterSelector = NSSelectorFromString(selectorString);
            }
        }
        
        // Get the type encoding of the property
        char *type = property_copyAttributeValue(property, "T");
        if (type) {
            _encoding = [NSString stringWithUTF8String:type];
            free(type);
        }
        
        // Check if the value should be copied
        char *copy = property_copyAttributeValue(property, "C");
        if (copy) {
            _copy = YES;
            free(copy);
        }
        
        // Check if the value should be stored weak
        char *weak = property_copyAttributeValue(property, "W");
        if (weak) {
            _weak = YES;
            free(weak);
        }
    }
    return self;
}

@end
