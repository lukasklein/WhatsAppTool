//
//  WATAppDelegate.m
//  WATool
//
//  Created by Lukas Klein on 5/27/12.
//  Copyright (c) 2012 LukasKlein.com. All rights reserved.
//

#import "WATAppDelegate.h"
#import "SQLiteDatabase.h"

@implementation WATAppDelegate
@synthesize backupSelector = _backupSelector;
@synthesize contactView = _contactView;
@synthesize messageView = _messageView;
@synthesize csvButton = _csvButton;

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self reloadBackups];
}

- (NSMutableArray*)getBackups
{
    NSString *homedirectory = NSHomeDirectory();
    NSString *backupdir = [homedirectory stringByAppendingPathComponent:@"Library/Application Support/MobileSync/Backup"];
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSArray *filelist;
    
    NSMutableArray *backups = [NSMutableArray arrayWithCapacity:0];
    
    filelist = [filemgr contentsOfDirectoryAtPath:backupdir error:NULL];
    [filelist enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:[backupdir stringByAppendingPathComponent:[obj stringByAppendingPathComponent:@"Info.plist"]]];
        NSMutableDictionary *backup = [NSMutableDictionary dictionaryWithCapacity:0];
        [backup setValue:[backupdir stringByAppendingPathComponent:obj] forKey:@"backupdir"];
        [backup setValue:[plistDict objectForKey:@"Display Name"] forKey:@"Backup Name"];
        [backup setValue:[plistDict objectForKey:@"Device Name"] forKey:@"Device Name"];
        NSDate *lastBackupDate = [plistDict objectForKey:@"Last Backup Date"];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MMMM d, YYYY HH:mm"];
        [backup setValue:[dateFormat stringFromDate:lastBackupDate] forKey:@"Last Backup Date"];
        [backup setValue:[plistDict objectForKey:@"Product Type"] forKey:@"Product Type"];
        [backup setValue:[plistDict objectForKey:@"Product Version"] forKey:@"Product Version"];
        BOOL hasWhatsAppInstalled = [[[plistDict objectForKey:@"iTunes Settings"] objectForKey:@"LibraryApplications"] containsObject:@"net.whatsapp.WhatsApp"];
        [backup setValue:[NSNumber numberWithBool:hasWhatsAppInstalled] forKey:@"WhatsApp Installed"];
        if([backup objectForKey:@"Backup Name"])
        {
            [backups addObject:backup];
        }
    }];
    return backups;
}

- (void)reloadBackups
{
    [_backupSelector removeAllItems];
    _backups = [self getBackups];
    [_backups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [_backupSelector addItemWithTitle:[NSString stringWithFormat:@"%@ (%@)", [obj objectForKey:@"Device Name"], [obj objectForKey:@"Last Backup Date"]]];
        if(![obj objectForKey:@"WhatsApp Installed"])
        {
            [[_backupSelector lastItem] setEnabled:NO];
        }
        
    }];
    [_backupSelector setAutoenablesItems:NO];
}

- (IBAction)loadChatHistory:(id)sender
{
    [_chatContacts removeAllObjects];
    [_chatContactsNumbers removeAllObjects];
    NSMutableArray *chatContacts = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *chatContactsNumbers = [NSMutableArray arrayWithCapacity:0];
    SQLiteDatabase *database = [[SQLiteDatabase alloc] initWithPath:[[[_backups objectAtIndex:[_backupSelector indexOfSelectedItem]] objectForKey:@"backupdir"] stringByAppendingPathComponent:@"1b6b187a1b60b9ae8b720c79e2c67f472bab09c0"]]; // SHA-1 of AppDomain-net.whatsapp.WhatsApp-Documents/ChatStorage.sqlite
    NSArray *result = [database performQuery:@"SELECT ZFROMJID, ZTEXT, ZMESSAGEDATE FROM ZWAMESSAGE WHERE ZFROMJID<>'' GROUP BY ZFROMJID"];
    for(NSArray *row in result)
    {
        NSString *number = [[[row objectAtIndex:0] componentsSeparatedByString:@"@"] objectAtIndex:0];
        NSString *contact = [self nameByNumber:number];
        [chatContacts addObject:contact];
        [chatContactsNumbers addObject:number];
    }
    _chatContacts = chatContacts;
    _chatContactsNumbers = chatContactsNumbers;
    [_contactView setEnabled:YES];
    [_contactView reloadData];
}

- (IBAction)updateChatHistoryFromIndividual:(id)sender
{
    if([sender selectedRow] > -1)
    {
        [self loadChatHistoryFrom:[_chatContactsNumbers objectAtIndex:[sender selectedRow]]];
    }
}

- (void)loadChatHistoryFrom:(NSString *)number
{
    [_chats removeAllObjects];
    NSMutableArray *chats = [NSMutableArray arrayWithCapacity:0];
    SQLiteDatabase *database = [[SQLiteDatabase alloc] initWithPath:[[[_backups objectAtIndex:[_backupSelector indexOfSelectedItem]] objectForKey:@"backupdir"] stringByAppendingPathComponent:@"1b6b187a1b60b9ae8b720c79e2c67f472bab09c0"]]; // SHA-1 of AppDomain-net.whatsapp.WhatsApp-Documents/ChatStorage.sqlite
    NSArray *result = [database performQuery:[NSString stringWithFormat:@"SELECT ZFROMJID, ZTEXT, ZMESSAGEDATE FROM ZWAMESSAGE WHERE ZFROMJID='%@@s.whatsapp.net' OR ZTOJID='%@@s.whatsapp.net'", number, number]];
    for(NSArray *row in result)
    {
        NSMutableDictionary *chat = [NSMutableDictionary dictionaryWithCapacity:0];
        NSString *number = [row objectAtIndex:0];
        NSString *contact;
        if([row objectAtIndex:0] != [NSNull null])
        {
            number = [[number componentsSeparatedByString:@"@"] objectAtIndex:0];
            contact = [self nameByNumber:number];
        }else{
            contact = @"Me";
        }
        NSString *message = [row objectAtIndex:1];
        NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate: [[row objectAtIndex:2] doubleValue]];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MMMM d, YYYY HH:mm"];
        NSString *dateString = [dateFormat stringFromDate:date];
        [chat setValue:contact forKey:@"Contact"];
        [chat setValue:message forKey:@"Message"];
        [chat setValue:dateString forKey:@"Date"];
        [chats addObject:chat];
    }
    _chats = chats;
    [_messageView setEnabled:YES];
    [_messageView reloadData];
    [_csvButton setEnabled:YES];
}

- (NSString *)nameByNumber:(NSString *)number
{
    SQLiteDatabase *database = [[SQLiteDatabase alloc] initWithPath:[[[_backups objectAtIndex:[_backupSelector indexOfSelectedItem]] objectForKey:@"backupdir"] stringByAppendingPathComponent:@"1b6b187a1b60b9ae8b720c79e2c67f472bab09c0"]]; // SHA-1 of AppDomain-net.whatsapp.WhatsApp-Documents/ChatStorage.sqlite
    NSArray *result = [database performQuery:[NSString stringWithFormat:@"SELECT ZDISPLAYNAME FROM ZWAFAVORITE WHERE ZWHATSAPPID='%@'", number]];
    for(NSArray *row in result)
    {
        return [row objectAtIndex:0];
    }
    return nil;
}

- (IBAction)showHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.lukasklein.com/watool/"]];
}

- (IBAction)exportToCSV:(id)sender
{
    NSSavePanel *save = [NSSavePanel savePanel];
    int result = [save runModal];
    if(result==NSOKButton)
    {
        NSString *selectedFile = [[save URL] path];
        [[NSFileManager defaultManager] createFileAtPath: selectedFile contents:nil attributes:nil];
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:selectedFile];
        NSString *writeString = @"\"Contact\",\"Date\",\"Message\"\n";
        for(int i=0; i<[_chats count]; i++)
        {
            writeString = [writeString stringByAppendingString:[NSString stringWithFormat:@"\"%@\",\"%@\",\"%@\"\n", [[_chats objectAtIndex:i] objectForKey:@"Contact"], [[_chats objectAtIndex:i] objectForKey:@"Date"], [[_chats objectAtIndex:i] objectForKey:@"Message"]]];
        }
        [handle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];

    }
}

- (int) numberOfRowsInTableView:(NSTableView*)tableView
{
    if(tableView==_contactView)
    {
        return [_chatContacts count];
    }else if(tableView==_messageView){
        return [_chats count];
    }else{
        return 0;
    }
}

- (id) tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView==_contactView)
    {
        return [_chatContacts objectAtIndex:row];
    }else if(tableView==_messageView){
        return [[_chats objectAtIndex:row] objectForKey:[tableColumn identifier]];
    }else{
        return nil;
    }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView==_messageView)
    {
        if([[_chats objectAtIndex:row] objectForKey:@"Contact"]==@"Me")
        {
            [cell setBackgroundColor:[NSColor colorWithCalibratedRed:0.929 green:0.953 blue:0.996 alpha:1.0]];
        }else{
            [cell setBackgroundColor:[NSColor whiteColor]];
        }
    }
}

@end
