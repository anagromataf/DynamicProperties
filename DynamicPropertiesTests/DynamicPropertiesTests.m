//
//  DynamicPropertiesTests.m
//  DynamicPropertiesTests
//
//  Created by Tobias Kräntzer on 14.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "DPTestObject.h"

#import "DynamicPropertiesTests.h"

@implementation DynamicPropertiesTests

- (void)testDynamicProperties
{
    DPTestObject *object = [[DPTestObject alloc] init];
    
    STAssertNil(object.name, nil);
    
    object.name = @"Foo";
    STAssertEqualObjects(object.name, @"Foo", nil);
    STAssertEqualObjects(object.values, @{@"name":@"Foo"}, nil);
    
    object.name = nil;
    STAssertNil(object.name, nil);
    STAssertEqualObjects(object.values, @{}, nil);
    
    [object.values setObject:@"Bar" forKey:@"name"];
    STAssertNotNil(object.name, nil);
    STAssertEqualObjects(object.name, @"Bar", nil);
}

@end
