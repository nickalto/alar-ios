//
//  ViewController.h
//  Shelf
//
//  Created by Gregory on 12/10/13.
//  Copyright (c) 2013 Artefact. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface ViewController : UIViewController <BLEDelegate>
{
    IBOutlet UIButton *btnConnect;
}

@property (strong,nonatomic) BLE *ble;
@property (weak, nonatomic) IBOutlet UILabel *ready;


@end
