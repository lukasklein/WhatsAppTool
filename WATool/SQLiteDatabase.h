//
//  SQLiteDatabase.h
//  WATool
//
//  Created by Lukas Klein on 5/30/12.
//  Copyright (c) 2012 LukasKlein.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SQLiteDatabase : NSObject
{
    sqlite3 *database;
}

- (id)initWithPath:(NSString*)path;
- (NSArray *)performQuery:(NSString*)query;

@end
