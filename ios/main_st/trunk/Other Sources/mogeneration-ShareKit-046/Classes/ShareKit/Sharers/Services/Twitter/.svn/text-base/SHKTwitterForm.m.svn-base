//
//  SHKTwitterForm.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/22/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKTwitterForm.h"
#import "SHK.h"
#import "SHKTwitter.h"


@implementation SHKTwitterForm

@synthesize delegate;
@synthesize textView;
@synthesize counter;
@synthesize hasAttachment;
@synthesize submitButton;

- (void)dealloc 
{
	[delegate release];
	[textView release];
    [submitButton release];
	[counter release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{		
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							  target:self
																							  action:@selector(cancel)] autorelease];

        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Logout" 
                                                                                  style:UIBarButtonSystemItemCancel 
                                                                                 target:self 
                                                                                 action:@selector(logoutAction)] autorelease];
        self.navigationItem.title = @"Twitter";
    }
    return self;
}
- (UIImage *)buttonImage
{
    return [UIImage imageNamed:@"shk_bluebtn.png"];
}
- (void)logoutAction
{
    [SHKTwitter logout];
    [self performSelector:@selector(cancel)];
    [self autorelease];
    [SHKTwitter shareItem:[delegate item]];
}

#define SubmitButtonWidth 120.0f
#define SubmitButtonTopMargin 30.0f

- (void)loadView 
{
	[super loadView];
    self.view.backgroundColor = [UIColor blackColor];	
	textView = [[UITextView alloc] initWithFrame:self.view.bounds];
	textView.delegate = self;
	textView.font = [UIFont systemFontOfSize:15];
	textView.contentInset = UIEdgeInsetsMake(5,5,0,0);
	textView.backgroundColor = [UIColor whiteColor];	
	textView.autoresizesSubviews = YES;
	textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.layer.cornerRadius = 4.0f;
	[self.view addSubview:textView];
    
    UIImage *image = [self buttonImage];
    image = [image stretchableImageWithLeftCapWidth:(image.size.width/2)+1 topCapHeight:(image.size.height/2)+1];
    self.submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [submitButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setBackgroundImage:image forState:UIControlStateNormal];
    [submitButton setTitle:@"Submit" forState:UIControlStateNormal];
    submitButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    [self.view addSubview:submitButton];
}


- (void)viewWillAppear:(BOOL)animated 
{
    textView.frame = CGRectInset(CGRectMake(0, 30.0f, self.view.bounds.size.width, 160.0f), 20.0f, 20.0f);
    // submitButton.frame = CGRectMake(CGRectGetMaxX(textView.frame)-SubmitButtonWidth, CGRectGetMaxY(textView.frame)+SubmitButtonTopMargin, SubmitButtonWidth, 40.0f);
    submitButton.frame = CGRectMake(CGRectGetMinX(textView.frame), CGRectGetMinY(textView.frame)-42.0f, SubmitButtonWidth, 40.0f);
}
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];	
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
	
	[self.textView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];	
	
	// Remove observers
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name: UIKeyboardWillShowNotification object:nil];
	
	// Remove the SHK view wrapper from the window
	[[SHK currentHelper] viewWasDismissed];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

//#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)keyboardWillShow:(NSNotification *)notification
{	
//	CGRect keyboardFrame;
//	CGFloat keyboardHeight;
	
	// 3.2 and above
	/*if (UIKeyboardFrameEndUserInfoKey)
	 {		
	 [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];		
	 if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait || [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) 
	 keyboardHeight = keyboardFrame.size.height;
	 else
	 keyboardHeight = keyboardFrame.size.width;
	 }
	 
	 // < 3.2
	 else 
	 {*/

//	[[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];
//	keyboardHeight = keyboardFrame.size.height;
	//}
	
	// Find the bottom of the screen (accounting for keyboard overlay)
	// This is pretty much only for pagesheet's on the iPad
//	UIInterfaceOrientation orient = [[UIApplication sharedApplication] statusBarOrientation];
//	BOOL inLandscape = orient == UIInterfaceOrientationLandscapeLeft || orient == UIInterfaceOrientationLandscapeRight;
//	BOOL upsideDown = orient == UIInterfaceOrientationPortraitUpsideDown || orient == UIInterfaceOrientationLandscapeRight;
//	
//	CGPoint topOfViewPoint = [self.view convertPoint:CGPointZero toView:nil];
//	CGFloat topOfView = inLandscape ? topOfViewPoint.x : topOfViewPoint.y;
//	
//	CGFloat screenHeight = inLandscape ? [[UIScreen mainScreen] applicationFrame].size.width : [[UIScreen mainScreen] applicationFrame].size.height;
	
    //CGFloat distFromBottom = screenHeight - ((upsideDown ? screenHeight - topOfView : topOfView ) + self.view.bounds.size.height) + ([UIApplication sharedApplication].statusBarHidden || upsideDown ? 0 : 20);							
	//CGFloat maxViewHeight = self.view.bounds.size.height - keyboardHeight + distFromBottom;
	
	[self layoutCounter];

}
//#pragma GCC diagnostic pop  

#pragma mark -

- (void)updateCounter
{
	if (counter == nil)
	{
		self.counter = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
		counter.backgroundColor = [UIColor clearColor];
		counter.opaque = NO;
		counter.font = [UIFont systemFontOfSize:14];
		counter.textAlignment = UITextAlignmentRight;
		
		counter.autoresizesSubviews = YES;
		counter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		
		[self.view addSubview:counter];
		[self layoutCounter];
		
		[counter release];
	}
	
	int count = (hasAttachment?115:140) - textView.text.length;
	counter.text = [NSString stringWithFormat:@"Characters: %@%i/140", hasAttachment ? @"Image + ":@"" , count];
	counter.textColor = count >= 0 ? [UIColor whiteColor] : [UIColor redColor];
}

- (void)layoutCounter
{
	counter.frame = CGRectMake(textView.bounds.size.width-187,
							   textView.frame.origin.y-20,
							   200,
							   15);
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	[self updateCounter];
}

- (void)textViewDidChange:(UITextView *)textView
{
	[self updateCounter];	
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[self updateCounter];
}

#pragma mark -

- (void)cancel
{	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	[(SHKTwitter *)delegate sendDidCancel];
}

- (void)save
{	
	if (textView.text.length > (hasAttachment?115:140))
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is too long")
									 message:SHKLocalizedString(@"Twitter posts can only be 140 characters in length.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	else if (textView.text.length == 0)
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is empty")
									 message:SHKLocalizedString(@"You must enter a message in order to post.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	[(SHKTwitter *)delegate sendForm:self];
	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

@end
