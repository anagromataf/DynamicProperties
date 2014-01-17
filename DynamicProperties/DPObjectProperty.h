//
//  DPObjectProperty.h
//  DynamicProperties
//
//  Created by Tobias Kräntzer on 17.01.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface DPObjectProperty : NSObject

+ (instancetype)propertyWithDeclaration:(objc_property_t)property;

#pragma mark Life-cycle

- (id)initWithDeclaration:(objc_property_t)property;

#pragma mark Name

@property (nonatomic, readonly) NSString *name;

#pragma mark Read Write

@property (nonatomic, readonly, getter=isReadonly) BOOL readonly;

#pragma mark Ownership

@property (nonatomic, readonly, getter=isWeak) BOOL weak;
@property (nonatomic, readonly, getter=isCopy) BOOL copy;

#pragma mark Selectors

@property (nonatomic, readonly) SEL getterSelector;
@property (nonatomic, readonly) SEL setterSelector;

#pragma mark Type Encoding

@property (nonatomic, readonly) NSString *encoding;

@end
