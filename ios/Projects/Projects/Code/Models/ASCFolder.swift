//
//  ASCFolder.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/9/17.
//  Copyright (c) 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCFolder: Mappable {
    var id: String = ""
    var parentId: String?
    var filesCount: Int = 0
    var foldersCount: Int = 0
    var isShareable: Bool = false
    var title: String = ""
    var access: ASCEntityAccess = .none
    var shared: Bool = false
    var rootFolderType: ASCFolderType = .unknown
    var updated:Date?
    var updatedBy: ASCUser?
    var created:Date?
    var createdBy: ASCUser?
    var isNew: Bool = false
    var isThirdParty: Bool = false
    var providerType: String?
    var device: Bool = false
    var parent: ASCFolder? = nil

    init() {
        //
    }
    
    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        id                  <- (map["id"], ASCIndexTransform())
        parentId            <- (map["parentId"], ASCIndexTransform())
        filesCount          <- map["filesCount"]
        foldersCount        <- map["foldersCount"]
        isShareable         <- map["isShareable"]
        title               <- (map["title"], ASCStringTransform())
        access              <- (map["access"], EnumTransform())
        shared              <- map["shared"]
        rootFolderType      <- (map["rootFolderType"], EnumTransform())
        updated             <- (map["updated"], ASCDateTransform())
        updatedBy           <- map["updatedBy"]
        created             <- (map["created"], ASCDateTransform())
        createdBy           <- map["createdBy"]
        isNew               <- map["isNew"]
        isThirdParty        <- map["providerItem"]
        providerType        <- map["providerKey"]
    }
}
