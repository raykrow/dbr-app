//
//  MainViewController.swift
//  dbr
//
//  Created by Ray Krow on 10/2/18.
//  Copyright © 2018 Kirk. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxGesture

class MainViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let disposeBag = DisposeBag()
    var dbrView: UIView?
    
    var dbrViewLeadingAnchor: NSLayoutConstraint?
    var dbrViewTrailingAnchor: NSLayoutConstraint?
    var menuViewLeadingAnchor: NSLayoutConstraint?
    var settingsViewLeadingAnchor: NSLayoutConstraint?
    var settingsViewTrailingAnchor: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard
            let dbrController = UIViewController.initWithStoryboard(DailyBibleReadingViewController.self),
            let menuBarController = UIViewController.initWithStoryboard(MenuBarViewController.self),
            let settingsController = UIViewController.initWithStoryboard(SettingsViewController.self)
        else {
            fatalError()
        }
        
        self.addChildViewController(dbrController)
        self.addChildViewController(menuBarController)
        self.addChildViewController(settingsController)
        
        // Order is important here - dbr view must get added
        // last so it sits on top of the menu
        self.view.addSubview(menuBarController.view)
        self.view.addSubview(dbrController.view)
        self.view.addSubview(settingsController.view)
        
        
        //
        //  Place the Menu Bar
        //
        menuBarController.view.translatesAutoresizingMaskIntoConstraints = false
        menuBarController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        menuBarController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        let menuWidthConstraint = menuBarController.view.widthAnchor.constraint(equalToConstant: UIConstants.menuWidth)
        menuWidthConstraint.priority = UILayoutPriority(999) // Makes annoying warning go away
        menuWidthConstraint.isActive = true
        self.menuViewLeadingAnchor = menuBarController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0) // UIConstants.menuWidth * -1)
        self.menuViewLeadingAnchor?.isActive = true
        
        
        //
        //  Place the DBR view
        //
        dbrView = dbrController.view
        dbrView?.translatesAutoresizingMaskIntoConstraints = false
        dbrView?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        dbrView?.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.dbrViewLeadingAnchor = dbrView?.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        self.dbrViewTrailingAnchor = dbrView?.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        self.dbrViewLeadingAnchor?.isActive = true
        self.dbrViewTrailingAnchor?.isActive = true
        
        
        //
        // Place the Settings view
        //
        let settingsView = settingsController.view
        settingsView?.translatesAutoresizingMaskIntoConstraints = false
        settingsView?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        settingsView?.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.settingsViewLeadingAnchor = settingsView?.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        self.settingsViewTrailingAnchor = settingsView?.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        
        settingsView?.backgroundColor = .green
        
        
        //
        // Setup listeners for events
        //
        AppDelegate.global.store?.menuIsVisible.change.subscribe { menuIsVisible in
            if menuIsVisible.element! { self.showMenu() }
            else { self.hideMenu() }
        }.disposed(by: disposeBag)
        
        let panGesture = menuBarController.view.rx.panGesture()
        
        panGesture.when(.ended)
            .asTranslation()
            .subscribe(onNext: self.onMenuBarPanEnd)
            .disposed(by: self.disposeBag)
        
        panGesture.when(.changed)
            .asTranslation()
            .subscribe(onNext: self.onMenuBarPanChange)
            .disposed(by: self.disposeBag)
        
    }
    
    func showMenu() {
        
        self.dbrViewLeadingAnchor?.constant = UIConstants.menuWidth
        self.dbrViewTrailingAnchor?.constant = UIConstants.menuWidth
        // self.menuViewLeadingAnchor?.constant = 0
        
        animateMenuMove()
        
        // Create a view and add it over the top of
        // the area where the dbr view is now sitting
        let coverView = UIView()
        coverView.tag = 2932
        self.view.addSubview(coverView)
        
        // Position cover view over the dbr section
        coverView.translatesAutoresizingMaskIntoConstraints = false
        coverView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        coverView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        coverView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        coverView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: UIConstants.menuWidth).isActive = true
        
        // Add a swipe gesture recognizer to the cover view
        // so we know when user trys to close view
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleCloseSwipe(gestureRecognizer:)))
        gestureRecognizer.direction = .left
        gestureRecognizer.delegate = self
        coverView.addGestureRecognizer(gestureRecognizer)
        
    }
    
    @objc func handleCloseSwipe(gestureRecognizer: UIGestureRecognizer) {
        AppDelegate.global.store?.menuIsVisible.value = false
    }
    
    func hideMenu() {
        if let coverView = self.view.viewWithTag(2932) {
            coverView.removeFromSuperview()
        }
        // Move the dbr view over
        self.dbrViewLeadingAnchor?.constant = 0
        self.dbrViewTrailingAnchor?.constant = 0
        // self.menuViewLeadingAnchor?.constant = UIConstants.menuWidth * -1
        
        animateMenuMove()
    }
    
    func animateMenuMove() {
        UIViewPropertyAnimator(duration: 0.2, curve: .linear, animations: {
            self.view.layoutIfNeeded()
        }).startAnimation()
    }
    
//    @objc func didSwipeOnView(_ sender: Any) {
//        let xChange: CGFloat = panGesture!.getXAxisChange(self.view)
//        guard xChange != 0 else { return }
//        let currentMenuXPosition = self.view.frame.midX
//        let halfWayMark = UIScreen.main.bounds.midX
//        if currentMenuXPosition >= halfWayMark {
//
//        }
//        print("CHANGED: \(xChange)")
//        if panGesture!.state == .cancelled {
//            print("FINAL")
//        }
//    }
    
    func onMenuBarPanChange(_ translation: CGPoint, _ velocity: CGPoint) -> Void {
        print("...")
        // Move the views to match the current translated position
    }
    
    func onMenuBarPanEnd(_ translation: CGPoint, _ velocity: CGPoint) -> Void {
        print("ENDED")
        // Decide if the view is currenly closer to
        // open or close and then snap it to that side
    }
    
    func slideMenuToSetting() -> Void {
        
    }
    
    func slideMenuToDBR() -> Void {
        
    }
    
    func slideView(toX x: CGFloat) -> Void {
        
    }
    
}
