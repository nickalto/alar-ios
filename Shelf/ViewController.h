//
//  ViewController.h
//  Shelf
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface ViewController : UIViewController <BLEDelegate>
{
    IBOutlet UIButton *btnConnect;
}

@property (strong,nonatomic) BLE *ble;
@property (weak, nonatomic) IBOutlet UILabel *sentData;
@property (weak, nonatomic) IBOutlet UIButton *btn;


@end
