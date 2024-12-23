//
//  AppMedia+CoreDataProperties.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 01/11/2024.
//
//

import Foundation
import CoreData


extension AppMedia {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppMedia> {
        return NSFetchRequest<AppMedia>(entityName: "AppMedia")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var duration: Double
    @NSManaged public var id: UUID?
    @NSManaged public var localIdentifier: String?
    @NSManaged public var mediaType: String?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var title: String?

}

extension AppMedia : Identifiable {

}
