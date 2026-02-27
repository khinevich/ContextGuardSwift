//
//  File.swift
//  ContextGuard
//
//  Created by Mikhail Khinevich on 27.02.26.
//

import Foundation

import SwiftUI

struct AppLayout {
    let horizontalPadding: CGFloat
    let iconSize: CGFloat
    let cardSpacing: CGFloat
    let sectionSpacing: CGFloat
    
    /// Compact = iPhone, Regular = iPad
    static func current(for sizeClass: UserInterfaceSizeClass?) -> AppLayout {
        if sizeClass == .compact {
            return AppLayout(
                horizontalPadding: 20,
                iconSize: 40,
                cardSpacing: 12,
                sectionSpacing: 24
            )
        } else {
            return AppLayout(
                horizontalPadding: 40,
                iconSize: 56,
                cardSpacing: 20,
                sectionSpacing: 32
            )
        }
    }
}
