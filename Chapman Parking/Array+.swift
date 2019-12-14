//
//  Array+.swift
//  PantherPark
//
//  Created by stephenciauri on 9/30/17.
//  Copyright © 2017 Stephen Ciauri. All rights reserved.
//

import Foundation

public extension Array {
    @discardableResult
    mutating func replaceFirstMatchWith(element: Element, where condition: (Element)->Bool) -> Bool {
        guard let index = firstIndex(where: condition) else {
            return false
        }
        remove(at: index)
        insert(element, at: index)
        return true
    }
}
