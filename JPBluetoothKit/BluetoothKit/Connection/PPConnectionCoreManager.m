//
//  PPCoreStack.m
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

#import "PPConnectionCoreManager.h"
#import "PPCentralManager.h"
#import "PPErrorBuilder.h"

@interface PPConnectionCoreManager ()

//@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, assign) NSInteger pendingCharacteristicsDiscoverCount;
@property (nonatomic, readwrite, strong) PPConfiguration *configuration;
@property (nonatomic, readwrite, strong) PPPeripheral *connectedPeripheral;

@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) NSTimer *connectionTimer;

@end

@implementation PPConnectionCoreManager

#pragma mark - search initialization

- (void)startConnectionWithPeripheral:(PPPeripheral *)peripheral {
    self.connectedPeripheral = peripheral;
    self.configuration = peripheral.configuration;
    self.pendingCharacteristicsDiscoverCount = 0;
    [self scheduleAsSubscriber];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (CBCentralManagerStatePoweredOn != central.state) {
        NSError *error = [PPErrorBuilder errorForBluetoothCentralState:central.state];
        if (self.bluetoothStateHandler) {
            self.bluetoothStateHandler(error);
        }
    }
    else {
        [[PPCentralManager sharedManager] reloadScan];
    }
}

- (void)scheduleAsSubscriber {
    [[PPCentralManager sharedManager] addSubsriber:self withConfiguration:self.configuration];
}

- (void)resetSubscription {
    [[PPCentralManager sharedManager] removeSubsriber:self withConfiguration:self.configuration];
}

#pragma mark - connection

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if (!self.peripheral) {
        BOOL shouldConnect = NO;
        if (self.onDiscoveryHandler) {
            shouldConnect = self.onDiscoveryHandler(advertisementData, peripheral.identifier.UUIDString);
        }
        if (shouldConnect) {
            ConnectionLog(@"started connection with devcie advertising: %@", advertisementData);
            [self scheduleConnectionTimer];
            self.peripheral = peripheral;
            self.peripheral.delegate = self;
            [[PPCentralManager sharedManager].centralManager connectPeripheral:peripheral options:nil];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self invalidateConnectionTimer];
    ConnectionLog(@"device connected: %@", peripheral);
    if (self.onConnectedHandler) {
        self.onConnectedHandler();
    }
    if (self.configuration.services.count) {
        [self.peripheral discoverServices:[self.configuration rawServices]];
    }
    else {
        [self.peripheral discoverServices:nil];
    }
}

- (void)scheduleConnectionTimer {
    self.connectionTimer = [NSTimer scheduledTimerWithTimeInterval:self.maxConnectionTime target:self selector:@selector(connectionTimeout) userInfo:nil repeats:NO];
//    [self.connectionTimer fire];
}

- (void)invalidateConnectionTimer {
    ConnectionLog(@"Connection timeout.");
    [self.connectionTimer invalidate];
    self.connectionTimer = nil;
}

#pragma mark - discovery

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    ConnectionLog(@"discovered services: %@", peripheral.services);
    BOOL shouldDiscoverCharacteristics = NO;
    if (self.onServicesDiscoveryHandler) {
        shouldDiscoverCharacteristics = self.onServicesDiscoveryHandler(peripheral.services);
    }
    else {
        [self cleanup];
    }
    if (shouldDiscoverCharacteristics) {
        for (CBService *service in peripheral.services) {
            if (self.configuration.characteristics.count) {
                if ([self.configuration configurationContainsService:service]) {
                    NSLog(@"Configuration contains service");
                    PPService *s = [self.configuration mirrorServiceFor:service];
                    s.service = service;
                    self.pendingCharacteristicsDiscoverCount ++;
                    [self.peripheral discoverCharacteristics:[self.configuration characteristicsContainedInService:service.UUID] forService:service];
                }
            }
            else {
                [self.peripheral discoverCharacteristics:nil forService:service];
            }
        }
    }
    else {
        [self cleanup];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    ConnectionLog(@"discovered characteristics: %@", service.characteristics);
    self.pendingCharacteristicsDiscoverCount --;
    BOOL shouldAcceptDevice = NO;
    if (self.onCharacteristicsDiscoveryHandler) {
        shouldAcceptDevice = self.onCharacteristicsDiscoveryHandler(service.characteristics, service);
    }
    if (shouldAcceptDevice) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([self.configuration configurationContainsCharacteristic:characteristic]) {
                PPCharacteristic *ch = [self.configuration mirrorCharacteristicFor:characteristic];
                ch.characteristic = characteristic;
                NSLog(@"Raw characteristic set for: %@", characteristic);
                if (ch.shouldObserveValue) {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
        if (self.pendingCharacteristicsDiscoverCount == 0) {
            [self resetSubscription];
            if (self.onCompleteConnectionHandler) {
                self.onCompleteConnectionHandler(self.peripheral);
            }
        }
    }
    else {
        [self cleanup];
    }
}

#pragma mark - failure handling
#pragma mark - peripheral

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //FIXME: handle failure in subscribing to characteristic
    if (error) {
        ConnectionLog(@"failed subsribing to characteristic: %@ \n error: %@", characteristic, error);
    }
    else {
        ConnectionLog(@"Succesfully subscribed to characteristic");
    }
}

#pragma mark - central

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    ConnectionLog(@"Disconnected");
    [self scheduleAsSubscriber];
    if (self.onDisconnectionHandler) {
        self.onDisconnectionHandler(error);
    }
    [self cleanup];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    ConnectionLog(@"Failed to connect peripheral, trying to reconnect");
    [[PPCentralManager sharedManager] reloadScan];
    [[PPCentralManager sharedManager].centralManager connectPeripheral:peripheral options:nil];
}

#pragma mark - disconnection

- (void)disconnectDevice {
    [[PPCentralManager sharedManager] permanentlyRemoveSubsriber:self withConfiguration:self.configuration];
    [[PPCentralManager sharedManager] disconnectPeripheral:self.peripheral];
    [self cleanup];
}

- (void)connectionTimeout {
    [self.connectionTimer invalidate];
    self.connectionTimer = nil;
    [self cleanup];
    [[PPCentralManager sharedManager] reloadScan];
}

#pragma mark - cleanup after disconnection

- (void)cleanup {
    ConnectionLog(@"Connection failed, cleanup");
    if (self.peripheral.services != nil) {
        for (CBService *service in self.peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if (characteristic.isNotifying) {
                        [self.peripheral setNotifyValue:NO forCharacteristic:characteristic];
                        return;
                    }
                }
            }
        }
    }
    self.peripheral = nil;
}

#pragma mark - dealloc

- (void)dealloc {
    [[PPCentralManager sharedManager] permanentlyRemoveSubsriber:self withConfiguration:self.configuration];
}

@end
