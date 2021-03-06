//
//  Store.swift
//  dbr
//
//  Created by Ray Krow on 10/3/18.
//  Copyright © 2018 Kirk. All rights reserved.
//

import Foundation
import RxSwift

enum View {
    case dbr
    case settings
    case scripture
}

class Store {
    
    var date = StoreItem(Date())
    var dbr = StoreItem<DBR?>(nil)
    var menuIsVisible = StoreItem(false)
    var dbrIsLoading = StoreItem(false)
    var view = StoreItem(View.dbr)
    var passage = StoreItem<String?>(nil)
    
}


class StoreItem<T> {
    
    private let _subject: BehaviorSubject<T>
    var change: Observable<T> {
        return self._subject.asObservable()
    }
    
    private var _value: T
    var value: T {
        get {
            return self._value
        }
        set {
            self._value = newValue
            self._subject.onNext(self._value)
        }
    }
    
    init(_ value: T) {
        self._value = value
        self._subject = BehaviorSubject(value: self._value)
    }
    
}
