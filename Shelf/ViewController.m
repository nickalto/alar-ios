//
//  ViewController.m
//  Shelf
//

#import "ViewController.h"

@interface ViewController ()

@end


@implementation ViewController

BOOL bleIsActive;
BOOL bleTimeSet = false;
BOOL bleGMTSet = false;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _ble = [[BLE alloc] init];
    bleIsActive = NO;
    bleTimeSet = NO;
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
    [self.sentData setText:@""];
}

- (void)bleDidConnect
{
    NSLog(@"BLE connected");
    
    bleIsActive = YES;
    // send reset
    UInt8 buf[] = {0x04, 0x00, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [_ble write:data];
    [self sendBLEGMTOffset];
    [self sendBLETime];
}

- (void)sendBLEGMTOffset
{
    typedef struct {
        unsigned char command[6];
        unsigned char toggle;
    } Header;
    
    Header header;
    header.toggle = 1;
    
    NSInteger secondsFromGMT = [[NSTimeZone localTimeZone] secondsFromGMT];
    int hoursFromGmt = ( secondsFromGMT / 60 ) / 60;
    
    
    // Arduino expects value as TxxxxxxxT to delimit time value
    NSString *timeString = [NSString stringWithFormat:@"G%dG", hoursFromGmt];
    
    for( int i = 0; i < timeString.length; i++ ) {
        header.command[i] = [timeString characterAtIndex:i];
    }
    
    NSLog(@"%s", header.command);
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    if (bleIsActive) {
        [_ble write:data];
    }
}


- (void)sendBLETime
{
    typedef struct {
        unsigned char command[12];
        unsigned char toggle;
    } Header;
    
    Header header;
    header.toggle = 1;
    
    //
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss dd MM yyyy"];
    
    NSTimeZone *gmt = [NSTimeZone systemTimeZone];
    [dateFormatter setTimeZone:gmt];
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    NSDate *curdate = [dateFormatter dateFromString:timeStamp];
    NSInteger secondsFromGMT = [[NSTimeZone localTimeZone] secondsFromGMT];
    int unix_timestamp =  [curdate timeIntervalSince1970];
    int hoursFromGmt = ( secondsFromGMT / 60 ) / 60;
    

    // Arduino expects value as TxxxxxxxT to delimit time value
    NSString *timeString = [NSString stringWithFormat:@"T%dT", unix_timestamp];
    
    for( int i = 0; i < timeString.length; i++ ) {
        header.command[i] = [timeString characterAtIndex:i];
    }
    
    NSLog(@"%s", header.command);
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    if (bleIsActive) {
        [_ble write:data];
    }
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

//    [self sendBLEData:'a' onOrOff:1];
}

-(void) bleDidReceiveData:(unsigned char *) data length:(int) length {
    NSLog([NSString stringWithFormat:@"DID RECIEVE DATA - %s", data]);
    
    if([[NSString stringWithFormat:@"%s", data] isEqualToString:@"GMTSET"]) {
        bleGMTSet = true;
        NSLog(@"GMT WAS SUCESSFULLY SET!");
    }
    
    if([[NSString stringWithFormat:@"%s", data] isEqualToString:@"TIMESET"]) {
        bleTimeSet = true;
        NSLog(@"TIME WAS SUCESSFULLY SET!");
    }
    [self.sentData setText:[NSString stringWithFormat:@"%s", data]];
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

-(void)bleConnect {
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

- (IBAction)btnScanForPeripherals:(id)sender
{
    [self bleConnect];
}

@end
