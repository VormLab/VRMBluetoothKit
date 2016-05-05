//
//  ViewController.m
//  VRMBluetoothKit
//
//  Created by Jan Posz on 25.01.2016.
//  Copyright © 2016 Jan Posz. All rights reserved.
//

#import "ConnectionViewController.h"
#import "VRMConnection.h"
#import "VRMAdvertisement.h"
#import "Constants.h"

static NSString *LED_SERVICE_UUID               = @"A000";
static NSString *LED_STATE_CHARACTERISTIC_UUID  = @"A001";
static NSString *LED2_SERVICE_UUID              = @"A002";
static NSString *LED2_STATE_CHARACTERISTIC_UUID = @"A003";

@interface ConnectionViewController ()

@end

@implementation ConnectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)connectTapped:(id)sender {
    [self connect];
}

- (void)connect {
    
    VRMService *s1 = [[VRMService alloc] initWithUUID:[CBUUID UUIDWithString:LED_SERVICE_UUID]];
    VRMService *s2 = [[VRMService alloc] initWithUUID:[CBUUID UUIDWithString:LED2_SERVICE_UUID]];
    
    VRMCharacteristic *ch1 = [[VRMCharacteristic alloc] initWithContainedService:s1 uuid:[CBUUID UUIDWithString:LED_STATE_CHARACTERISTIC_UUID] shouldObserveValue:YES];
    
    VRMCharacteristic *ch2 = [[VRMCharacteristic alloc] initWithContainedService:s2 uuid:[CBUUID UUIDWithString:LED2_STATE_CHARACTERISTIC_UUID] shouldObserveValue:YES];
    
    VRMConfiguration *config = [VRMConfiguration connectionConfigurationWithServices:@[s1,s2] characteristics:@[ch1,ch2] advertisementUUID:LED_SERVICE_UUID];
    
    VRMPeripheral *peripheral = [VRMPeripheral peripheralWithConfiguration:config];
    
    VRMConnection *connection = [[VRMConnection alloc] init];
    connection.enableLogging = true;
    [connection connectDevice:peripheral completionHandler:^(BOOL completed, NSError *error) {
        NSLog(@"jakiś log");
    }];
}



@end
