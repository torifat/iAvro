//
//  IMPreferences.m
//  Avro Keyboard
//
//  Created by GittuBaba on 20/10/17.
//

#import "IMPreferences.h"

@implementation IMPreferences

+ (void)initialize {
    NSString *prefFile = [[NSBundle mainBundle] pathForResource:@"preferences" ofType:@"plist"];
    if (prefFile != nil) {
        NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:prefFile];
        [[NSUserDefaults standardUserDefaults] registerDefaults:prefDict];
        [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:prefDict];
    }
}

- (void)dealloc{
    [_windowController release];
    [super dealloc];
}

- (NSWindowController*)windowController {
    if (_windowController == nil) {
        _windowController = [[NSWindowController alloc] initWithWindowNibName:@"preferences"];
    }
    return _windowController;
}

@end
