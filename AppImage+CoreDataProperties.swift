//
//  AppImage+CoreDataProperties.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 22/10/2024.
//
//

import Foundation
import CoreData


extension AppImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppImage> {
        return NSFetchRequest<AppImage>(entityName: "AppImage")
    }

    @NSManaged public var filepath: String?
    @NSManaged public var id: UUID?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var title: String?
    @NSManaged public var createdAt: Date?

}

extension AppImage : Identifiable {

}
