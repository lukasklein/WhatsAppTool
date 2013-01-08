//
//  WATAppDelegate.h
//  WATool
//
//  Created by Lukas Klein on 5/27/12.
//  Copyright (c) 2012 LukasKlein.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WATAppDelegate : NSObject <NSApplicationDelegate>
{
    NSMutableArray *_backups;
    NSMutableArray *_chatContacts;
    NSMutableArray *_chatContactsNumbers;
    NSMutableArray *_chats;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSPopUpButton *backupSelector;
@property (assign) IBOutlet NSTableView *contactView;
@property (assign) IBOutlet NSTableView *messageView;
@property (assign) IBOutlet NSButton *csvButton;

- (NSMutableArray*)getBackups;
- (void)reloadBackups;
- (int) numberOfRowsInTableView:(NSTableView*)tableView;
- (id) tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (IBAction)loadChatHistory:(id)sender;
- (NSString *)nameByNumber:(NSString *)number;
- (void)loadChatHistoryFrom:(NSString *)number;
- (IBAction)updateChatHistoryFromIndividual:(id)sender;
- (IBAction)exportToCSV:(id)sender;
- (IBAction)showHelp:(id)sender;


@end
