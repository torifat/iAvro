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

#import "XmlDigester.h"
#import "XmlDigesterRule.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation XmlDigester

@synthesize rules, stack, rootObject, enableLogging;

- (id)init {
  if ((self = [super init])) {
    rules = [[NSMutableArray alloc] init];
    stack = [[NSMutableArray alloc] init];
    currentElementPath = @"";
    enableLogging = false;
  }
  return self;
}

- (void)appendRule:(XmlDigesterRule*)newRule {
  [rules addObject:newRule];
}

- (XmlDigesterRule *)findRule:(NSString *)path {
  XmlDigesterRule *rv = nil;
  
  for (XmlDigesterRule *rule in rules) {
    if ([rule matches:path]) {
      rv = rule;
      break;
    }
  }
  
  return rv;
}

- (void)push:(id)obj {
  [stack insertObject:obj atIndex:0];
  if ([stack count] == 1) {
    rootObject = obj;
  }
  if (enableLogging) {
    NSLog(@"stack is now %@", stack);
  }
}


- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString *)str {
  //NSLog(@"found characters %@", str);
  lastValue = [NSString stringWithString:str];
}


- (NSString*)trimPrefix:(NSString*)elementName {
  NSString *eName;
  NSArray *comp = [elementName componentsSeparatedByString:@":"];
  if ([comp count] == 1) {
    eName = elementName;
  }
  else {
    eName = [comp objectAtIndex:1];
  }
  return eName;
}

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString *)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributeDict {
  if (enableLogging) {
    NSLog(@"start element %@", elementName);
  }
  NSString *eName = [self trimPrefix: elementName];
  currentElementPath = [currentElementPath stringByAppendingPathComponent:eName];
  if (enableLogging) {
    NSLog(@"path is now %@", currentElementPath);
  }
  
  BOOL matchFound = false;
  for (XmlDigesterRule *rule in rules) {
    if ([rule matches:currentElementPath]) {
      [self fireRuleStartElement:rule :elementName :attributeDict];
      matchFound = true;
      break;
    }
  }
  if (!matchFound) {
    if (enableLogging) {
      NSLog(@"warning - no match for path %@", currentElementPath);
      for (XmlDigesterRule *rule in rules) {
        NSLog(@"rule regex %@ status is %d", [rule elementPathExpression], [rule matches:currentElementPath]);
      }
    }
  }
}



- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
  if (enableLogging) {
    NSLog(@"end element %@", elementName);
  }
  NSString *eName = [self trimPrefix: elementName];
  
  for (XmlDigesterRule *rule in rules) {
    if ([rule matches:currentElementPath]) {
      [self fireRuleEndElement:rule :eName];
      break;
    }
  }
  
  currentElementPath = [currentElementPath stringByDeletingLastPathComponent];
  if (enableLogging) {
    NSLog(@"path is now %@", currentElementPath);
  }
}  



- (void)fireRuleStartElement:(XmlDigesterRule *)rule:(NSString*)elementName:(NSDictionary*)attributes {
  
  if ( [rule isKindOfClass: [XmlDigesterPropertiesAssignmentRule class]] ) {
  }
  else if ( [rule isKindOfClass: [XmlDigesterCallSelectorRule class]] ) {
    XmlDigesterCallSelectorRule *r = (XmlDigesterCallSelectorRule*)rule;
    if (enableLogging) {
      NSLog(@"call selector %@", r.selectorName);
    }
    id top = [stack objectAtIndex:0];
    SEL selector = NSSelectorFromString(r.selectorName);
    objc_msgSend(top, selector, attributes);
    //[top performSelector:selector withObject:attributes];
  }
  else if ( [rule isKindOfClass: [XmlDigesterObjectCreationRule class]] ) {
    XmlDigesterObjectCreationRule *r = (XmlDigesterObjectCreationRule*)rule;
    if (enableLogging) {
      NSLog(@"create instance of %@", r.objectCreationClass);
    }
    id obj = [[r.objectCreationClass alloc] init];
    
    // are there any attributes that I can assign?
    [self assignAttributes :obj :attributes];
    
    
    if (r.parentMethodName != nil) {
      id top = [stack objectAtIndex:0];
      SEL selector = NSSelectorFromString(r.parentMethodName);
      if (enableLogging) {
        NSLog(@"calling method %@ on %@ for %@", r.parentMethodName, top, obj);
      }
      objc_msgSend(top, selector, obj);
      //[top performSelector:selector withObject:obj];
    }
    if (enableLogging) {
      NSLog(@"created and pushing object %@", obj);
    }
    [self push:obj];
  }
  else if ( [rule isKindOfClass: [XmlDigesterPropertyAssignmentRule class]] ) {
    XmlDigesterPropertyAssignmentRule *r = (XmlDigesterPropertyAssignmentRule*)rule;
    NSString *nm = r.propertyName;
    if (nm == nil) {
      nm = elementName;
    }
  }
  
}

- (void)assignAttributes:(id) obj:(NSDictionary*)attributes {
  Class objectClass = [obj class];
  [attributes enumerateKeysAndObjectsUsingBlock:^(id attributeName, id attributeValue, BOOL *stop) {
    if (enableLogging) {
      NSLog(@"process attribute %@ = %@", attributeName, attributeValue);
    }
    NSString *propertyName = [NSString stringWithFormat:@"%@", attributeName];
    objc_property_t theProperty = class_getProperty(objectClass, [propertyName UTF8String]);
    if (theProperty) {
      id val = [self convertKnownValue:(NSString *)attributeValue destObject:obj elementName:attributeName];
      [obj setValue:val forKey:propertyName];
      if (enableLogging) {
        NSLog(@"set to %@", [obj valueForKey:propertyName]);
      }
    }
    
	}];
}

- (void)fireRuleEndElement:(XmlDigesterRule *)rule:(NSString*)elementName {
  if ( [rule isKindOfClass: [XmlDigesterObjectCreationRule class]] ) {
    //XmlDigesterObjectCreationRule *r = (XmlDigesterObjectCreationRule*)rule;
    if (enableLogging) {
      NSLog(@"pop object from stack %@", [stack objectAtIndex:0]);
    }
    [stack removeObjectAtIndex:0];
  }
  else if ( [rule isKindOfClass: [XmlDigesterPropertyAssignmentRule class]] ) {
    XmlDigesterPropertyAssignmentRule *r = (XmlDigesterPropertyAssignmentRule*)rule;
    id obj = [stack objectAtIndex:0];
    NSString *nm = r.propertyName;
    if (nm == nil) {
      nm = elementName;
    }
    
    @try {
      if (r.converterName != nil) {
        id tmp = [self runConverter:lastValue: r.converterName];
        [obj setValue:tmp forKey:nm];
      }
      else if (r.converter != nil) {
        id tmp = objc_msgSend(self, r.converter, lastValue);
        //id tmp = [self performSelector:r.converter withObject:lastValue];
        [obj setValue:tmp forKey:nm];
      }
      else {
        id val = [self convertKnownValue:(NSString *)lastValue destObject:obj elementName:nm];
        [obj setValue:val forKey:nm];
      }
    }
    @catch (NSException *e) {
      if ([[e name] isEqualToString:NSUndefinedKeyException]) {
        //if (enableLogging) {
        NSLog(@"Property: %@ does not recognize the property \"%@\"", obj, nm);
        //}
      }
    }
  }
  else if ( [rule isKindOfClass: [XmlDigesterPropertiesAssignmentRule class]] ) {
    //XmlDigesterPropertiesAssignmentRule *r = (XmlDigesterPropertiesAssignmentRule*)rule;
    id obj = [stack objectAtIndex:0];
    @try {
      id val = [self convertKnownValue:(NSString *)lastValue destObject:obj elementName:elementName];
      [obj setValue:val forKey:elementName];
      //[obj setValue:lastValue forKey:elementName];
    }
    @catch (NSException *e) {
      if ([[e name] isEqualToString:NSUndefinedKeyException]) {
        //if (enableLogging) {
        NSLog(@"Properties: %@ does not recognize the property \"%@\"", obj, elementName);
        //}
      }
    }
  }
  
}

- (id)convertKnownValue:(NSString*)value destObject:(id)destObject elementName:(NSString *)nm {
  
  id rv = value;
  
  NSString *pname = [NSString stringWithFormat:@"%@%@", [[nm substringToIndex:1] lowercaseString], [nm substringFromIndex:1]];
  Class objectClass = [destObject class];
  objc_property_t theProperty = class_getProperty(objectClass, [pname UTF8String]);
  if (theProperty) {
    const char * propertyAttrs = property_getAttributes(theProperty);
    NSString *pa = [NSString stringWithCString:propertyAttrs encoding:NSStringEncodingConversionAllowLossy];
    if (enableLogging) {
      NSLog(@"data type: %@", pa);
    }
    if ([pa hasPrefix:@"T@\"NSDate\""]) {
      rv = [self timeStampConverter:(NSString*)value];
    }
    else if ([pa hasPrefix:@"Ti"]) {
      NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
      [f setNumberStyle:NSNumberFormatterDecimalStyle];
      rv = [f numberFromString:value];
    }
    else if ([pa hasPrefix:@"Tl"]) {
      NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
      [f setNumberStyle:NSNumberFormatterDecimalStyle];
      rv = [f numberFromString:value];
    }
    else if ([pa hasPrefix:@"Tc"]) {
      // handle true/false in the event the field is a boolean
      if ([value isEqualToString:@"true"]) {
        rv = [NSNumber numberWithBool:true];
      }
      else if ([value isEqualToString:@"false"]) {
        rv = [NSNumber numberWithBool:false];
      }
      else {
        rv = [NSNumber numberWithChar:[value characterAtIndex:0]];
      }
    }
    
  }
  return rv;
}


- (id)runConverter:(id) obj: (NSString*)converter {
  id rv = obj;
  
  if ([@"timestamp" isEqual:converter]) {
    rv = [self timeStampConverter:(NSString*)obj];
  }
  else if ([@"date" isEqual:converter]) {
    rv = [self dateConverter:(NSString*)obj];
  }
  
  return rv;
}

- (id)timeStampConverter:(NSString*) s {
  NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
  [f setNumberStyle:NSNumberFormatterDecimalStyle];
  NSNumber * myNumber = [f numberFromString:s];
  if (myNumber) {
    double d = [myNumber doubleValue];
    d = d / 1000.0;
    NSDate *rv = [NSDate dateWithTimeIntervalSince1970:d];
    return rv;
  }
  else {
    if (s.length > 20) {
      s = [s stringByReplacingOccurrencesOfString:@":"
                                       withString:@""
                                          options:0
                                            range:NSMakeRange(20, s.length-20)];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *rv = [dateFormatter dateFromString:s];
    return rv;
  }
}

- (id)dateConverter:(NSString*) s {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd"];
  NSDate *rv = [dateFormatter dateFromString:s];
  return rv;
}




@end
