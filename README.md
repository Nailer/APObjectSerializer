# APObjectSerializer
A Obj-C library for easy JSON serialization and de-serialization.

The goal of this library is to easily facilitate JSON serialization and de-serialization without writing any specific code.
The library allows for this without requiring any code in the serialized class itself. 
This de-couples the storage from the data object itself.


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
    
    Car *deserializedCar = [serializer createObjectOfClass:[Car class] fromDict:carJSON];
    NSDictionary *serializedCar = [serializer serializeObject:deserializedCar];
