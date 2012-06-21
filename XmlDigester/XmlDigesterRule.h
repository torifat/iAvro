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

@interface XmlDigesterRule : NSObject {
  NSRegularExpression *elementPathExpression;
}

- (id)initWithRegex:(NSString*)regex;

- (BOOL)matches:(NSString *)path;

@property (strong)NSRegularExpression *elementPathExpression;

@end








@interface XmlDigesterObjectCreationRule : XmlDigesterRule {
  Class objectCreationClass;
  NSString *parentMethodName;
}

- (id)initWithRegex:(NSString*)regex className:(NSString*)came;
- (id)initWithRegex:(NSString*)regex className:(NSString*)came parentMethodName:(NSString*)mname;

@property (strong)Class objectCreationClass;
@property (strong)NSString *parentMethodName;

@end






@interface XmlDigesterPropertiesAssignmentRule : XmlDigesterRule {
}
- (id)initWithRegex:(NSString*)regex;
@end








@interface XmlDigesterPropertyAssignmentRule : XmlDigesterRule {
}

@property (strong)NSString *propertyName;
@property (strong)NSString *converterName;
@property SEL converter;

- (id)initWithRegex:(NSString*)regex propertyName:(NSString*)pname;

- (id)initWithRegex:(NSString*)regex propertyName:(NSString*)pName converter:(NSString*)c;

- (id)initWithRegex:(NSString*)regex propertyName:(NSString*)pName selector:(SEL)sel;

@end





@interface XmlDigesterCallSelectorRule : XmlDigesterRule

- (id)initWithRegex:(NSString*)regex selectorName:(NSString*)selName;

@property (strong)NSString *selectorName;

@end





