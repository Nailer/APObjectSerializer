//
//  APObjectSerializerTests.m
//  APObjectSerializerTests
//
//  Created by Andreas Petrov on 13/08/15.
//  Copyright (c) 2015 Andreas Petrov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "APObjectSerializer.h"

@interface Person : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, assign) NSInteger age;

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age;


@end

@implementation Person

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age
{
    self = [super init];
    if (self)
    {
        _name = name;
        _age = age;
    }

    return self;
}

@end

@interface Car : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) Person *driver;
@property (nonatomic, readonly, strong) Person *coDriver;

- (instancetype)initWithName:(NSString *)name driver:(Person *)driver coDriver:(Person *)coDriver;

@end

@implementation Car

- (instancetype)initWithName:(NSString *)name driver:(Person *)driver coDriver:(Person *)coDriver
{
    self = [super init];
    if (self)
    {
        _name = name;
        _driver = driver;
        _coDriver = coDriver;
    }

    return self;
}

@end

@interface APObjectSerializerTests : XCTestCase

@end

@implementation APObjectSerializerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSerializationRoundtrip
{
    APObjectSerializer *serializer = [APObjectSerializer new];
    [serializer registerPropertyNameMapping:[[APObjectSerializerPropertyNameMapping alloc] initWithStorageKey:@"first_name" propertyName:@"name"] forClass:[Person class]];
    [serializer registerPropertyNameMapping:[[APObjectSerializerPropertyNameMapping alloc] initWithStorageKey:@"actual_age" propertyName:@"age"] forClass:[Person class]];

    [serializer registerPropertyNameMapping:[[APObjectSerializerPropertyNameMapping alloc] initWithStorageKey:@"stored_driver" propertyName:@"driver"] forClass:[Car class]];
    [serializer registerPropertyTypeMapping:[[APObjectSerializerPropertyTypeMapping alloc] initWithPropertyName:@"driver" propertyType:[Person class]] forClass:[Car class]];
    [serializer registerPropertyTypeMapping:[[APObjectSerializerPropertyTypeMapping alloc] initWithPropertyName:@"coDriver" propertyType:[Person class]] forClass:[Car class]];


    NSDictionary *driverJSON =  @
    {
            @"first_name" : @"Andreas",
            @"actual_age" : @(28),
    };

    NSDictionary *coDriverJSON =  @
    {
        @"first_name" : @"Skybert",
        @"actual_age" : @(29),
    };
    
    NSDictionary * carJSON = @
    {
        @"name" : @"Ferrari",
        @"stored_driver" : driverJSON,
        @"coDriver" : coDriverJSON,
    };

    Person *sourceDriver = [[Person alloc] initWithName:driverJSON[@"first_name"] age:[driverJSON[@"actual_age"]integerValue]];
    Person *sourceCoDriver = [[Person alloc] initWithName:coDriverJSON[@"first_name"] age:[coDriverJSON[@"actual_age"]integerValue]];
    Car *sourceCar = [[Car alloc] initWithName:carJSON[@"name"] driver:sourceDriver coDriver:sourceCoDriver];

    Car *deserializedCar = [serializer createObjectOfClass:[Car class] fromDict:carJSON];

    XCTAssertEqualObjects(sourceCar.name, deserializedCar.name);
    XCTAssertEqualObjects(sourceCar.driver.name, deserializedCar.driver.name);
    XCTAssertEqual(sourceCar.driver.age, deserializedCar.driver.age);

    NSDictionary *serializedCar = [serializer serializeObject:deserializedCar];
    NSDictionary *serializedDriver = serializedCar[@"stored_driver"];
    NSDictionary *serializedCoDriver = serializedCar[@"coDriver"];
    XCTAssertEqualObjects(serializedCar[@"name"], carJSON[@"name"]);
    XCTAssertEqualObjects(serializedDriver[@"first_name"], driverJSON[@"first_name"]);
    XCTAssertEqualObjects(serializedDriver[@"actual_age"], driverJSON[@"actual_age"]);
    XCTAssertEqualObjects(serializedCoDriver[@"first_name"], serializedCoDriver[@"first_name"]);
    XCTAssertEqualObjects(serializedCoDriver[@"actual_age"], serializedCoDriver[@"actual_age"]);
}

@end
