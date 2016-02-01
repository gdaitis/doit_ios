//
//  Do_ItViewController.m
//  Do It
//
//  Created by Vytautas on 3/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Do_ItViewController.h"
#import "PointViewController.h"
#import "ASIFormDataRequest.h"
#import "CJSONDeserializer.h"
#import "AddNewViewController.h"
#import "TextEditViewController.h"
#import "MapListViewController.h"
#import "SettingsViewController.h"
#import "LoginViewController.h"
#import "Reachability.h"
#import <dispatch/dispatch.h>

@implementation Do_ItViewController

@synthesize appDelegate, serverUrl, locationManager, mapListViewController, addNewViewController, settings, loginViewController, settingsViewController, internetReachable, connection, mapButton, listButton, addButton, settingsButton, loadingBackground, loadingActivityIndicator;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	self.appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSLog(@"UDID: %@", [[UIDevice currentDevice] uniqueIdentifier]);
    
    self.title = @"";
    self.loadingBackground.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"loading_bg.png"]];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"index_bg.png"]];
    
    // Checking the internet connection
	self.internetReachable = [Reachability reachabilityForInternetConnection];
	[self.internetReachable startNotifier];
	NetworkStatus internetStatus = [self.internetReachable currentReachabilityStatus];
	switch (internetStatus)
	{
		case NotReachable:
		{
			NSLog(@"The internet is down.");
			self.connection = NO;
			break;
		}
		case ReachableViaWiFi:
		{
			NSLog(@"The internet is working via WIFI.");
			self.connection = YES;
			break;
		}
		case ReachableViaWWAN:
		{
			NSLog(@"The internet is working via WWAN.");
			self.connection = YES;
			break;
		}
	}
	
	if (self.connection == NO) 
    {
        self.mapButton.enabled = NO;
        self.mapButton.hidden = NO;
        self.listButton.enabled = NO;
        self.listButton.hidden = NO;
        self.addButton.enabled = NO;
        self.addButton.hidden = NO;
        self.settingsButton.enabled = NO;
        self.settingsButton.hidden = NO;
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" 
														message:@"'Do it' requires internet connection to be enabled. Without it, the application will not work." 
													   delegate:nil 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
        return;
	}
    
    // Setting up the Location Manager to get current coords
    locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	[locationManager startUpdatingLocation];
    
    // Parsing the API server adress
    [self.loadingActivityIndicator startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                   {
                       NSString *urlString = [appDelegate.settings objectForKey:@"first_server"];
                       NSURL *url = [NSURL URLWithString:urlString]; 
                       NSLog(@"%@", urlString);
                       NSString *latitude = [NSString stringWithFormat:@"%g", locationManager.location.coordinate.latitude];
                       NSString *longitude = [NSString stringWithFormat:@"%g", locationManager.location.coordinate.longitude];		
                       
                       ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
                       [request setPostValue:latitude forKey:@"lat"];
                       [request setPostValue:longitude forKey:@"lon"];
                       
                       [request startSynchronous];
                       NSError *error = [request error];
                       if (!error) 
                       {
                           NSData *response = [request responseData];
                           
                           CJSONDeserializer *jsonDeserializer = [CJSONDeserializer deserializer];
                           NSError *error2 = nil;
                           NSDictionary *resultsDictionary = [jsonDeserializer deserializeAsDictionary:response error:&error2];
                           if(!error2)
                           {
                               self.serverUrl = [resultsDictionary objectForKey:@"api_base_url"];
//                               self.serverUrl = [NSString stringWithFormat:@"http://api.letsdoitworld.org/?q=api"]; // <--- TEST
                               NSLog(@"Server URL: %@", serverUrl);
                               dispatch_async(dispatch_get_main_queue(), ^
                                              {
                                                  [UIView beginAnimations:nil context:nil];
                                                  [UIView setAnimationDuration:1.0];
                                                  self.loadingBackground.alpha = 0.0;
                                                  [UIView commitAnimations];
                                                  [self.loadingActivityIndicator stopAnimating];
                                              });
                           }
                           else
                           {
                               NSLog(@"Error2: %@", [error2 localizedDescription]);
                               dispatch_async(dispatch_get_main_queue(), ^
                                              {
                                                  [UIView beginAnimations:nil context:nil];
                                                  [UIView setAnimationDuration:1.0];
                                                  self.loadingBackground.alpha = 0.0;
                                                  [UIView commitAnimations];
                                                  [self.loadingActivityIndicator stopAnimating];
                                                  
                                                  NSLog(@"Error: %@", [error2 localizedDescription]);
                                                  NSString *alertString = [NSString stringWithFormat:@"An error occured: %@", [error2 localizedDescription]];
                                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                                                  message:alertString
                                                                                                 delegate:nil
                                                                                        cancelButtonTitle:@"OK"
                                                                                        otherButtonTitles:nil];
                                                  [alert show];
                                                  [alert release];
                                              });
                           }
                       }
                       else
                       {
                           NSLog(@"Error: %@", [error localizedDescription]);
                           dispatch_async(dispatch_get_main_queue(), ^
                                          {
                                              [UIView beginAnimations:nil context:nil];
                                              [UIView setAnimationDuration:1.0];
                                              self.loadingBackground.alpha = 0.0;
                                              [UIView commitAnimations];
                                              [self.loadingActivityIndicator stopAnimating];
                                              
                                              NSLog(@"Error: %@", [error localizedDescription]);
                                              NSString *alertString = [NSString stringWithFormat:@"An error occured: %@", [error localizedDescription]];
                                              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                                              message:alertString
                                                                                             delegate:nil
                                                                                    cancelButtonTitle:@"OK"
                                                                                    otherButtonTitles:nil];
                                              [alert show];
                                              [alert release];
                                          });
                       }
                   });
    
    // Set up the settings
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"settings.plist"];
    self.settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if ([self.settings count] == 0) 
    {
        self.settings = [NSMutableDictionary dictionary];
        [self.settings setValue:@"1" forKey:@"bbox"];
        [self.settings setValue:@"10" forKey:@"max_results"];
        [self.settings writeToFile:path atomically:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.addNewViewController.textEditViewController.currentField = nil;
    [self.appDelegate.navigationController setNavigationBarHidden:YES];
    self.navigationItem.hidesBackButton = YES;
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark - Buttons

- (IBAction)mapPressed
{
	if (self.mapListViewController == nil)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        [self.loadingActivityIndicator startAnimating];
        self.loadingBackground.alpha = 1.0;
        [UIView commitAnimations];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           self.mapListViewController = [[MapListViewController alloc] init];
                           self.mapListViewController.parent = self;
                           self.mapListViewController.loadViewString = @"map";
                           
                           dispatch_async(dispatch_get_main_queue(), ^
                                          {
                                              [UIView beginAnimations:nil context:nil];
                                              [UIView setAnimationDuration:0.5];
                                              [self.loadingActivityIndicator stopAnimating];
                                              self.loadingBackground.alpha = 0.0;
                                              [UIView commitAnimations];
                                              
                                              [self.appDelegate.navigationController pushViewController:mapListViewController animated:YES];
                                          });
                       });
    }
    else
    {
        [self.mapListViewController.segmentedControl setSelectedSegmentIndex:0];
        [self.appDelegate.navigationController pushViewController:mapListViewController animated:YES];
    }
}

- (IBAction)listPressed
{
	if (self.mapListViewController == nil)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        [self.loadingActivityIndicator startAnimating];
        self.loadingBackground.alpha = 1.0;
        [UIView commitAnimations];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           self.mapListViewController = [[MapListViewController alloc] init];
                           self.mapListViewController.parent = self;
                           self.mapListViewController.loadViewString = @"list";
                           
                           dispatch_async(dispatch_get_main_queue(), ^
                                          {
                                              [UIView beginAnimations:nil context:nil];
                                              [UIView setAnimationDuration:0.5];
                                              [self.loadingActivityIndicator stopAnimating];
                                              self.loadingBackground.alpha = 0.0;
                                              [UIView commitAnimations];
                                              
                                              [self.appDelegate.navigationController pushViewController:mapListViewController animated:YES];
                                          });
                       });
    }
    else
    {
        [self.mapListViewController.segmentedControl setSelectedSegmentIndex:1];
        [self.appDelegate.navigationController pushViewController:mapListViewController animated:YES];
    }
}

- (IBAction)addNew
{
    if (self.loginViewController == nil)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        [self.loadingActivityIndicator startAnimating];
        self.loadingBackground.alpha = 1.0;
        [UIView commitAnimations];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           self.loginViewController = [[LoginViewController alloc] init];
                           self.loginViewController.parent = self;
                           dispatch_async(dispatch_get_main_queue(), ^
                                          {
                                              [UIView beginAnimations:nil context:nil];
                                              [UIView setAnimationDuration:0.5];
                                              [self.loadingActivityIndicator stopAnimating];
                                              self.loadingBackground.alpha = 0.0;
                                              [UIView commitAnimations];
                                              
                                              [self.navigationController presentModalViewController:loginViewController animated:YES];
                                          });
                       });
    }
    else
    {
        if (self.addNewViewController == nil)
        {
            [self.navigationController presentModalViewController:loginViewController animated:YES];
        }
        else
        {
            [self.navigationController pushViewController:self.addNewViewController animated:YES];
        }
    }
}

- (IBAction)settingsPressed
{
    if (self.settingsViewController == nil)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        [self.loadingActivityIndicator startAnimating];
        self.loadingBackground.alpha = 1.0;
        [UIView commitAnimations];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           self.settingsViewController = [[SettingsViewController alloc] init];
                           self.settingsViewController.parent = self;
                           
                           dispatch_async(dispatch_get_main_queue(), ^
                                          {
                                              [UIView beginAnimations:nil context:nil];
                                              [UIView setAnimationDuration:0.5];
                                              [self.loadingActivityIndicator stopAnimating];
                                              self.loadingBackground.alpha = 0.0;
                                              [UIView commitAnimations];
                                              
                                              [self.appDelegate.navigationController pushViewController:settingsViewController animated:YES];
                                          });
                       });
    }
    else
    {
        [self.appDelegate.navigationController pushViewController:settingsViewController animated:YES];
    }
}

#pragma mark - CLLocationManager delegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation 
{
	NSLog(@"Current coordinates: %g %g", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);
}

#pragma mark -

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
//	self.appDelegate = nil;
//    self.serverUrl = nil;
//    self.locationManager = nil;
//    self.mapListViewController = nil;
//    self.addNewViewController = nil;
//    self.settings = nil;
//    self.loginViewController = nil;
//    self.settingsViewController = nil;
//    self.internetReachable = nil;
//    self.mapButton = nil;
//    self.listButton= nil;
//    self.addButton = nil;
//    self.settingsButton = nil;
//    self.loadingBackground = nil;
//    self.loadingActivityIndicator = nil;
}


- (void)dealloc
{
    [super dealloc];
	[appDelegate release];
    [serverUrl release];
    [locationManager release];
    [mapListViewController release];
    [addNewViewController release];
    [settings release];
    [settingsViewController release];
    [loginViewController release];
    [internetReachable release];
    [mapButton release];
    [listButton release];
    [addButton release];
    [settingsButton release];
    [loadingBackground release];
    [loadingActivityIndicator release];
}

@end
