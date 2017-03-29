//
//  ViewController.m
//  PokemonCome
//
//  Created by rachel on 3/29/17.
//  Copyright © 2017 rwu. All rights reserved.
//

#import "ViewController.h"

static NSString *const kKeychainItemName = @"Google Sheets API";
static NSString *const kClientID = @"25366958284-kpbntmetdjr2me9poat6v26i03vn2td9.apps.googleusercontent.com";

@implementation ViewController

@synthesize service = _service;
@synthesize output = _output;

// When the view loads, create necessary subviews, and initialize the Google Sheets API service.
- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor yellowColor];

    // Create a UITextView to display output.
    self.output = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.output.editable = false;
    self.output.contentInset = UIEdgeInsetsMake(20.0, 0.0, 20.0, 0.0);
    self.output.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.output];

    // Initialize the Google Sheets API service & load existing credentials from the keychain if available.
    self.service = [[GTLRSheetsService alloc] init];
    self.service.authorizer =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                          clientID:kClientID
                                                      clientSecret:nil];
}

// When the view appears, ensure that the Google Sheets API service is authorized, and perform API calls.
- (void)viewDidAppear:(BOOL)animated {
    if (!self.service.authorizer.canAuthorize) {
        // Not yet authorized, request authorization by pushing the login UI onto the UI stack.
        [self presentViewController:[self createAuthController] animated:YES completion:nil];

    } else {
        [self listMajors];
    }
}

// Display (in the UITextView) the names and majors of students in a sample
// spreadsheet:
// https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit
- (void)listMajors {
    self.output.text = @"Getting sheet data...";
    NSString *spreadsheetId = @"1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms";
    NSString *range = @"Class Data!A2:E";

    GTLRSheetsQuery_SpreadsheetsValuesGet *query =
    [GTLRSheetsQuery_SpreadsheetsValuesGet queryWithSpreadsheetId:spreadsheetId
                                                            range:range];
    [self.service executeQuery:query
                      delegate:self
             didFinishSelector:@selector(displayResultWithTicket:finishedWithObject:error:)];
}

// Process the response and display output
- (void)displayResultWithTicket:(GTLRServiceTicket *)ticket
             finishedWithObject:(GTLRSheets_ValueRange *)result
                          error:(NSError *)error {
    if (error == nil) {
        NSMutableString *output = [[NSMutableString alloc] init];
        NSArray *rows = result.values;
        if (rows.count > 0) {
            [output appendString:@"Name, Major:\n"];
            for (NSArray *row in rows) {
                // Print columns A and E, which correspond to indices 0 and 4.
                [output appendFormat:@"%@, %@\n", row[0], row[4]];
            }
        } else {
            [output appendString:@"No data found."];
        }
        self.output.text = output;
    } else {
        NSMutableString *message = [[NSMutableString alloc] init];
        [message appendFormat:@"Error getting sheet data: %@\n", error.localizedDescription];
        [self showAlert:@"Error" message:message];
    }
}



// Creates the auth controller for authorizing access to Google Sheets API.
- (GTMOAuth2ViewControllerTouch *)createAuthController {
    GTMOAuth2ViewControllerTouch *authController;
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    NSArray *scopes = [NSArray arrayWithObjects:kGTLRAuthScopeSheetsSpreadsheetsReadonly, nil];
    authController = [[GTMOAuth2ViewControllerTouch alloc]
                      initWithScope:[scopes componentsJoinedByString:@" "]
                      clientID:kClientID
                      clientSecret:nil
                      keychainItemName:kKeychainItemName
                      delegate:self
                      finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return authController;
}

// Handle completion of the authorization process, and update the Google Sheets API
// with the new credentials.
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error {
    if (error != nil) {
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
        self.service.authorizer = nil;
    }
    else {
        self.service.authorizer = authResult;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
     {
         [alert dismissViewControllerAnimated:YES completion:nil];
     }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
    
}

@end
