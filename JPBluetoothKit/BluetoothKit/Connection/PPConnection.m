//
//  JPConnection.m
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

#import "PPConnection.h"
#import "PPConnectionCoreManager.h"

static NSString *connectionAllowedKey = @"kCBAdvDataIsConnectable";
static CGFloat defaultMaximumConnectionTime = 5.0;

@interface PPConnection ()

@property (nonatomic, readwrite ,strong) PPPeripheral *connectingPeripheral;
@property (nonatomic, strong) PPConnectionCoreManager *bluetoothCore;
@property (nonatomic, strong) NSMutableArray *scheduledConnections;

@property (nonatomic, copy) void(^handler)(BOOL completed, NSError *error);
@property (nonatomic, copy) void(^stateHandler)(ConnectionState state);

@end

@implementation PPConnection

+ (PPConnection *)defaultConnection {
    
    static PPConnection *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.scheduledConnections = [NSMutableArray new];
    }
    return self;
}

- (PPConnectionCoreManager *)loadDefaultCore {
    
    PPConnectionCoreManager *core = [[PPConnectionCoreManager alloc] init];
    _currentConnectionState = ConnectionStateNone;
    self.shouldRetryAfterDisconnection = YES;
    self.enableLogging = NO;
    self.deviceShouldContainAllConfigurationData = YES;
    self.maximumConnectionTime = defaultMaximumConnectionTime;
    core.maxConnectionTime = defaultMaximumConnectionTime;
    return core;
}

- (void)connectDevice:(PPPeripheral *)peripheral completionHandler:(void (^)(BOOL, NSError *))handler {
    [self connectDevice:peripheral connectionStateHandler:nil completionHandler:handler];
}

- (void)connectDevice:(PPPeripheral *)peripheral connectionStateHandler:(void (^)(ConnectionState))connectionStateHandler completionHandler:(void (^)(BOOL, NSError *))handler {
    
    self.bluetoothCore = [self loadDefaultCore];
    _currentConnectionState = ConnectionStateSearching;
    self.handler = handler;
    self.stateHandler = connectionStateHandler;
    self.connectingPeripheral = peripheral;
    [self.scheduledConnections addObject:self.bluetoothCore];
    [self.bluetoothCore startConnectionWithPeripheral:peripheral];
    [self validateAdvertisementForConnection:self.bluetoothCore];
    [self validateConnectionForConnection:self.bluetoothCore];
    [self validateCharacteristicsForConnection:self.bluetoothCore];
    [self validateServicesForConnection:self.bluetoothCore];
    [self handleCompletionForConnection:self.bluetoothCore];
    [self handleErrorForConnection:self.bluetoothCore];
    [self handleBluetoothStateForConnection:self.bluetoothCore];
}

- (void)disconnectDevice:(PPPeripheral *)device {
    NSLog(@"Disconnected device");
    for (PPConnectionCoreManager *core in self.scheduledConnections) {
        if ([core.connectedPeripheral isEqual:device]) {
            [core disconnectDevice];
        }
    }
}

- (void)setMaximumConnectionTime:(CGFloat)maximumConnectionTime {
    _maximumConnectionTime = maximumConnectionTime;
    for (PPConnectionCoreManager *core in self.scheduledConnections) {
        [core setMaxConnectionTime:maximumConnectionTime];
    }
}

- (void)setShouldRetryAfterDisconnection:(BOOL)shouldRetryAfterDisconnection {
    _shouldRetryAfterDisconnection = shouldRetryAfterDisconnection;
    for (PPConnectionCoreManager *core in self.scheduledConnections) {
        [core setShouldRetryAfterDisconnection:shouldRetryAfterDisconnection];
    }
}

- (void)setEnableLogging:(BOOL)enableLogging {
    _enableLogging = enableLogging;
    for (PPConnectionCoreManager *core in self.scheduledConnections) {
        [core setEnableLogging:enableLogging];
    }
}

#pragma mark - peripheral discovery and connection

- (void)validateAdvertisementForConnection:(PPConnectionCoreManager *)bluetoothCore {
    __weak typeof(self) weakSelf = self;
    __weak typeof(PPConnectionCoreManager) *weakCore = bluetoothCore;
    [bluetoothCore setOnDiscoveryHandler:^BOOL(NSDictionary *adv, NSString *identifier) {
        _currentConnectionState = ConnectionStateSearching;
        if (weakSelf.stateHandler) {
            weakSelf.stateHandler(weakSelf.currentConnectionState);
        }
        if (weakSelf.preconnectionValidationHandler) {
            BOOL shouldConnect = weakSelf.preconnectionValidationHandler(identifier, adv, weakCore.connectedPeripheral);
            return shouldConnect;
        }
        return [weakSelf defaultValidateAdvertisement:adv];
    }];
}

- (BOOL)defaultValidateAdvertisement:(NSDictionary *)adv {
    NSNumber *connectable = [adv objectForKey:connectionAllowedKey];
    if (connectable) {
        if (connectable.boolValue) {
            return YES;
        }
        else {
            return NO;
        }
    }
    return YES;
}

- (void)validateConnectionForConnection:(PPConnectionCoreManager *)bluetoothCore {
    __weak typeof(self) weakSelf = self;
    [bluetoothCore setOnConnectedHandler:^BOOL{
        _currentConnectionState = ConnectionStateConnecting;
        if (weakSelf.stateHandler) {
            weakSelf.stateHandler(weakSelf.currentConnectionState);
        }
        return YES;
    }];
}

#pragma mark - services and characteristics discovery

- (void)validateServicesForConnection:(PPConnectionCoreManager *)bluetoothCore {
    __weak typeof(self) weakSelf = self;
    __weak typeof(PPConnectionCoreManager) *weakCore = bluetoothCore;
    [bluetoothCore setOnServicesDiscoveryHandler:^BOOL(NSArray *services) {
        _currentConnectionState = ConnectionStateValidating;
        if (weakSelf.stateHandler) {
            weakSelf.stateHandler(weakSelf.currentConnectionState);
        }
        BOOL servicesValid = NO;
        if (weakSelf.servicesValidationHandler) {
            servicesValid = weakSelf.servicesValidationHandler(services, weakCore.connectedPeripheral);
        }
        servicesValid = [weakSelf defaultValidateServices:services];
        if (!servicesValid) {
            NSLog(@"Discarding connetion: wrong services");
        }
        return servicesValid;
    }];
}

- (void)validateCharacteristicsForConnection:(PPConnectionCoreManager *)bluetoothCore {
    __weak typeof(self) weakSelf = self;
    __weak typeof(PPConnectionCoreManager) *weakCore = bluetoothCore;
    [bluetoothCore setOnCharacteristicsDiscoveryHandler:^BOOL(NSArray *characteristics, CBService *service) {
        _currentConnectionState = ConnectionStateValidating;
        if (weakSelf.stateHandler) {
            weakSelf.stateHandler(weakSelf.currentConnectionState);
        }
        BOOL characteristicsValid = NO;
        if (weakSelf.characteristicsValidationHandler) {
            characteristicsValid = weakSelf.characteristicsValidationHandler(characteristics, service, weakCore.connectedPeripheral);
        }
        characteristicsValid = [weakSelf defaultValidateCharacteristics:characteristics forService:service];
        if (!characteristicsValid) {
             NSLog(@"Discarding connetion: wrong characteristics");
        }
        return characteristicsValid;
    }];
}

- (BOOL)defaultValidateCharacteristics:(NSArray *)characteristics forService:(CBService *)service {
    NSInteger loopCount = 0;
    NSArray *desried = [self.connectingPeripheral.configuration characteristicsContainedInService:service.UUID];
    for (CBCharacteristic *characteristic in characteristics) {
        if ([self.connectingPeripheral.configuration configurationContainsCharacteristic:characteristic]) {
            loopCount ++;
        }
    }
    if (self.deviceShouldContainAllConfigurationData) {
        if (loopCount == desried.count) {
            return YES;
        }
    }
    else {
        if (loopCount != 0) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)defaultValidateServices:(NSArray *)services {
    NSInteger loopCount = 0;
    for (CBService *service in services) {
        if ([self.connectingPeripheral.configuration configurationContainsService:service]) {
            loopCount ++;
        }
    }
    if (self.deviceShouldContainAllConfigurationData) {
        if (loopCount == self.connectingPeripheral.configuration.services.count) {
            return YES;
        }
    }
    else {
        if (loopCount != 0) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - succesfull connection

- (void)handleCompletionForConnection:(PPConnectionCoreManager *)bluetoothCore {
    __weak typeof(self) weakSelf = self;
    [bluetoothCore setOnCompleteConnectionHandler:^void(CBPeripheral *peripheral) {
        _currentConnectionState = ConnectionStateComplete;
        if (weakSelf.stateHandler) {
            weakSelf.stateHandler(weakSelf.currentConnectionState);
        }
        weakSelf.connectingPeripheral.peripheral = peripheral;
        if (weakSelf.handler) {
            weakSelf.handler(YES, nil);
        }
    }];
}

#pragma mark - error handling

- (void)handleErrorForConnection:(PPConnectionCoreManager *)bluetoothCore {
    __weak typeof(self) weakSelf = self;
    [bluetoothCore setErrorHandler:^(NSError *error) {
        if (error) {
            _currentConnectionState = ConnectionStateError;
            if (weakSelf.stateHandler) {
                weakSelf.stateHandler(weakSelf.currentConnectionState);
            }
            if (weakSelf.handler) {
                weakSelf.handler(NO, error);
            }
        }
    }];
}

- (void)handleBluetoothStateForConnection:(PPConnectionCoreManager *)bluetoothCore {
    __weak typeof(self) weakSelf = self;
    [bluetoothCore setBluetoothStateHandler:^(NSError *error) {
        if (error) {
            _currentConnectionState = ConnectionStateError;
            if (weakSelf.stateHandler) {
                weakSelf.stateHandler(weakSelf.currentConnectionState);
            }
            if (weakSelf.handler) {
                weakSelf.handler(NO, error);
            }
        }
    }];
}

@end
