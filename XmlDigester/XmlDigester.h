//
// Copyright 2011-2012 James Guistwite
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


#import <Foundation/Foundation.h>
#import "XmlDigesterRule.h"

@interface XmlDigester : NSObject <NSXMLParserDelegate> {

  NSMutableArray *rules;
  NSMutableArray *stack;
  NSString *currentElementPath;
  NSString *lastValue;
  id rootObject;
}

@property (strong)NSMutableArray *rules;
@property (strong)NSMutableArray *stack;
@property (strong)id rootObject;
@property BOOL enableLogging;

- (void)appendRule:(XmlDigesterRule *)newRule;
- (void)fireRuleStartElement:(XmlDigesterRule *)rule:(NSString*)elementName:(NSDictionary*)attributes;
- (void)fireRuleEndElement:(XmlDigesterRule *)rule:(NSString*)elementName;
- (void)push:(id)obj;
- (id)runConverter:(id) obj: (NSString*)converter;

- (id)timeStampConverter:(NSString*) timestampString;
- (id)dateConverter:(NSString*) dateString;
- (void)assignAttributes:(id)obj :(NSDictionary *)attributes;
- (NSString*)trimPrefix:(NSString*)elementName;

- (id)convertKnownValue:(NSString*)value destObject:(id)destObject elementName:(NSString*)elementName;

@end
