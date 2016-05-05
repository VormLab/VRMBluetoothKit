//
//  VRMConfiguration.m
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

#import "VRMConfiguration.h"
#import "VRMErrorBuilder.h"
#import "VRMUtility.h"

@interface VRMConfiguration ()

@property (nonatomic, readwrite, strong) NSArray<VRMService *> *services;
@property (nonatomic, readwrite, strong) NSArray<VRMCharacteristic *> *characteristics;
@property (nonatomic, readwrite, strong) CBUUID *advServiceUUID;
@property (nonatomic, readwrite, strong) NSDictionary *advertisingPacket;

@end

@implementation VRMConfiguration

+ (VRMConfiguration *)adverisementConfigurationWithServices:(NSArray *)services characteristics:(NSArray *)characteristics advertisingPacket:(NSDictionary *)dictionary {
    VRMConfiguration *configuration = [VRMConfiguration new];
    configuration.services = services;
    configuration.characteristics = characteristics;
    configuration.advertisingPacket = dictionary;
    return configuration;
}

+ (VRMConfiguration *)connectionConfigurationWithServices:(NSArray *)services characteristics:(NSArray *)characteristics {
    VRMConfiguration *conf = [VRMConfiguration new];
    conf.services = services;
    conf.characteristics = characteristics;
    return conf;
}

+ (VRMConfiguration *)connectionConfigurationWithServices:(NSArray *)services characteristics:(NSArray *)characteristics advertisementUUID:(NSString *)uuid {
    VRMConfiguration *conf = [VRMConfiguration connectionConfigurationWithServices:services characteristics:characteristics];
    conf.advServiceUUID = [VRMUtility normalizedUUID:uuid error:nil];
    return conf;
}

- (NSArray<CBUUID *> *)rawServices {
    NSMutableArray *services = [NSMutableArray new];
    for (VRMService *service in self.services) {
        [services addObject:service.uuid];
    }
    return [services copy];
}

- (NSArray<VRMCharacteristic *> *)characteristicsContainedInService:(CBUUID *)serviceUUID {
    NSMutableArray *characteristics = [NSMutableArray new];
    for (VRMCharacteristic *characteristic in self.characteristics) {
        if ([[characteristic.containedService.uuid UUIDString].lowercaseString isEqualToString:serviceUUID.UUIDString.lowercaseString]) {
            [characteristics addObject:characteristic];
        }
    }
    return [characteristics copy];
}

- (NSArray<CBUUID *> *)characteristicsUUIDsContainedInService:(CBUUID *)serviceUUID {
    NSMutableArray *characteristics = [NSMutableArray new];
    for (VRMCharacteristic *characteristic in self.characteristics) {
        if ([[characteristic.containedService.uuid UUIDString].lowercaseString isEqualToString:serviceUUID.UUIDString.lowercaseString]) {
            [characteristics addObject:characteristic.uuid];
        }
    }
    return [characteristics copy];
}

#pragma mark - characteristics fetch

- (VRMCharacteristic *)characteristicWithIdentifier:(NSInteger)identifier {
    for (VRMCharacteristic *ch in self.characteristics) {
        if (ch.identifier == identifier) {
            return ch;
        }
    }
    return nil;
}

- (VRMCharacteristic *)characteristicWithOpenDescription:(NSString *)description {
    for (VRMCharacteristic *ch in self.characteristics) {
        if ([ch.openDescription isEqualToString:description]) {
            return ch;
        }
    }
    return nil;
}

#pragma mark - helper methods

- (BOOL)configurationContainsCharacteristic:(CBCharacteristic *)characteristic {
    if ([self mirrorCharacteristicFor:characteristic]) {
        return YES;
    }
    return NO;
}

- (VRMCharacteristic *)mirrorCharacteristicFor:(CBCharacteristic *)characteristic {
    for (VRMCharacteristic *ch in self.characteristics) {
        if ([ch.uuid.UUIDString.lowercaseString isEqualToString:characteristic.UUID.UUIDString.lowercaseString]) {
            return ch;
        }
    }
    return nil;
}

- (BOOL)configurationContainsService:(CBService *)service {
    if ([self mirrorServiceFor:service]) {
        return YES;
    }
    return NO;
}

- (VRMService *)mirrorServiceFor:(CBService *)service {
    for (VRMService *s in self.services) {
        if ([s.uuid.UUIDString.lowercaseString isEqualToString:service.UUID.UUIDString.lowercaseString]) {
            return s;
        }
    }
    return nil;
}

#pragma mark - description

- (NSString *)description {
    return [NSString stringWithFormat:@"\n Services: \n %@ \n Characteristics: \n :%@", self.services, self.characteristics];
}

@end
