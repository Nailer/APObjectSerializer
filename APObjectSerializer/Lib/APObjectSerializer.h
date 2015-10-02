//
//  Created by Andreas Petrov on 13/08/15.
//  Copyright (c) 2015 Andreas Petrov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APObjectSerializer : NSObject

@property (nonatomic, readonly, copy) NSArray *specs;


/**
 Create a serializer with a list of APObjectSerializerSpec objects.
 */
- (instancetype)initWithSpecs:(NSArray *)specs;

/**
 Creates an object of the given class with the given dictionary as source data
 Populating properties using Non-built-in classes must be configured using registerPropertyClassMappingForClass
 */
- (id)createObjectOfClass:(Class)objectClass fromDict:(NSDictionary *)dict;

/**
 Returns the object serialized in the form of a NSDictionary
 */
- (NSDictionary *)serializeObject:(id)object;

@end
