//
//  CancelBag.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 05.07.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import Foundation
import Combine

typealias CancelBag = Set<AnyCancellable>

extension CancelBag {
    mutating func collect(@Builder _ cancellables: () -> [AnyCancellable]) {
        formUnion(cancellables())
    }

    @_functionBuilder
    struct Builder {
        static func buildBlock(_ cancellables: AnyCancellable...) -> [AnyCancellable] {
            return cancellables
        }
    }
}

extension CancelBag {
    mutating func cancelAll() {
        forEach { $0.cancel() }
        removeAll()
    }
}
