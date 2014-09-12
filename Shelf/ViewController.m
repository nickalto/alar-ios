//
//  ViewController.m
//  Shelf
//
//  Created by Gregory on 12/10/13.
//  Copyright (c) 2013 Artefact. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end


@implementation ViewController

BOOL bleIsActive;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _ble = [[BLE alloc] init];
    bleIsActive = NO;
    [_ble controlSetup];
    _ble.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    // sharing _ble instance with MapViewController when it loads & it becomes delegate
    // set it back when that controller is dismissed to prevent crash
    _ble.delegate = self;
    
    // TO DO: check for connected state and react accordingly (BLE could disconnect while in other view)
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    /*
    ViewController *mapViewController = [segue destinationViewController];
    mapViewController.ble = _ble;
     */
}

- (void)bleDidDisconnect
{
    NSLog(@"BLE disconnected");
    [btnConnect setTitle:@"Connect to Shelf" forState:UIControlStateNormal];
    [self.ready setText:@""];
}

- (void)bleDidConnect
{
    NSLog(@"BLE connected");
    
    bleIsActive = YES;
    // send reset
    UInt8 buf[] = {0x04, 0x00, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [_ble write:data];
}

- (void)sendBLEData:(unsigned char)command onOrOff:(unsigned char)toggle
{
    typedef struct {
        unsigned char command;
        unsigned char toggle;
    } Header;
    
    Header header;
    header.command = command;
    header.toggle = toggle;
    
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    if (bleIsActive) {
        [_ble write:data];
    }
}


-(IBAction)sendData:(id)sender {
    NSLog(@"sent");
    [self sendBLEData:'a' onOrOff:1];
}

-(void) bleDidReceiveData:(unsigned char *) data length:(int) length {
    NSLog([NSString stringWithFormat:@"DID RECIEVE DATA - %s", data]);
    [self.ready setText:@"READY!"];
}

- (void)connectionTimer:(NSTimer*)timer
{
    [btnConnect setEnabled:true];
    [btnConnect setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    if (_ble.peripherals.count > 0) {
        [_ble connectPeripheral:[_ble.peripherals objectAtIndex:0]];
    } else {
        [btnConnect setTitle:@"Not Found" forState:UIControlStateNormal];
    }
}

- (IBAction)btnScanForPeripherals:(id)sender
{
    NSLog(@"btnScanForPeripherals");
    
    if (_ble.activePeripheral) {
        if (_ble.activePeripheral.state == CBPeripheralStateConnected) {
            [[_ble CM] cancelPeripheralConnection:[_ble activePeripheral]];
            [btnConnect setTitle:@"Connected" forState:UIControlStateNormal];
            return;
        }
    }
    
    if (_ble.peripherals) {
        _ble.peripherals = nil;
    }
    
    [btnConnect setEnabled:false];
    [_ble findBLEPeripherals:2];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
}

@end
