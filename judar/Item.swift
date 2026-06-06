//
//  Item.swift
//  judar
//
//  Created by 4hoe8pow on 2026/06/07.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
