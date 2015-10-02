#import <Foundation/Foundation.h>

@interface APObjectSerializerSpec : NSObject

@property (nonatomic, readonly, copy) Class targetClass;
@property (nonatomic, readonly, copy) NSDictionary *nameMappings;
@property (nonatomic, readonly, copy) NSDictionary *reverseNameMappings;
@property (nonatomic, readonly, copy) NSDictionary *typeMappings;

/**
 Creates a spec that describes to APObjectSerializer how to serialize/deserialize an object
 Example:

 [[APObjectSerializerSpec alloc] initWithTargetClass:[Car class]
                                        nameMappings:@
                                        {
                                                @"stored_driver" : @"driver", // Key is the name of the key in the JSON dictionary we're deserializing
                                        }
                                        typeMappings:@
                                        {
                                                @"driver" : [Person class], // Key is name of the property in the targetClass. NOT the key in the JSON dictionary
                                                @"coDriver" : [Person class],
                                        }]
 */
- (instancetype)initWithTargetClass:(Class)targetClass
                       nameMappings:(NSDictionary *)nameMappings
                       typeMappings:(NSDictionary *)typeMappings;

@end
