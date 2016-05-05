//
//  ViewController.m
//  JPBluetoothKit
//
//  Created by Jan Posz on 25.01.2016.
//  Copyright © 2016 Jan Posz. All rights reserved.
//

#import "ConnectionViewController.h"
#import "PPConnection.h"
#import "PPAdvertisement.h"
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
    
    PPService *s1 = [[PPService alloc] initWithUUID:[CBUUID UUIDWithString:LED_SERVICE_UUID]];
    PPService *s2 = [[PPService alloc] initWithUUID:[CBUUID UUIDWithString:LED2_SERVICE_UUID]];
    
    PPCharacteristic *ch1 = [[PPCharacteristic alloc] initWithContainedService:s1 uuid:[CBUUID UUIDWithString:LED_STATE_CHARACTERISTIC_UUID] shouldObserveValue:YES];
    
    PPCharacteristic *ch2 = [[PPCharacteristic alloc] initWithContainedService:s2 uuid:[CBUUID UUIDWithString:LED2_STATE_CHARACTERISTIC_UUID] shouldObserveValue:YES];
    
    PPConfiguration *config = [PPConfiguration connectionConfigurationWithServices:@[s1,s2] characteristics:@[ch1,ch2] advertisementUUID:LED_SERVICE_UUID];
    
    PPPeripheral *peripheral = [PPPeripheral peripheralWithConfiguration:config];
    
    PPConnection *connection = [[PPConnection alloc] init];
    connection.enableLogging = true;
    [connection connectDevice:peripheral completionHandler:^(BOOL completed, NSError *error) {
        NSLog(@"jakiś log");
    }];
}



@end
