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

#import "XmlDigesterRule.h"


@implementation XmlDigesterRule

@synthesize elementPathExpression;


- (id)initWithRegex:(NSString*)regex {
  if ((self = [super init])) {
    NSError *error = NULL;
    self.elementPathExpression = [NSRegularExpression regularExpressionWithPattern:regex
                                                             options:NSRegularExpressionCaseInsensitive
                                                                  error:&error];
  }
  return self;
}

- (BOOL)matches:(NSString *)path {
  BOOL rv = FALSE;
  
  if (elementPathExpression != nil) {
    NSUInteger numberOfMatches = [elementPathExpression numberOfMatchesInString:path
                                                        options:0
                                                        range:NSMakeRange(0, [path length])];
    rv = numberOfMatches != 0;
  }
  
  return rv;
}

@end














@implementation XmlDigesterPropertiesAssignmentRule


- (id)initWithRegex:(NSString*)regex {
  if ((self = [super initWithRegex:regex])) {
  }
  return self;
}



@end









@implementation XmlDigesterPropertyAssignmentRule

@synthesize propertyName;
@synthesize converterName;
@synthesize converter;

- (id)initWithRegex:(NSString *)regex propertyName:(NSString *)pname {
  if ((self = [super initWithRegex:regex])) {
    self.propertyName = pname;
  }
  return self;
}  


- (id)initWithRegex:(NSString *)regex propertyName:(NSString *)pname converter:(NSString *)c {
if ((self = [self initWithRegex:regex propertyName:pname])) {
    self.converterName = c;
  }
  return self;
}


- (id)initWithRegex:(NSString *)regex propertyName:(NSString *)pName selector:(SEL)sel {
  if ((self = [self initWithRegex:regex propertyName:pName])) {
    self.converter = sel;
  }
  return self;
}



@end








@implementation XmlDigesterObjectCreationRule

@synthesize objectCreationClass = _objectCreationClass;
@synthesize parentMethodName = _parentMethodName;

- (id)initWithRegex:(NSString *)regex className:(NSString *)cname {
  if ((self = [self initWithRegex:regex])) {
    self.objectCreationClass = NSClassFromString(cname);
  }
  return self;
}  
  
  
- (id)initWithRegex:(NSString *)regex className:(NSString *)cname parentMethodName:(NSString *)mname {
  if ((self = [self initWithRegex:regex className:cname])) {
    self.parentMethodName = mname;
  }
  return self;
}  


@end







@implementation XmlDigesterCallSelectorRule

@synthesize selectorName;

- (id)initWithRegex:(NSString *)regex selectorName:(NSString *)selName {
  if ((self = [self initWithRegex:regex])) {
    self.selectorName = selName;
  }
  return self;
}  


@end

