//
//  File.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import Foundation

enum CheckingState: Equatable {
    case idle
    case analyzing
    case completed
    case failed(String)
}
