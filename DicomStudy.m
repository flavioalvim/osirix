/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

/***************************************** Modifications *********************************************

Version 2.3

	20051229	LP	Fixed bug in paths method. Now accesses completePath.
	20060101	DDP	Changed yearOld to return in the format 5 y or 23 d rather than 5 yo or 23 do,
					as this is more internationally generic.
				
	
****************************************************************************************************/

#import "DicomStudy.h"
#import <OsiriX/DCMAbstractSyntaxUID.h>

@implementation DicomStudy

- (NSString *) localstring
{
	NSManagedObject	*obj = [[[[self valueForKey:@"series"] anyObject] valueForKey:@"images"] anyObject];
	
	BOOL local = [[obj valueForKey:@"inDatabaseFolder"] boolValue];
	BOOL iPod = [[obj valueForKey:@"iPod"] boolValue];
	
	if( local) return @"L";
	else if( iPod) return @"i";
	else return @"";
}


//ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ

- (NSString*) yearOld
{
	if( [self valueForKey: @"dateOfBirth"])
	{
		NSCalendarDate *momsBDay = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[self valueForKey:@"dateOfBirth"] timeIntervalSinceReferenceDate]];
		NSCalendarDate *dateOfBirth = [NSCalendarDate date];
		
		#if __LP64__
		NSInteger years, months, days;
		#else
		int years, months, days;
		#endif
		
		[dateOfBirth years:&years months:&months days:&days hours:NULL minutes:NULL seconds:NULL sinceDate:momsBDay];
		
		if( years < 2)
		{
			if( years < 1)
			{
				if( months < 1) return [NSString stringWithFormat:@"%d d", days];
				else return [NSString stringWithFormat:@"%d m", months];
			}
			else return [NSString stringWithFormat:@"%d y %d m",years, months];
		}
		else return [NSString stringWithFormat:@"%d y", years];
	}
	else return @"";
}


//ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ

- (NSNumber *) noFiles
{
	if( [[self primitiveValueForKey:@"numberOfImages"] intValue] == 0)
	{
		NSSet	*series = [self valueForKey:@"series"];
		NSArray	*array = [series allObjects];
		
		long sum = 0, i;
		
		for( i = 0; i < [array count]; i++)
		{
			sum += [[[array objectAtIndex:i] valueForKey:@"images"] count];
		}
		
		NSNumber	*no = [NSNumber numberWithInt:sum];
		[self setPrimitiveValue:no forKey:@"numberOfImages"];
		return no;
	}
	else return [self primitiveValueForKey:@"numberOfImages"];
}


//ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ

- (NSSet*) paths
{
//	NSLog(@"keyPath: %@", [[self valueForKeyPath:@"series.images.completePath"] description]);
	NSSet *sets = [self valueForKeyPath: @"series.images.completePath"];
	NSEnumerator *enumerator = [sets objectEnumerator];
	NSMutableSet *set = [NSMutableSet set];
//	NSEnumerator *enumerator = [[self primitiveValueForKey:@"series"] objectEnumerator];
	id subset;
	while (subset = [enumerator nextObject])
		[set unionSet: subset];
	return set;
}


//ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ

- (NSSet*) keyImages
{
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *enumerator = [[self primitiveValueForKey: @"series"] objectEnumerator];
	
	id object;
	while (object = [enumerator nextObject])
		[set unionSet:[object keyImages]];
	return set;
}

//ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ------------------------ Series subselections-----------------------------------ΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡΡ


- (NSArray *)imageSeries{
	NSArray *array = [self primitiveValueForKey: @"series"];
	
	NSMutableArray *newArray = [NSMutableArray array];
	NSEnumerator *enumerator = [array objectEnumerator];
	id series;
	while (series = [enumerator nextObject]){
		if ([DCMAbstractSyntaxUID isImageStorage:[series valueForKey:@"seriesSOPClassUID"]] || [series valueForKey:@"seriesSOPClassUID"] == nil)
			[newArray addObject:series];
	}
	return newArray;
}

- (NSArray *)reportSeries{
	NSArray *array = [self primitiveValueForKey: @"series"] ;
	NSMutableArray *newArray = [NSMutableArray array];
	NSEnumerator *enumerator = [array objectEnumerator];
	id series;
	while (series = [enumerator nextObject]){
		if ([DCMAbstractSyntaxUID isStructuredReport:[series valueForKey:@"seriesSOPClassUID"]])
			[newArray addObject:series];
	}
	return newArray;
}

- (NSArray *)structuredReports{
	NSArray *array = [self primitiveValueForKey:@"reportSeries"];
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *enumerator = [array objectEnumerator];
	id series;
	while (series = [enumerator nextObject])
		[set unionSet:[series primitiveValueForKey:@"images"]];
	return [set allObjects];
}

- (NSArray *)keyObjectSeries{
	NSArray *array = [self primitiveValueForKey: @"series"] ;
	NSMutableArray *newArray = [NSMutableArray array];
	NSEnumerator *enumerator = [array objectEnumerator];
	id series;
	while (series = [enumerator nextObject]){
		if ([[DCMAbstractSyntaxUID keyObjectSelectionDocumentStorage] isEqualToString:[series valueForKey:@"seriesSOPClassUID"]])
			[newArray addObject:series];
	}
	return newArray;
}

- (NSArray *)keyObjects{
	NSArray *array = [self keyObjectSeries];
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *enumerator = [array objectEnumerator];
	id series;
	while (series = [enumerator nextObject])
		[set unionSet:[series primitiveValueForKey:@"images"]];
	return [set allObjects];
}

- (NSArray *)presentationStateSeries{
	NSArray *array = [self primitiveValueForKey: @"series"] ;
	NSMutableArray *newArray = [NSMutableArray array];
	NSEnumerator *enumerator = [array objectEnumerator];
	id series;
	while (series = [enumerator nextObject]){
		if ([DCMAbstractSyntaxUID isPresentationState:[series valueForKey:@"seriesSOPClassUID"]])
			[newArray addObject:series];
	}
	return newArray;
}

- (NSArray *)waveFormSeries{
	NSArray *array = [self primitiveValueForKey: @"series"] ;
	NSMutableArray *newArray = [NSMutableArray array];
	NSEnumerator *enumerator = [array objectEnumerator];
	id series;
	while (series = [enumerator nextObject]){
		if ([DCMAbstractSyntaxUID isWaveform:[series valueForKey:@"seriesSOPClassUID"]])
			[newArray addObject:series];
	}
	return newArray;
}

	


@end
