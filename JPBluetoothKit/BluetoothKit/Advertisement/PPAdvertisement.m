//
//  PPAdvertisement.m
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

#import "PPAdvertisement.h"
#import "PPAdvertisementCoreManager.h"

@interface PPAdvertisement ()

@property (nonatomic, strong) PPConfiguration *configuration;
@property (nonatomic, strong) NSMutableArray *subscribedCentrals;
@property (nonatomic, strong) PPAdvertisementCoreManager *coreManager;

@end

@implementation PPAdvertisement

- (instancetype)init {
    if (self = [super init]) {
        self.coreManager = [PPAdvertisementCoreManager sharedManager];
        self.subscribedCentrals = [NSMutableArray new];
    }
    return self;
}

- (void)updateValue:(NSData *)value onCharacteristic:(PPCharacteristic *)characteristic {
    [self.coreManager updateValue:value onCharacteristic:characteristic.characteristic onCentrals:self.subscribedCentrals];
}

- (void)advertisePerpheralWithConfiguration:(PPConfiguration *)configuration {
    self.configuration = configuration;
    [self.coreManager setupAdvertisementWithConfiguration:configuration];
    [self setupSubscriptionHandler];
    [self setupUnsubscriptionHandler];
    [self setupWriteRequestHandler];
    [self setupReadRequestHandler];
}

- (void)setupSubscriptionHandler {
    __weak typeof(self) weakSelf = self;
    [self.coreManager setSubcriptionHandler:^(CBCentral *central) {
        [weakSelf.subscribedCentrals addObject:central];
    }];
}

- (void)setupUnsubscriptionHandler {
    __weak typeof(self) weakSelf = self;
    [self.coreManager setUnsubcriptionHandler:^(CBCentral *central) {
        [weakSelf.subscribedCentrals removeObject:central];
    }];
}

- (void)setupReadRequestHandler {
    __unused __weak typeof(self) weakSelf = self;
    [self.coreManager setReadRequestHandler:^NSData *(CBATTRequest *request) {
        PPCharacteristic *characteristic = [weakSelf.configuration mirrorCharacteristicFor:request.characteristic];
        if (weakSelf.readRequestHandler) {
            return weakSelf.readRequestHandler(characteristic);
        }
        return nil;
    }];
}

- (void)setupWriteRequestHandler {
    __unused __weak typeof(self) weakSelf = self;
    [self.coreManager setWriteRequestHandler:^(CBATTRequest *request) {
        PPCharacteristic *characteristic = [weakSelf.configuration mirrorCharacteristicFor:request.characteristic];
        if (weakSelf.writeRequestHandler) {
            weakSelf.writeRequestHandler(characteristic, request.value);
        }
    }];
}

@end
