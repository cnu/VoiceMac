//
//  MGMNumberOptions.m
//  VoiceMac
//
//  Created by Mr. Gecko on 9/6/10.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). http://mrgeckosmedia.com/
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose
//  with or without fee is hereby granted, provided that the above copyright notice
//  and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//  REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT,
//  OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
//  DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
//  ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

#import "MGMNumberOptions.h"
#import "MGMController.h"
#import "MGMVoiceUser.h"
#import "MGMSIPUser.h"
#import <VoiceBase/VoiceBase.h>
#import <MGMUsers/MGMUsers.h>

@implementation MGMNumberOptions
- (id)initWithContactsController:(MGMContactsController *)theContactsController controller:(MGMController *)theController number:(NSString *)theNumber {
	if ((self = [super init])) {
		if (![NSBundle loadNibNamed:@"NumberOptions" owner:self]) {
			NSLog(@"Unable to load the Number Options Window");
			[self release];
			self = nil;
		} else {
			contactsController = theContactsController;
			controller = theController;
			[phoneField setStringValue:[theNumber readableNumber]];
			NSString *name = [[contactsController contacts] nameForNumber:theNumber];
			if (name==nil || [name isEqual:[phoneField stringValue]]) {
				connectionManager = [MGMURLConnectionManager new];
				MGMWhitePagesHandler *handler = [MGMWhitePagesHandler reverseLookup:theNumber delegate:self];
				[connectionManager addHandler:handler];
				[nameField setStringValue:@"Loading..."];
			} else {
				[nameField setStringValue:name];
			}
			if (![contactsController respondsToSelector:@selector(sms:)])
				[smsButton setEnabled:NO];
			
			[self updateAccounts];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAccounts) name:MGMContactsControllersChangedNotification object:nil];
			
			[optionsWindow makeKeyAndOrderFront:self];
		}
	}
	return self;
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[connectionManager release];
	[super dealloc];
}

- (void)updateAccounts {
	NSArray *contactsControllers = [controller contactsControllers];
	NSMenu *accounts = [[NSMenu new] autorelease];
	int currentAccount = -1;
	for (int i=0; i<[contactsControllers count]; i++) {
		NSMenuItem *item = [[NSMenuItem new] autorelease];
		[item setTitle:[[contactsControllers objectAtIndex:i] menuTitle]];
		if ([contactsControllers objectAtIndex:i]==contactsController)
			currentAccount = i;
		if (i<10)
			[item setKeyEquivalent:[[NSNumber numberWithInt:i+1] stringValue]];
		[item setTag:i];
		[item setTarget:self];
		[item setAction:@selector(setAccount:)];
		[accounts addItem:item];
	}
	if (currentAccount==-1) {
		currentAccount = 0;
		contactsController = [[controller contactsControllers] objectAtIndex:currentAccount];
		if (![contactsController respondsToSelector:@selector(sms:)])
			[smsButton setEnabled:NO];
		else
			[smsButton setEnabled:YES];
	}
	[accountPopUp setMenu:accounts];
	[accountPopUp selectItemAtIndex:currentAccount];
}
- (IBAction)setAccount:(id)sender {
	contactsController = [[controller contactsControllers] objectAtIndex:[sender tag]];
	if (![contactsController respondsToSelector:@selector(sms:)])
		[smsButton setEnabled:NO];
	else
		[smsButton setEnabled:YES];
}

- (IBAction)call:(id)sender {
	[contactsController showContactsWindow];
	[[contactsController phoneField] setStringValue:[phoneField stringValue]];
	[contactsController call:sender];
	[self cancel:sender];
}
- (IBAction)sms:(id)sender {
	if ([contactsController respondsToSelector:@selector(sms:)]) {
		[contactsController showContactsWindow];
		[[contactsController phoneField] setStringValue:[phoneField stringValue]];
		[contactsController sms:sender];
		[self cancel:sender];
	}
}
- (IBAction)cancel:(id)sender {
	[connectionManager cancelAll];
	[optionsWindow close];
	[self release];
}

- (void)reverseLookupDidFindInfo:(MGMWhitePagesHandler *)theHandler {
	if ([theHandler name]!=nil) {
		[nameField setStringValue:[theHandler name]];
	} else if ([theHandler location]!=nil) {
		[nameField setStringValue:[theHandler location]];
	}
}
@end