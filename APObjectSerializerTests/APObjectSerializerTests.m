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
#import "APObjectSerializerSpec.h"

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

@interface Weapon : NSObject

@property (nonatomic, readonly, copy) NSString *name;

- (instancetype)initWithName:(NSString *)name;


@end

@implementation Weapon

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _name = [name copy];
    }

    return self;
}


@end

@interface BattleCar : Car

@property (nonatomic, readonly, assign) NSInteger maxHitpoints;
@property (nonatomic, readonly, strong) Weapon *weapon;

- (instancetype)initWithName:(NSString *)name driver:(Person *)driver coDriver:(Person *)coDriver maxHitpoints:(NSInteger)maxHitpoints weapon:(Weapon *)weapon;

@end

@implementation BattleCar

- (instancetype)initWithName:(NSString *)name driver:(Person *)driver coDriver:(Person *)coDriver maxHitpoints:(NSInteger)maxHitpoints weapon:(Weapon *)weapon
{
    self = [super init];
    if (self)
    {
        _maxHitpoints = maxHitpoints;
        _weapon = weapon;
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
    NSMutableArray *specs = [NSMutableArray new];
    [specs addObject:[[APObjectSerializerSpec alloc] initWithTargetClass:[Person class]
                                                            nameMappings:@
                                                            {
                                                                    @"first_name" : @"name",
                                                                    @"actual_age" : @"age",
                                                            }
                                                            typeMappings:nil]];

    [specs addObject:[[APObjectSerializerSpec alloc] initWithTargetClass:[Car class]
                                                            nameMappings:@
                                                            {
                                                                    @"stored_driver" : @"driver",
                                                            }
                                                            typeMappings:@
                                                            {
                                                                    @"driver" : [Person class],
                                                                    @"coDriver" : [Person class],
                                                            }]];


    [specs addObject:[[APObjectSerializerSpec alloc] initWithTargetClass:[BattleCar class]
                                                            nameMappings:@
                                                            {
                                                                    @"maxHp" : @"maxHitpoints",
                                                                    @"stored_weapon" : @"weapon",
                                                            }
                                                            typeMappings:@
                                                            {
                                                                    @"weapon" : [Weapon class],
                                                            }]];


    APObjectSerializer *serializer = [[APObjectSerializer alloc] initWithSpecs:specs];

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

    NSDictionary * weaponJSON = @
    {
            @"name" : @"Bazooka",
    };

    NSDictionary * carJSON = @
    {
        @"name" : @"Ferrari",
        @"stored_driver" : driverJSON,
        @"coDriver" : coDriverJSON,
        @"maxHp" : @(100),
        @"stored_weapon" : weaponJSON
    };

    Person *sourceDriver = [[Person alloc] initWithName:driverJSON[@"first_name"] age:[driverJSON[@"actual_age"]integerValue]];
    Person *sourceCoDriver = [[Person alloc] initWithName:coDriverJSON[@"first_name"] age:[coDriverJSON[@"actual_age"]integerValue]];
    BattleCar *sourceCar = [[BattleCar alloc] initWithName:carJSON[@"name"] driver:sourceDriver coDriver:sourceCoDriver maxHitpoints:[carJSON[@"maxHp"]integerValue] weapon:[[Weapon alloc] initWithName:weaponJSON[@"name"]]];

    BattleCar *deserializedCar = [serializer createObjectOfClass:[BattleCar class] fromDict:carJSON];

    XCTAssertEqualObjects(sourceCar.name, deserializedCar.name);
    XCTAssertEqualObjects(sourceCar.driver.name, deserializedCar.driver.name);
    XCTAssertEqualObjects(sourceCar.weapon.name, deserializedCar.weapon.name);
    XCTAssertEqual(sourceCar.driver.age, deserializedCar.driver.age);
    XCTAssertEqual(sourceCar.maxHitpoints, deserializedCar.maxHitpoints);

    NSDictionary *serializedCar = [serializer serializeObject:deserializedCar];
    NSDictionary *serializedDriver = serializedCar[@"stored_driver"];
    NSDictionary *serializedCoDriver = serializedCar[@"coDriver"];
    NSDictionary *serializedWeapon = serializedCar[@"stored_weapon"];
    XCTAssertEqualObjects(serializedCar[@"name"], carJSON[@"name"]);
    XCTAssertEqualObjects(serializedCar[@"maxHp"], carJSON[@"maxHp"]);
    XCTAssertEqualObjects(serializedWeapon[@"name"], weaponJSON[@"name"]);
    XCTAssertEqualObjects(serializedDriver[@"first_name"], driverJSON[@"first_name"]);
    XCTAssertEqualObjects(serializedDriver[@"actual_age"], driverJSON[@"actual_age"]);
    XCTAssertEqualObjects(serializedCoDriver[@"first_name"], serializedCoDriver[@"first_name"]);
    XCTAssertEqualObjects(serializedCoDriver[@"actual_age"], serializedCoDriver[@"actual_age"]);
}

@end
