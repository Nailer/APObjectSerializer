#import <Foundation/Foundation.h>

@interface APObjectSerializerPropertyTypeMapping : NSObject

@property (nonatomic, readonly, copy) NSString *propertyName;
@property (nonatomic, readonly, copy) Class propertyType;

- (instancetype)initWithPropertyName:(NSString *)propertyName propertyType:(Class)propertyType;

@end


@interface APObjectSerializerPropertyNameMapping : NSObject

/**
 The name of the key used to stored the mapped property in its serialized form.
 Most usually the name the key has in its JSON dictionary
 */
@property (nonatomic, readonly, copy) NSString *storageKey;

/**
 The name of the property to assign the value of the storageKey.
 */
@property (nonatomic, readonly, copy) NSString *propertyName;

- (instancetype)initWithStorageKey:(NSString *)storageKey propertyName:(NSString *)propertyName;

@end

@interface APObjectSerializer : NSObject

/**
 Creates an object of the given class with the given dictionary as source data
 Populating properties using Non-built-in classes must be configured using registerPropertyClassMappingForClass
 */
- (id)createObjectOfClass:(Class)objectClass fromDict:(NSDictionary *)dict;

/**
 Returns the object serialized in the form of a NSDictionary
 */
- (NSDictionary *)serializeObject:(id)object;

/**
 A mapping between a property and its type
 Example: If your Vehicle class has a driver property of type Person, initialize it in the following way
 [self registerPropertyTypeMapping:[[APObjectSerializerPropertyTypeMapping alloc]initWithPropertyName:@"driver" propertyType:[Person class]] forClass:[Vehicle class]]
 */
- (void)registerPropertyTypeMapping:(APObjectSerializerPropertyTypeMapping *)mapping forClass:(Class)clazz;

/**
 A mapping between name of property in its stored form (NSDictionary) to its object form.
 Example: If class Person has a property firstName and it's value comes from a dictionary with the key first_name register it in
 the following way
 [self registerPropertyNameMapping:[[APObjectSerializerPropertyNameMapping alloc]initWithStorageKey:@"first_name" propertyName:@"firstName"]] forClass:[Person class]]
 */
- (void)registerPropertyNameMapping:(APObjectSerializerPropertyNameMapping *)mapping forClass:(Class)clazz;

@end
