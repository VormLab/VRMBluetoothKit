//
//  PPAdvertisementCoreManager.m
//
// Copyright (c) 2016 Jan Posz
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PPAdvertisementCoreManager.h"
#import "PPErrorBuilder.h"
@import CoreBluetooth;

@interface PPAdvertisementCoreManager () <CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSArray *mutableCharacteristics;
@property (nonatomic, strong) PPConfiguration *configuration;

@end

@implementation PPAdvertisementCoreManager

+ (PPAdvertisementCoreManager *)sharedManager {
    
    static PPAdvertisementCoreManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)setupAdvertisementWithConfiguration:(PPConfiguration *)configuration {
    self.mutableCharacteristics = @[];
    self.configuration = configuration;
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (CBPeripheralManagerStatePoweredOn == peripheral.state) {
        [self setupAdvertisement];
    }
    else {
        __unused NSError *error = [PPErrorBuilder errorForBluetoothPeripheralState:peripheral.state];
    }
}

#pragma mark - advertisement setup

- (void)setupAdvertisement {
    NSArray *services = [self services];
    for (CBMutableService *service in services) {
        [self.peripheralManager addService:service];
    }
    [self.peripheralManager startAdvertising:self.configuration.advertisingPacket];
}

- (NSArray *)services {
    
    NSMutableArray *allServices = [NSMutableArray new];
    for (PPService *service in self.configuration.services) {
        CBMutableService *s = [[CBMutableService alloc] initWithType:service.uuid primary:YES];
        s.characteristics = [self characteristcsForService:service];
        [allServices addObject:s];
    }
    return [allServices copy];
}

- (NSArray *)characteristcsForService:(PPService *)service {
    NSArray *characteristics = [self.configuration characteristicsContainedInService:service.uuid];
    NSMutableArray *includeCharacteristics = [NSMutableArray new];
    NSMutableArray *mutable = [NSMutableArray new];
    for (PPCharacteristic *characteristic in characteristics) {
        CBMutableCharacteristic *ch = [[CBMutableCharacteristic alloc] initWithType:characteristic.uuid properties:characteristic.properties value:nil permissions:characteristic.permissions];
        [mutable addObject:ch];
        characteristic.characteristic = [ch copy];
        [includeCharacteristics addObject:[ch copy]];
    }
    self.mutableCharacteristics = [mutable copy];
    return characteristics;
}

#pragma mark - value update

- (void)updateValue:(NSData *)data onCharacteristic:(CBCharacteristic *)characteristic onCentrals:(NSMutableArray *)centrals {
    CBMutableCharacteristic *ref = nil;
    for (CBMutableCharacteristic *ch in self.mutableCharacteristics) {
        if ([ch.UUID.UUIDString.lowercaseString isEqualToString:characteristic.UUID.UUIDString.lowercaseString]) {
            ref = ch;
        }
    }
    if (ref) {
        [self.peripheralManager updateValue:data forCharacteristic:ref onSubscribedCentrals:centrals];
    }
    else {
        NSLog(@"Desired characteristic not found");
    }
}

#pragma mark - peripheral manager delegate

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    if (self.subcriptionHandler) {
        self.subcriptionHandler(central);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    if (self.unsubcriptionHandler) {
        self.unsubcriptionHandler(central);
    }
}

#pragma mark - readwrite requests

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    if (self.readRequestHandler) {
        self.readRequestHandler(request);
    }
    NSData *data = nil;
    if (self.readRequestHandler) {
        data = self.readRequestHandler(request);
    }
    request.value = data;
    //FIXME: proper error handling
    [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    if (self.writeRequestHandler) {
        self.writeRequestHandler([requests objectAtIndex:0]);
    }
    //FIXME: proper error handling + multiple request handling
    if (self.writeRequestHandler) {
        self.writeRequestHandler([requests objectAtIndex:0]);
    }
    [self.peripheralManager respondToRequest:[requests objectAtIndex:0] withResult:CBATTErrorSuccess];
}

@end
