/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "ThumbnailsListPanel.h"
#import "ViewerController.h"
#import "AppController.h"
#import "NSWindow+N2.h"
#import "N2Debug.h"
#import "Notifications.h"
#import "ToolbarPanel.h"
#import "NavigatorWindowController.h"

static 	NSMutableDictionary *associatedScreen = nil;
static int increment = 0;
static int MacOSVersion109orHigher = -1;
extern  BOOL USETOOLBARPANEL;

@implementation ThumbnailsListPanel

@synthesize viewer;

+ (long) fixedWidth {

    float w = 0;
    
    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"])
    {
        case -1: w = 100 * 0.8; break;
        case 0: w = 100; break;
        case 1: w = 100 * 1.3; break;
    }
    
    w += 10;
    
    return w;
}

+ (void) checkScreenParameters
{
    for( NSScreen *s in [NSScreen screens])
        [[AppController thumbnailsListPanelForScreen: s] applicationDidChangeScreenParameters: nil];
}

-(void)applicationDidChangeScreenParameters:(NSNotification*)aNotification
{
	if ([[NSScreen screens] count] <= screen)
		return;
	
	NSRect screenRect = [[[NSScreen screens] objectAtIndex:screen] visibleFrame];
	
	NSRect dstframe;
	dstframe.size.height = screenRect.size.height;
	dstframe.size.width = [ThumbnailsListPanel fixedWidth];
	dstframe.origin.x = screenRect.origin.x;
	dstframe.origin.y = screenRect.origin.y;
	
    if( USETOOLBARPANEL)
        dstframe.size.height -= [[AppController toolbarForScreen:[[self window] screen]] exposedHeight];
    
    if( NavigatorWindowController.navigatorWindowController.window.screen == self.window.screen)
    {
        dstframe.origin.y += NavigatorWindowController.navigatorWindowController.window.frame.size.height;
        dstframe.size.height -= NavigatorWindowController.navigatorWindowController.window.frame.size.height;
    }
    
	[[self window] setFrame:dstframe display:YES];
}

- (id)initForScreen: (long) s
{
	screen = s;
	
	if (self = [super initWithWindowNibName:@"ThumbnailsList"])
	{
		thumbnailsView = nil;
		
        [[self window] setAnimationBehavior: NSWindowAnimationBehaviorNone];
        [[self window] setLevel: NSNormalWindowLevel];
        
        [self applicationDidChangeScreenParameters: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:NSApp];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerWillClose:) name: OsirixCloseViewerNotification object: nil];
		
		if( [AppController hasMacOSXSnowLeopard])
			[[self window] setCollectionBehavior: 1 << 6]; //NSWindowCollectionBehaviorIgnoresCycle
		
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:0];
        
        [self.window safelySetMovable:NO];
        
        if( self.window == nil)
            [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"UseFloatingThumbnailsList"];
	}
    
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    
	[thumbnailsView release];
	[super dealloc];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible] && viewer)
            [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible])
		{
			if( [[viewer window] isVisible])
				[[viewer window] makeKeyAndOrderFront: self];
            
            if( viewer && viewer.window.windowNumber > 0)
                [[self window] orderWindow: NSWindowBelow relativeTo: viewer.window.windowNumber];
            else
            {
                [self.window orderOut: self];
            }
		}
	}
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible] && viewer)
            [[self window] orderWindow: NSWindowBelow relativeTo: viewer.window.windowNumber];
	}
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		[[viewer window] makeKeyAndOrderFront: self];
        
		if( [[self window] isVisible] && viewer)
            [[self window] orderWindow: NSWindowBelow relativeTo: viewer.window.windowNumber];
        
		return;
	}
	
	if( [(NSWindow*)[aNotification object] level] != NSNormalWindowLevel)
        return;
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"] == NO)
	{
		[[self window] orderOut:self];
		return;
	}
	
	//[self checkPosition];
	
	if( [[[aNotification object] windowController] isKindOfClass:[ViewerController class]])
	{
		if( [[NSScreen screens] count] > screen)
		{
			if( [[aNotification object] screen] == [[NSScreen screens] objectAtIndex: screen])
			{
				[[viewer window] orderFront: self];
				
				[[self window] orderBack:self];
                
                if( viewer && viewer.window.windowNumber > 0)
                    [[self window] orderWindow: NSWindowBelow relativeTo: viewer.window.windowNumber];
			}
			else
				[self.window orderOut:self];
		}
	}
	
	[[self window] setFrame:[[self window] frame] display:YES];
}

- (void) thumbnailsListWillClose :(NSView*) tb
{
	if( thumbnailsView == tb)
	{
		[[self window] orderOut: self];
		
		if( [[self window] screen])
			[associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: thumbnailsView]];
		else
			[associatedScreen removeObjectForKey: [NSValue valueWithPointer: thumbnailsView]];
		
		[associatedScreen removeObjectForKey: [NSValue valueWithPointer: thumbnailsView]];
		
		[thumbnailsView release];
		thumbnailsView = 0L;
		
        [viewer release];
		viewer = 0L;
	}
}

- (void) viewerWillClose: (NSNotification*) n
{
    if( [n object] == viewer)
    {
        [self setThumbnailsView: nil viewer: nil];
    }
}

- (NSView*) thumbnailsView
{
    return thumbnailsView;
}

- (void) setThumbnailsView:(NSView*) tb viewer:(ViewerController*) v
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"] == NO)
        return;
    
	if( associatedScreen == nil) associatedScreen = [[NSMutableDictionary alloc] init];
	
    NSDisableScreenUpdates();
    
    @try
    {
        if( tb == nil && viewer)
            tb = [[[NSView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)] autorelease];
        
        if( tb == thumbnailsView)
        {
            if( viewer != nil && viewer.window.windowNumber > 0)
                [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
        
            if( thumbnailsView)
            {
                if( [associatedScreen objectForKey: [NSValue valueWithPointer: thumbnailsView]] != [[self window] screen])
                {
                    if( [[self window] screen])
                        [associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: thumbnailsView]];
                    else
                        [associatedScreen removeObjectForKey: [NSValue valueWithPointer: thumbnailsView]];
                }
            }
            else
            {
                if( self.window.isVisible)
                    [self.window orderOut: self];
            }
            
            return;
        }
        
        [viewer release];
        viewer = [v retain];
        
        if( thumbnailsView != tb)
        {
            [superView addSubview: thumbnailsView];
            
            [thumbnailsView release];
            thumbnailsView = [tb retain];
            
            superView = [thumbnailsView superview];
            
            [self.window.contentView addSubview: thumbnailsView];
            [thumbnailsView setHidden: NO];
            [thumbnailsView setFrameSize: thumbnailsView.superview.frame.size];
        }
        
        if( thumbnailsView)
        {
            @try
            {
                if( [associatedScreen objectForKey: [NSValue valueWithPointer: thumbnailsView]] != [[self window] screen])
                {
                    if( [[self window] screen])
                        [associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: thumbnailsView]];
                    else
                        [associatedScreen removeObjectForKey: [NSValue valueWithPointer: thumbnailsView]];
                }
                
                if( [[viewer window] isKeyWindow])
                    [[self window] orderBack: self];
            }
            @catch (NSException *exception) {
                N2LogException( exception);
            }
        }
        else
        {
            if( self.window.isVisible)
                [self.window orderOut: self];
        }
        
        if( thumbnailsView)
        {
            [self applicationDidChangeScreenParameters:nil];
            
            if( [[viewer window] isKeyWindow])
                [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
        }
            
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    @finally {
        NSEnableScreenUpdates();
    }
}

@end
