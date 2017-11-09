//
//  ASCProject.swift
//  Projects
//
//  Created by Alexander Yuzhin on 11/9/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

enum ASCProjectStatysType: Int {
    case open, closed, paused
}

class ASCProject: Mappable {
    var id: String?
    var status: ASCProjectStatysType = .closed
    var title: String?
    var description: String?
    var projectFolder: String?
    var canEdit: Bool = false
    var canDelete: Bool = false
    var security: ASCProjectSecurityInfo?
    var responsible: ASCUser?
    var isPrivate: Bool = false
    var isFollow: Bool = false
    var taskCount: Int = 0
    var taskCountTotal: Int = 0
    var milestoneCount: Int = 0
    var discussionCount: Int = 0
    var participantCount: Int = 0
    var documentsCount: Int = 0
    var timeTrackingTotal: Date?
    var tags: [String] = []
    var updatedBy: ASCUser?
    var created: Date?
    var createdBy: ASCUser?
    var updated: Date?

    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        id                      <- (map["id"], ASCIndexTransform())
        status                  <- (map["status"], EnumTransform())
        title                   <- (map["title"], ASCStringTransform())
        description             <- (map["description"], ASCStringTransform())
        projectFolder           <- (map["projectFolder"], ASCIndexTransform())
        canEdit                 <- map["canEdit"]
        canDelete               <- map["canDelete"]
        security                <- map["security"]
        responsible             <- map["responsible"]
        isPrivate               <- map["isPrivate"]
        isFollow                <- map["isFollow"]
        taskCount               <- map["taskCount"]
        taskCountTotal          <- map["taskCountTotal"]
        milestoneCount          <- map["milestoneCount"]
        discussionCount         <- map["discussionCount"]
        participantCount        <- map["participantCount"]
        documentsCount          <- map["documentsCount"]
        timeTrackingTotal       <- (map["timeTrackingTotal"], ASCDateTransform())
        tags                    <- map["tags"]
        updatedBy               <- map["updatedBy"]
        created                 <- (map["created"], ASCDateTransform())
        createdBy               <- map["createdBy"]
        updated                 <- (map["updated"], ASCDateTransform())
    }
}

class ASCProjectSecurityInfo: Mappable {
    var canCreateMilestone: Bool = false
    var canCreateMessage: Bool = false
    var canCreateTask: Bool = false
    var canCreateTimeSpend: Bool = false
    var canEditTeam: Bool = false
    var canReadFiles: Bool = false
    var canReadMilestones: Bool = false
    var canReadMessages: Bool = false
    var canReadTasks: Bool = false
    var canLinkContact: Bool = false
    var canReadContacts: Bool = false
    var isInTeam: Bool = false
    var canCreateProject: Bool = false

    init() {
        //
    }

    required init?(map: Map) {
        //
    }

    func mapping(map: Map) {
        canCreateMilestone      <- map["canCreateMilestone"]
        canCreateMessage        <- map["canCreateMessage"]
        canCreateTask           <- map["canCreateTask"]
        canCreateTimeSpend      <- map["canCreateTimeSpend"]
        canEditTeam             <- map["canEditTeam"]
        canReadFiles            <- map["canReadFiles"]
        canReadMilestones       <- map["canReadMilestones"]
        canReadMessages         <- map["canReadMessages"]
        canReadTasks            <- map["canReadTasks"]
        canLinkContact          <- map["canLinkContact"]
        canReadContacts         <- map["canReadContacts"]
        isInTeam                <- map["isInTeam"]
        canCreateProject        <- map["canCreateProject"]
    }
}
