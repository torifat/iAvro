//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "PreferencesController.h"

@implementation PreferencesController {
    NSPredicate* _searchPredicate;
}

- (void)awakeFromNib {
	[[self window] setContentSize:[_generalView frame].size];
    [[[self window] contentView] addSubview:_generalView];
    [[[self window] contentView] setWantsLayer:YES];
    
    _searchPredicate = [NSPredicate predicateWithFormat:@"(key CONTAINS[c] $searchTerm) OR (value CONTAINS $searchTerm)"];
    
    // Load Credits
    [_aboutContent readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtfd"]];
    [_aboutContent scrollToBeginningOfDocument:_aboutContent];
}

- (NSRect)newFrameForNewContentView:(NSView*)view {
    NSWindow* window = [self window];
    NSRect newFrameRect = [window frameRectForContentRect:[view frame]];
    NSRect oldFrameRect = [window frame];
    NSSize newSize = newFrameRect.size;
    NSSize oldSize = oldFrameRect.size;
    
    NSRect frame = [window frame];
    frame.size = newSize;
    frame.origin.y -= (newSize.height - oldSize.height);
    
    return frame;
}

- (NSView*)viewForTag:(int)tag {
    NSView* view = nil;
    switch (tag) {
        case 0:
            view = _generalView;
            break;
        case 1:
            view = _autoCorrectView;
            break;
        default:
            view = _aboutView;
            break;
    }
    return view;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item {
    if ([item tag] == _currentViewTag) {
        return NO;
    }
    return YES;
}

- (IBAction)switchView:(id)sender {
    int tag = [sender tag];
    NSView* view = [self viewForTag:tag];
    NSView* previousView = [self viewForTag:_currentViewTag];
    _currentViewTag = tag;
    NSRect newFrame = [self newFrameForNewContentView:view];
    
    [NSAnimationContext beginGrouping];
    
    if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
        [[NSAnimationContext currentContext] setDuration:1.0];
    }
    
    [[[[self window] contentView] animator] replaceSubview:previousView with:view];
    [[[self window] animator] setFrame:newFrame display:YES];
    
    [NSAnimationContext endGrouping];
}

- (IBAction)changePredicate:(id)sender {
    NSString *searchTerm = [[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSPredicate *predicate = nil;
    if ([searchTerm length]) {
        NSDictionary* dictionary = @{@"searchTerm" : searchTerm};
        predicate = [_searchPredicate predicateWithSubstitutionVariables:dictionary];
    }
    [_autoCorrectController setFilterPredicate:predicate];
}

@end
