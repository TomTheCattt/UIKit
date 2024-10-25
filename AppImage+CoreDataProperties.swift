//
//  AppImage+CoreDataProperties.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 24/10/2024.
//
//

import Foundation
import CoreData


extension AppImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppImage> {
        return NSFetchRequest<AppImage>(entityName: "AppImage")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var filepath: String?
    @NSManaged public var id: UUID?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var title: String?
    @NSManaged public var localIdentifier: String?

}

extension AppImage : Identifiable {

}
