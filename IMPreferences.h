//
//  IMPreferences.h
//  Avro Keyboard
//
//  Created by GittuBaba on 20/10/17.
//

#import <Appkit/Appkit.h>

@interface IMPreferences : NSObject {
    NSWindowController *_windowController;
}

+ (void)initialize;
- (void)dealloc;
- (NSWindowController*)windowController;

@end
