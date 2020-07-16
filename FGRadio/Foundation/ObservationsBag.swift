//
//  ObservationsBag.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 19.06.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import Foundation

struct ObservationsBag {
    mutating func collect(@Builder _ cancellables: () -> [NSKeyValueObservation]) {
        bag.formUnion(cancellables())
    }

    @_functionBuilder
    struct Builder {
        static func buildBlock(_ cancellables: NSKeyValueObservation...) -> [NSKeyValueObservation] {
            return cancellables
        }
    }
        
    mutating func invalidate() {
        bag.forEach { $0.invalidate() }
        bag.removeAll()
    }
    
    mutating func add(observation: NSKeyValueObservation) {
        bag.insert(observation)
    }
    
    private var bag = Set<NSKeyValueObservation>()
}

extension NSKeyValueObservation {
    func store(in bag: inout ObservationsBag) {
        bag.add(observation: self)
    }
}
