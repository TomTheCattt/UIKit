//
//  AppVideo+CoreDataProperties.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 24/10/2024.
//
//

import Foundation
import CoreData


extension AppVideo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppVideo> {
        return NSFetchRequest<AppVideo>(entityName: "AppVideo")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var duration: Double
    @NSManaged public var filepath: String?
    @NSManaged public var id: UUID?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var title: String?
    @NSManaged public var localIdentifier: String?
}

extension AppVideo : Identifiable {

}
