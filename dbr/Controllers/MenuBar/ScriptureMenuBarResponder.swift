//
//  ScriptureMenuBarResponder.swift
//  dbr
//
//  Created by Ray Krow on 10/18/18.
//  Copyright © 2018 Kirk. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class ScriptureMenuBarResponder: MenuBarResponder {
    
    let label: UILabel
    let disposeBag = DisposeBag()
    var index = 0
    var delegate: MenuBarResponderArrowDelegate
    
    init(_ label: UILabel, _ delegate: MenuBarResponderArrowDelegate) {
        self.label = label
        self.delegate = delegate
        
        AppDelegate.global.store!.passage.change
            .subscribe { change in
                guard let newPassage = change.element else { return }
                self.updatePassage(newPassage)
            }.disposed(by: self.disposeBag)
        
    }
    
    func tapUp() {
        showPreviousPassageLabel()
    }
    
    func tapDown() {
        showNextPassageLabel()
    }
    
    func swipeUp() {
        showNextPassageLabel()
        
    }
    
    func swipeDown() {
        showPreviousPassageLabel()
    }
    
}

extension ScriptureMenuBarResponder {
    
    func updatePassage(_ passage: String?) {
        
        // Update Label
        guard let verse = passage else { return }
        label.text = verse
        guard let i = AppDelegate.global.store!.dbr.value?.verses.firstIndex(of: verse) else { return }
        self.index = i

        // Update Arrows
        let canMoveBackwards = index > 0
        let canMoveForwards = index < ((AppDelegate.global.store!.dbr.value?.verses.count ?? 0) - 1)
        self.delegate.setDownArrow(hidden: !canMoveForwards)
        self.delegate.setUpArrow(hidden: !canMoveBackwards)
    }
    
    func showNextPassageLabel() {
        AppDelegate.global.store!.passage.value = AppDelegate.global.store!.dbr.value?.verses[index + 1]
    }
    
    func showPreviousPassageLabel() {
        AppDelegate.global.store!.passage.value = AppDelegate.global.store!.dbr.value?.verses[index - 1]
    }
    
}
