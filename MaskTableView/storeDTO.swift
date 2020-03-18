//
//  storeDTO.swift
//  MaskTableView
//
//  Created by Seunghun Shin on 2020/03/11.
//  Copyright © 2020 SeunghunShin. All rights reserved.
//

import Foundation
import ObjectMapper

class Mask: Mappable {
    required init?(map: Map) {
        
    }
    func mapping(map: Map) {
        count <- map["count"]
        stores <- map["stores"]
    }
    var count: Int?
    var stores: [Stores]?
    
    class Stores: Mappable {
        required init?(map: Map) {
            
        }
        func mapping(map: Map) {
            addr <- map["addr"]
            code <- map["code"]
            created_at <- map["created_at"]
            lat <- map["lat"]
            lng <- map["lng"]
            name <- map["name"]
            remain_stat <- map["remain_stat"]
            stock_at <- map["stock_at"]
            type <- map["type"]
        }
        var addr: String?
        var code: String?
        var created_at: String?
        var lat: Double?
        var lng: Double?
        var name: String?
        var remain_stat: String?
        var stock_at: String?
        var type: String?
    }
}
