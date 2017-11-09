//
//  ASCFile.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/9/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCFile: Mappable {
    var id: String = ""
    var version: Int = 0
    var contentLength: String?
    var pureContentLength: Int = 0
    var fileStatus: ASCFileStatus = .none
    var viewUrl: String?
    var title: String = ""
    var access: ASCEntityAccess = .none
    var shared: Bool = false
    var rootFolderType: ASCFolderType = .unknown
    var updated: Date?
    var updatedBy: ASCUser?
    var created: Date?
    var createdBy: ASCUser?
    var isNew: Bool = false
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
        version             <- map["version"]
        contentLength       <- map["contentLength"]
        pureContentLength   <- map["pureContentLength"]
        fileStatus          <- (map["fileStatus"], EnumTransform())
        viewUrl             <- map["viewUrl"]
        title               <- (map["title"], ASCStringTransform())
        access              <- (map["access"], EnumTransform())
        shared              <- map["shared"]
        rootFolderType      <- (map["rootFolderType"], EnumTransform())
        updated             <- (map["updated"], ASCDateTransform())
        updatedBy           <- map["updatedBy"]
        created             <- (map["created"], ASCDateTransform())
        createdBy           <- map["createdBy"]
        device              <- map["device"]
        isNew               = fileStatus == .isNew
    }
}
