//
//  PPCentralManager.m
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

#import "PPCentralManager.h"

@interface PPCentralManager () <CBCentralManagerDelegate>

@property (nonatomic, readwrite, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray *activeSubscribers;
@property (nonatomic, strong) NSMutableArray *subscribers;
@property (nonatomic, strong) NSMutableArray *configurations;

@end

@implementation PPCentralManager

+ (PPCentralManager *)sharedManager {
    
    static PPCentralManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.activeSubscribers = [NSMutableArray new];
        self.subscribers = [NSMutableArray new];
        self.configurations = [NSMutableArray new];
    }
    return self;
}

- (void)addSubsriber:(id<CBCentralManagerDelegate>)subscriber withConfiguration:(PPConfiguration *)configuration {
    [self.configurations addObject:configuration];
    [self reloadScan];
    [self.activeSubscribers addObject:subscriber];
    if (![self.subscribers containsObject:subscriber]) {
        [self.subscribers addObject:subscriber];
    }
}

- (void)removeSubsriber:(id<CBCentralManagerDelegate>)subscriber withConfiguration:(PPConfiguration *)configuration {
    [self.configurations removeObject:configuration];
    [self.activeSubscribers removeObject:subscriber];
    if (self.activeSubscribers.count) {
        [self reloadScan];
    }
    [self stopScan];
}

- (void)permanentlyRemoveSubsriber:(id<CBCentralManagerDelegate>)subscriber withConfiguration:(PPConfiguration *)configuration {
    [self removeSubsriber:subscriber withConfiguration:configuration];
    [self.subscribers removeObject:subscriber];
}

#pragma mark - scanning

- (void)reloadScan {
    NSMutableArray *scanParams = [NSMutableArray new];
    for (PPConfiguration *configuration in self.configurations) {
        if (configuration.advServiceUUID) {
            [scanParams addObject:configuration.advServiceUUID];
        }
    }
    if (scanParams.count) {
        [self initializeScanningWithParameters:[scanParams copy]];
        return;
    }
    [self initializeScanningWithParameters:nil];
}

- (void)initializeScanningWithParameters:(NSArray *)params {
    [self stopScan];
    [self.centralManager scanForPeripheralsWithServices:params options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
}

- (void)stopScan {
    [self.centralManager stopScan];
}

- (void)disconnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Trying to cancel peripheral connection");
    if (peripheral) {
        [self.centralManager cancelPeripheralConnection:peripheral];
        NSLog(@"Peripheral connection cancelled");
    }
}

#pragma mark - central manager stack

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    @synchronized(self.activeSubscribers) {
        for (id<CBCentralManagerDelegate>subscriber in self.activeSubscribers) {
            if ([subscriber respondsToSelector:_cmd]) {
                [subscriber centralManagerDidUpdateState:central];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    @synchronized(self.activeSubscribers) {
        for (id<CBCentralManagerDelegate>subscriber in self.activeSubscribers) {
            if ([subscriber respondsToSelector:_cmd]) {
                [subscriber centralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    @synchronized(self.activeSubscribers) {
        for (id<CBCentralManagerDelegate>subscriber in self.activeSubscribers) {
            if ([subscriber respondsToSelector:_cmd]) {
                [subscriber centralManager:central didConnectPeripheral:peripheral];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    @synchronized(self.subscribers) {
        for (id<CBCentralManagerDelegate>subscriber in self.subscribers) {
            if ([subscriber respondsToSelector:_cmd]) {
                [subscriber centralManager:central didDisconnectPeripheral:peripheral error:error];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    @synchronized(self.activeSubscribers) {
        for (id<CBCentralManagerDelegate>subscriber in self.activeSubscribers) {
            if ([subscriber respondsToSelector:_cmd]) {
                [subscriber centralManager:central didFailToConnectPeripheral:peripheral error:error];
            }
        }
    }
}

@end
