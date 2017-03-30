//
//  ViewController.h
//  PokemonCome
//
//  Created by rachel on 3/29/17.
//  Copyright © 2017 rwu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLRSheets.h"

@interface ViewController : UIViewController

@property (nonatomic, strong) GTLRSheetsService *service;
@property (nonatomic, strong) UITextView *output;

@end

