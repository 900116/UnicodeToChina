//
//  UnicodeToChina.m
//  UnicodeToChina
//
//  Created by YongCheHui on 15/12/11.
//  Copyright © 2015年 ApesStudio. All rights reserved.
//

#import "UnicodeToChina.h"
#import "RegexKitLite.h"
#import <Cocoa/Cocoa.h>
#import "IDEFoundation.h"
#import <QuartzCore/QuartzCore.h>

@interface UnicodeToChina()
@property (nonatomic, strong) NSBundle *bundle;
@end

@implementation UnicodeToChina

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString *currentApplicationName =
    [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}



- (id)initWithBundle:(NSBundle *)plugin {
    if (!(self = [super init]))
        return nil;
    
    self.bundle = plugin;
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationDidFinishLaunching:)
     name:NSApplicationDidFinishLaunchingNotification
     object:nil];
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self addMenuItemsToMenu];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:NSApplicationDidFinishLaunchingNotification
     object:nil];
}

- (CGImageRef)nsImageToCGImageRef:(NSImage*)image;
{
    NSData * imageData = [image TIFFRepresentation];
    CGImageRef imageRef;
    if(imageData)
    {
        CGImageSourceRef imageSource =
        CGImageSourceCreateWithData(
                                    (CFDataRef)imageData,  NULL);
        
        imageRef = CGImageSourceCreateImageAtIndex(
                                                   imageSource, 0, NULL);
    }
    return imageRef;
}

- (void)addMenuItemsToMenu {
    NSMenu *main = [NSApp mainMenu];
    NSMenuItem *menuItem = [main itemWithTitle:@"Edit"];
    if (!menuItem)
        return;
    
    [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *actionMenuItem =
    [[NSMenuItem alloc] initWithTitle:@"UnicodeToChina"
                               action:@selector(unicodeTochinaAction)
                        keyEquivalent:@""];
    actionMenuItem.target = self;
    [[menuItem submenu] addItem:actionMenuItem];
}

-(NSString *)chinaString:(NSString *)str
{
    NSString *regex = @"\\\\U[a-zA-Z0-9]{4}";
    NSArray *array = [str componentsMatchedByRegex:regex];
    for (NSString * temp in array) {
        NSString* new = [NSString stringWithFormat:@"\"%@\"",temp];
        NSData *tempData = [new dataUsingEncoding:NSUTF8StringEncoding];
        NSString* returnStr = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:NULL error:NULL];
        str = [str stringByReplacingOccurrencesOfString:temp withString:returnStr];
    }
    return str;
}

- (NSWindowController *)windowController {
    return [[NSApp keyWindow] windowController];
}

- (id)currentEditor {
    if ([[self windowController]
         isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController =
        (IDEWorkspaceWindowController *)[self windowController];
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }
    return nil;
}

- (NSTextView *)textView {
    if ([[self currentEditor]
         isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return [[self currentEditor] textView];
    }
    
    if ([[self currentEditor]
         isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        return [[self currentEditor] keyTextView];
    }
    
    return nil;
}

- (BOOL)textViewHasSelection {
    return [[self textView] selectedRange].length > 0;
}


-(void)unicodeTochinaAction
{
    if (![self textViewHasSelection])
        return;
    NSTextView *textView = [self textView];
    NSRange range = [textView rangeForUserTextChange];
    NSString *textString = textView.string;
    NSMutableDictionary *selectS = [NSMutableDictionary new];
    for (NSValue *rangeValue in [textView selectedRanges]) {
        NSString *unicodeToString = [textString substringWithRange:rangeValue.rangeValue];
        [selectS setObject:[self chinaString:unicodeToString] forKey:unicodeToString];
    }
    for (NSString * key in selectS.allKeys) {
        textString =  [textString stringByReplacingOccurrencesOfString:key withString:selectS[key]];
    }
    textView.string = textString;
    [textView scrollRangeToVisible:range];
}
@end
