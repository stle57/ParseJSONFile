//
//  main.m
//  ParseJSONFile
//
//  Created by Stephanie Le on 11/25/15.
//  Copyright © 2015 Stephanie Le. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParseJSONFileClass:NSObject
/* method declaration */
- (NSDictionary*)parseJSONData:(NSData*)data;
@end

@implementation ParseJSONFileClass : NSObject 

/* method returning the max between two numbers */
- (NSDate*)dateWithJSONString:(NSString*)stringDate
{
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssz"];

    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    //[dateFormatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]];
    NSDate *date = [[NSDate alloc] init];
    date = [dateFormatter dateFromString:stringDate];
    return date;        
}

//
// Returns a string with the date
//
- (NSString*)getDate:(NSDate*)fullDate {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];


    NSString *theDate = [dateFormat stringFromDate:fullDate];

    return theDate;
}

//
// Convert the values to the correct units
// Converting miles to meters
// Converting minutes to seconds
//
//
- (NSMutableArray*)convertUnits:(NSArray*)data {
    NSMutableArray * newData = [data mutableCopy];

    for (id eachResult in data) {
      double duration = [[eachResult objectForKey:@"duration_in_seconds"] floatValue];
        duration =  duration * 60;
        NSLog(@"new duration value = %f", duration);
        double distance = [[eachResult objectForKey:@"distance_in_meters"] floatValue];
        distance = distance * 1609.34;

        NSDictionary * newResults =
        @{@"energy_in_calories" : eachResult[@"energy_in_calories"],
          @"duration_in_seconds": [[NSNumber numberWithFloat:duration] stringValue],
          @"distance_in_meters": [[NSNumber numberWithFloat:distance] stringValue],
          @"date": eachResult[@"completed_at"]};

        [newData removeObject:eachResult];
        [newData addObject:newResults];

    }

    return newData;
}

//
//  Parse the JSON Data, and find the values that have the same day.
//  Add the information together and return as an array of dictionaries
//
//
- (NSMutableArray*)parseJSONData:(NSData*)data {
    NSMutableArray * results = [[NSMutableArray alloc] init];
    NSError * error;

    if (data != nil) {
    NSMutableDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];

    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        NSString *key = @"activities";

        NSArray *activitiesArray = [dict objectForKey:key];

        if (activitiesArray == nil) {
            return results;
        } else {
           /* [{energy_in_calories: FLOAT, duration_in_seconds: FLOAT, distance_in_meters: FLOAT, completed_at: DATE}, ...]*/

            for ( NSDictionary *data in activitiesArray )
            {
                if ([data[@"equipmentId"] intValue]!= 0) {
                    // Look at date, if date is already in result, then sum the values for each type
                    // and update the result.
                    NSString *theDate = [self getDate:[self dateWithJSONString:data[@"date"]]];

                    // Find in results array the date
                    bool foundData = false;
                    NSArray * copyResults = [results copy];
                    NSDictionary * newResults = [[NSDictionary alloc] init];

                    for (id eachResult in copyResults) {
                        NSString *resultDate = [self getDate:[self dateWithJSONString:[eachResult objectForKey:@"completed_at"]]];
                        if ([resultDate isEqualToString:theDate]) {
                            double sumCalories =[data[@"calorie"] floatValue] + [[eachResult objectForKey:@"energy_in_calories"] floatValue];
                            double sumDistance = ([data[@"distance"] floatValue] + [[eachResult objectForKey:@"distance_in_meters"] floatValue]);
                            double sumDuration = [data[@"duration"] floatValue] + [[eachResult objectForKey:@"duration_in_seconds"] floatValue];

                            newResults =
                                @{@"energy_in_calories" : [[NSNumber numberWithInteger:sumCalories] stringValue],
                                                         @"duration_in_seconds": [[NSNumber numberWithInteger:sumDuration] stringValue],
                                                         @"distance_in_meters": [[NSNumber numberWithInteger:sumDistance] stringValue],
                                                         @"completed_at": data[@"date"]};
                            foundData = true;
                            [results removeObject:eachResult];
                            [results addObject:newResults];
                            break;
                        }
                    }

                    if (!foundData) {
                        NSDictionary * dataToAdd = @{@"energy_in_calories" : [data objectForKey:@"calorie"],
                                                     @"duration_in_seconds": [data objectForKey:@"duration"],
                                                     @"distance_in_meters": [data objectForKey:@"distance"],
                                                     @"completed_at": [data objectForKey:@"date"]};
                        [results addObject:dataToAdd];
                    }
                }
            }
        }

    }
    } else {
        NSLog(@"data is nil");
    }

    NSMutableArray * convertedResults = [self convertUnits:results];

    return convertedResults;
}

@end


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, can you parse this JSON Data?");


        ParseJSONFileClass *jsonParser = [[ParseJSONFileClass alloc] init];
        NSData * jsonData = [[NSData alloc] initWithContentsOfFile:@"/Users/LeFamily/Development/iOS/ParseJSONFile/ParseJSONFile/data.json"];

        NSDictionary * results = [jsonParser parseJSONData:jsonData];
        if ( results != nil) {
            NSLog(@"results = %lu", (unsigned long)results.count);
            NSLog(@"results = %@", results);
        }
    }
    return 0;
}

