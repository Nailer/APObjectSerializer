#import "APObjectSerializer.h"
#import <objc/runtime.h>

#define kArrayItemKey @"_mangled_items_"

@implementation APObjectSerializerPropertyTypeMapping

- (instancetype)initWithPropertyName:(NSString *)propertyName propertyType:(Class)propertyType
{
    self = [super init];
    if (self)
    {
        _propertyName = [propertyName copy];
        _propertyType = [propertyType copy];
    }

    return self;
}

@end

@implementation APObjectSerializerPropertyNameMapping

- (instancetype)initWithStorageKey:(NSString *)storageKey propertyName:(NSString *)propertyName
{
    self = [super init];
    if (self)
    {
        _storageKey = [storageKey copy];
        _propertyName = [propertyName copy];
    }

    return self;
}

@end

@interface APObjectSerializer()

// Stores all property names for a given class and its entire hierarchy.
// Eg. User inherits Person. The list will include all property names from both User and Person class
@property (nonatomic, strong) NSMutableDictionary *classToPropertyNameListDict;

// Stores a cached mapping from a given name, to the name of the actual property in the class in question
// Eg. stores that there is a mapping from "name" to "userName" or "id" to "customerId"
@property (nonatomic, strong) NSMutableDictionary *classToPropertyNameMappingDict;

// Same as classToPropertyNameMappingDict, but cached for each class and all of its superclasses
// Eg. User inherits Person, therefore this mapping will include the mappings for both User AND Person
@property (nonatomic, strong) NSMutableDictionary *classHierarchyToPropertyNameListDict;

// Stores a cached mapping from a certain property, to the class of that property
// Eg. property name "user" maps to a class with the name "User"
@property (nonatomic, strong) NSMutableDictionary *classPropertyMappingDict;

// Same as classPropertyMappingDict, but cached for each class and all of its superclasses
// Eg. User inherits Person, therefore this mapping will include the mappings for both User AND Person
@property (nonatomic, strong) NSMutableDictionary *classHierarchyPropertyMappingDict;

// Stores class hierarchies for classes. Omits NSObject
// Eg. Class hierarchy Entity>Person>User asking for the hierarchy for User will return ["Person","Entity"]
@property (nonatomic, strong) NSMutableDictionary *classHierarchyCache;

@end

@implementation APObjectSerializer

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.classToPropertyNameListDict = [NSMutableDictionary new];
        self.classToPropertyNameMappingDict = [NSMutableDictionary new];
        self.classHierarchyToPropertyNameListDict = [NSMutableDictionary new];
        self.classPropertyMappingDict = [NSMutableDictionary new];
        self.classHierarchyPropertyMappingDict = [NSMutableDictionary new];
        self.classHierarchyCache = [NSMutableDictionary new];
    }

    return self;
}

#pragma mark - Public

- (id)createObjectOfClass:(Class)objectClass fromDict:(NSDictionary *)dict
{
    if (!dict)
    {
        return nil;
    }

    NSArray *itemArray = dict[kArrayItemKey];
    if (itemArray)
    {
        NSMutableArray *deSerializedItems = [NSMutableArray new];
        for (NSDictionary *objDict in itemArray)
        {
            [deSerializedItems addObject:[self createObjectOfClass:objectClass fromDict:objDict]];
        }

        return deSerializedItems;
    }

    id object = [objectClass new];
    [self updateObject:object fromDict:dict];
    return object;
}

- (NSDictionary *)serializeObject:(id)object
{
    if (!object)
    {
        return nil;
    }

    if ([object isKindOfClass:[NSArray class]])
    {
        NSMutableArray *serializedObjects = [NSMutableArray new];
        for (id child in object)
        {
            [serializedObjects addObject:[self serializeObject:child]];
        }
        return @{kArrayItemKey : serializedObjects};
    }

    NSArray *nonNilKeys = [self findNonNilKeysForObject:object];
    NSDictionary *serializedObjectBase = [object dictionaryWithValuesForKeys:nonNilKeys];
    NSDictionary *propertyClassMappingForClass = [self propertyClassMappingForClass:[object class]];
    NSDictionary *propertyNameMappingForClass = [self propertyNameMappingForClass:[object class]];
    NSMutableDictionary *serializedObject = [NSMutableDictionary new];
    for (NSString *key in serializedObjectBase)
    {
        id actualValue = serializedObjectBase[key];
        NSString *keyWhenSerialized = [self keyWhenSerializedForKey:key usingPropertyNameMapping:propertyNameMappingForClass];
        Class substituteClass = propertyClassMappingForClass[key];
        serializedObject[keyWhenSerialized] = [self serializeValue:actualValue usingCustomClass:substituteClass];
    }

    return serializedObject;
}

- (void)registerPropertyTypeMapping:(APObjectSerializerPropertyTypeMapping *)mapping forClass:(Class)clazz
{
    NSString *className = NSStringFromClass(clazz);
    NSMutableDictionary *mappingsForClass = self.classPropertyMappingDict[className];
    if (!mappingsForClass)
    {
        mappingsForClass = [NSMutableDictionary new];
        self.classPropertyMappingDict[className] = mappingsForClass;
    }

    mappingsForClass[mapping.propertyName] = mapping.propertyType;
}

- (void)registerPropertyNameMapping:(APObjectSerializerPropertyNameMapping *)mapping forClass:(Class)clazz
{
    NSString *className = NSStringFromClass(clazz);
    NSMutableDictionary *mappingsForClass = self.classToPropertyNameMappingDict[className];
    if (!mappingsForClass)
    {
        mappingsForClass = [NSMutableDictionary new];
        self.classToPropertyNameMappingDict[className] = mappingsForClass;
    }

    mappingsForClass[mapping.storageKey] = mapping.propertyName;
}

#pragma mark - Helpers

- (id)serializeValue:(id)value usingCustomClass:(Class)customClass
{
    id serializedValue = value;
    BOOL objectNeedsCustomSerialization = customClass != nil;
    if (objectNeedsCustomSerialization)
    {
        if ([value isKindOfClass:[NSArray class]])
        {
            NSArray *valueArray = value;
            NSMutableArray *serializedValues = [NSMutableArray new];
            for (id item in valueArray)
            {
                [serializedValues addObject:[self serializeObject:item]];
            }

            serializedValue = serializedValues;
        } else
        {
            // NOTE THE RECURSION!
            serializedValue = [self serializeObject:value];
        }
    }

    return serializedValue;
}

- (void)updateObject:(id)object fromDict:(NSDictionary *)dict
{
    NSDictionary *propertyClassMappingForClass = [self propertyClassMappingForClass:[object class]];
    NSDictionary *propertyNameMappingForClass = [self propertyNameMappingForClass:[object class]];
    for (NSString *key in [dict allKeys])
    {
        NSString *mappedKey = propertyNameMappingForClass[key];
        NSString *keyWhenDeSerialized = mappedKey ? mappedKey : key;
        Class customClass = propertyClassMappingForClass[key];
        id deSerializedValue = [self deSerializedObjectFromValue:dict[key] customClass:customClass];
        [object setValue:deSerializedValue forKey:keyWhenDeSerialized];
    }
}

- (id)deSerializedObjectFromValue:(id)value customClass:(Class)customClass
{
    id customClassValue = value;
    if (customClass)
    {
        if ([value isKindOfClass:[NSDictionary class]])
        {
            customClassValue = [customClass new];
            [self updateObject:customClassValue fromDict:value];
        }
        else if ([value isKindOfClass:[NSArray class]] && [value count] > 0)
        {
            id firstArrayValue = value[0];
            BOOL shouldTransform = [firstArrayValue isKindOfClass:[NSDictionary class]];
            if (shouldTransform)
            {
                NSArray *array = value;
                NSMutableArray *transformedItems = [NSMutableArray new];
                for (id arrayItem in array)
                {
                    id transformedValue = [customClass new];
                    [self updateObject:transformedValue fromDict:arrayItem];
                    [transformedItems addObject:transformedValue];
                }
                customClassValue = transformedItems;
            }
        }
    }

    return customClassValue;
}

- (NSArray *)superClassesForClass:(Class)objClass
{
    if ([objClass superclass] == [NSObject class])
    {
        return nil;
    }

    NSString *className = NSStringFromClass(objClass);
    NSArray *cachedClasses = self.classHierarchyCache[className];
    if (cachedClasses)
    {
        return cachedClasses;
    }

    NSMutableArray *classes = [NSMutableArray new];
    Class currentClass = objClass;
    do
    {
        Class superClass = [currentClass superclass];
        [classes addObject:superClass];
        currentClass = superClass;
    } while ([currentClass superclass] != [NSObject class]);

    self.classHierarchyCache[className] = classes;

    return classes;
}

- (NSDictionary *)propertyNameMappingForClass:(Class)objClass
{
    return [self mapFromClass:objClass
               mappingForClass:self.classToPropertyNameMappingDict
storedMappingForClassHierarchy:self.classHierarchyToPropertyNameListDict];
}

- (NSDictionary *)propertyClassMappingForClass:(Class)objClass
{
    return [self mapFromClass:objClass
               mappingForClass:self.classPropertyMappingDict
storedMappingForClassHierarchy:self.classHierarchyPropertyMappingDict];
}

- (NSDictionary *)mapFromClass:(Class)objClass
               mappingForClass:(NSDictionary *)mappingForClass
storedMappingForClassHierarchy:(NSMutableDictionary *)storedMappingForClassHierarchy
{
    NSArray *classes = [self superClassesForClass:objClass];
    NSString *className = NSStringFromClass(objClass);
    if (classes.count > 0)
    {
        NSDictionary *cachedMapping = storedMappingForClassHierarchy[className];
        if (cachedMapping)
        {
            return cachedMapping;
        }

        NSMutableDictionary *mapping = [NSMutableDictionary new];
        NSDictionary *classProps = mappingForClass[className];
        if (classProps)
        {
            [mapping addEntriesFromDictionary:classProps];
        }

        for (Class c in classes)
        {
            NSDictionary *dictToMerge = mappingForClass[NSStringFromClass(c)];
            if (dictToMerge)
            {
                [mapping addEntriesFromDictionary:dictToMerge];
            }
        }

        storedMappingForClassHierarchy[className] = mapping;
        return mapping;
    } else
    {
        return mappingForClass[className];
    }
}

- (NSArray *)findNonNilKeysForObject:(id)object
{
    NSArray *propertyNamesForClass = [self propertyNamesForClass:[object class]];
    NSMutableArray *nonNilKeys = [NSMutableArray new];
    for (NSString *key in propertyNamesForClass)
    {
        if ([object valueForKey:key] != nil)
        {
            [nonNilKeys addObject:key];
        }
    }

    return nonNilKeys;
}

- (NSArray *)propertyNamesForClass:(Class)class
{
    NSString *className = NSStringFromClass(class);
    NSMutableArray *classPropertyNames = self.classToPropertyNameListDict[className];

    if (!classPropertyNames)
    {
        classPropertyNames = [NSMutableArray array];

        [self propertyNamesForClass:class propertyNames:classPropertyNames];

        self.classToPropertyNameListDict[className] = classPropertyNames;
    }

    return classPropertyNames;
}

// Recursively traverse all property names up until NSObject
- (void)propertyNamesForClass:(Class)class propertyNames:(NSMutableArray *)propertyNames
{
    if (![NSStringFromClass(class.superclass) isEqualToString:@"NSObject"])
    {
        [self propertyNamesForClass:class.superclass propertyNames:propertyNames];
    }

    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
    for (unsigned int i = 0; i < propertyCount; ++i)
    {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        [propertyNames addObject:[NSString stringWithUTF8String:name]];
    }
    free(properties);
}

- (NSString *)keyWhenSerializedForKey:(NSString *)key usingPropertyNameMapping:(NSDictionary *)propertyNameMapping
{
    //TODO: Optimize this when time arises by storing a reverse property name mapping! For now we haxxor a bit
    NSSet *translatedKeys = [propertyNameMapping keysOfEntriesPassingTest:^BOOL(id k, id obj, BOOL *stop)
    {
        return [obj isEqualToString:key];
    }];

    NSString *translatedKey = [translatedKeys anyObject];
    return translatedKey ? translatedKey : key;
}

@end
