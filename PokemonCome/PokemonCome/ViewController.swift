//
//  ViewController.swift
//  PokemonCome
//
//  Created by rachel on 3/26/17.
//  Copyright © 2017 rwu. All rights reserved.
//

import GoogleAPIClientForREST
import GTMOAuth2
import UIKit

class ViewController: UIViewController {

    private let kKeychainItemName = "Pokemon Come"
    private let kClientID = "25366958284-kpbntmetdjr2me9poat6v26i03vn2td9.apps.googleusercontent.com"

    private let scope = [kGTLRAuthScopeSheetsSpreadsheetsReadonly]

    private let service = GTLRSheetsService()
    let output = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        output.frame = view.bounds
        output.editable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]

        view.addSubview(output)

        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(
            kKeychainItemName,
            clientID: kClientID,
            clientSecret: nil) {
            service.authorizer = auth
        }
    }

    override func viewDidAppear(animated: Bool) {
        if let authorizer = service.authorizer, let canAuth = authorizer.canAuthorize, canAuth {
            listMajors()
        } else {
            presentViewController(
                createAuthController(),
                animated: true,
                completion: nil
            )
        }
    }

    func listMajors() {
        output.text = "Getting sheet data..."
        let spreadsheetId = "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
        let range = "Class Data!A2:E"
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .queryWithSpreadsheetId(spreadsheetId, range:range)
        service.executeQuery(query,
                             delegate: self,
                             didFinishSelector: "displayResultWithTicket:finishedWithObject:error:"
        )
    }

    // Process the response and display output
    func displayResultWithTicket(ticket: GTLRServiceTicket,
                                 finishedWithObject result : GTLRSheets_ValueRange,
                                 error : NSError?) {

        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }

        var majorsString = ""
        let rows = result.values!

        if rows.isEmpty {
            output.text = "No data found."
            return
        }

        majorsString += "Name, Major:\n"
        for row in rows {
            let name = row[0]
            let major = row[4]
            
            majorsString += "\(name), \(major)\n"
        }
        
        output.text = majorsString
    }

    // Creates the auth controller for authorizing access to Google Sheets API
    private func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joinWithSeparator(" ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: nil,
            keychainItemName: kKeychainItemName,
            delegate: self,
            finishedSelector: "viewController:finishedWithAuth:error:"
        )
    }

    // Handle completion of the authorization process, and update the Google Sheets API
    // with the new credentials.
    func viewController(vc : UIViewController,
                        finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {

        if let error = error {
            service.authorizer = nil
            showAlert("Authentication Error", message: error.localizedDescription)
            return
        }

        service.authorizer = authResult
        dismissViewControllerAnimated(true, completion: nil)
    }

    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.Default,
            handler: nil
        )
        alert.addAction(ok)
        presentViewController(alert, animated: true, completion: nil)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

