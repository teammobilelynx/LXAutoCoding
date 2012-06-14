//
//  LXAutoCodingObject.h
//  ViaggiaTreno iPhone
//
//  Created by Filippo Testini on 14/06/12.
//  Copyright (c) 2012 Lynx S.p.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXAutoCodingObject : NSObject <NSCoding> {
    BOOL dirty;
}

@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

@end
