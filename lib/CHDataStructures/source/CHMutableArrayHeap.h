/*
 CHDataStructures.framework -- CHMutableArrayHeap.h
 
 Copyright (c) 2008-2009, Quinn Taylor <http://homepage.mac.com/quinntaylor>
 
 Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
 
 The software is  provided "as is", without warranty of any kind, including all implied warranties of merchantability and fitness. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.
 */

#import "CHHeap.h"
#import "CHAbstractMutableArrayCollection.h"

/**
 @file CHMutableArrayHeap.h
 A simple CHHeap implemented using an NSMutableArray.
 */

/**
 A simple CHHeap implemented using an NSMutableArray.
 */
@interface CHMutableArrayHeap : CHAbstractMutableArrayCollection <CHHeap>
{
	NSComparisonResult sortOrder;
	unsigned long mutations; /**< Used to track mutations for NSFastEnumeration. */
}

@end