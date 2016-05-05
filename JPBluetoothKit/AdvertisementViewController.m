//
//  AdvertisementViewController.m
//  JPBluetoothKit
//
//  Created by Jan Posz on 05.02.2016.
//  Copyright © 2016 Jan Posz. All rights reserved.
//

#import "AdvertisementViewController.h"
#import "VRMAdvertisement.h"

@interface AdvertisementViewController () <UITextFieldDelegate>

@property (nonatomic, strong) VRMAdvertisement *advertisement;
@property (nonatomic, strong) VRMCharacteristic *characteristic;

@end

@implementation AdvertisementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startAdvertising];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)]];
}

- (void)startAdvertising {
    
    VRMService *s1 = [[VRMService alloc] initWithUUID:[CBUUID UUIDWithString:serviceUUID]];
    
    self.characteristic = [[VRMCharacteristic alloc] initWithContainedService:s1 uuid:[CBUUID UUIDWithString:characteristicUUID] properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    NSDictionary *advertisment = @{
                              //     CBAdvertisementDataServiceUUIDsKey : @[serviceUUID],
                                   CBAdvertisementDataLocalNameKey: @"TEST3"
                                   };
    
    VRMConfiguration *configuration = [VRMConfiguration adverisementConfigurationWithServices:@[s1] characteristics:@[self.characteristic] advertisingPacket:advertisment];
    self.advertisement = [[VRMAdvertisement alloc] init];
    [self.advertisement advertisePerpheralWithConfiguration:configuration];
}

- (void)updateValue:(NSString *)value {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    [self.advertisement updateValue:data onCharacteristic:self.characteristic];
}

#pragma mark - text field


- (void)hideKeyboard {
    [self.view endEditing:true];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateValue:textField.text];
}

@end
