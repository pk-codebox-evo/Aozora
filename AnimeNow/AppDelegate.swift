//
//  AppDelegate.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 4/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import Parse
import Bolts
import ANParseKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Power your app with Local Datastore. For more info, go to
        // https://parse.com/docs/ios_guide#localdatastore/iOS
        
        // Register subclasses
        Anime.registerSubclass()
        SeasonalChart.registerSubclass()
        
        // TODO: Check how to work with this
        Parse.enableLocalDatastore()
        
        // Initialize Parse.
        Parse.setApplicationId("X95vv1iNbXWqoEClbK5XzGvjuydWKQk2Ti2n8OPn",
            clientKey: "vvsbzUBBgnPKCoYQlltREy5S0gSIgMfBp34aDrkc")

        // AnimeTrakr Keys temp
//        Parse.setApplicationId("nLCbHmeklHp6gBly9KHZOZNSMBTyuvknAubwHGAQ",
//            clientKey: "yVixWhPhTM9yGmjtfm1isbC7Ekxq29eNLTzu6KzM")
        
        // Track statistics around application opens.
        // TODO: Uncomment this
        //PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barTintColor = UIColor.midnightBlue()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        UITabBar.appearance().tintColor = UIColor.peterRiver()
        
        UITextField.appearance().textColor = UIColor.whiteColor()

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

