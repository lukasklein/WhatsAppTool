//
//  SQLiteDatabase.m
//  WATool
//
//  Created by Lukas Klein on 5/30/12.
//  Copyright (c) 2012 LukasKlein.com. All rights reserved.
//

#import "SQLiteDatabase.h"

@implementation SQLiteDatabase

- (id)initWithPath:(NSString *)path
{
    if(self=[super init])
    {
        sqlite3 *dbConnection;
        if(sqlite3_open([path UTF8String], &dbConnection) != SQLITE_OK)
        {
            NSLog(@"[SQLITE] Unable to open database!");
            return nil;
        }
        database = dbConnection;
    }
    return self;
}

- (NSArray *)performQuery:(NSString *)query
{
    sqlite3_stmt *statement = nil;
    const char *sql = [query UTF8String];
    if(sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSLog(@"[SQLITE] Error when preparing query!");
    }else{
        NSMutableArray *result = [NSMutableArray array];
        while(sqlite3_step(statement) == SQLITE_ROW)
        {
            NSMutableArray *row = [NSMutableArray array];
            for (int i=0; i<sqlite3_column_count(statement); i++)
            {
                int colType = sqlite3_column_type(statement, i);
                id value;
                if(colType==SQLITE_TEXT)
                {
                    const unsigned char *col = sqlite3_column_text(statement, i);
                    value = [NSString stringWithFormat:@"%s", col];
                }else if(colType == SQLITE_INTEGER){
                    int col = sqlite3_column_int(statement, i);
                    value = [NSNumber numberWithInt:col];
                }else if(colType == SQLITE_FLOAT) {
                    double col = sqlite3_column_double(statement, i);
                    value = [NSNumber numberWithDouble:col];
                }else if(colType == SQLITE_NULL) {
                    value = [NSNull null];
                }else{
                    NSLog(@"[SQLITE] Unknown datatype");
                }
                [row addObject:value];
            }
            [result addObject:row];
        }
        return result;
    }
    return nil;
}

@end
