//
//  StorageUploadService.swift
//  FoodApp
//
//  Created by Emircan Özer on 26.10.2025.
//

import Foundation
import Supabase

enum StorageUploadService {
    // Bucket adını kendi projenize göre düzenleyin
    static let bucketName = "recipe-images"

    static func uploadRecipeImage(data: Data, userId: UUID, fileExtension: String = "jpg") async throws -> String {
        let supabase = FoodApp.supabase
        let fileName = UUID().uuidString + "." + fileExtension
        let path = "user_recipes/\(userId.uuidString)/\(fileName)"

        // Prepare options using FileOptions (per SDK in Types.swift)
        let options = FileOptions(
            cacheControl: "3600",
            contentType: "image/jpeg",
            upsert: false
        )

        try await supabase.storage
            .from(bucketName)
            .upload(
                path: path,
                file: data,
                options: options
            )

        // Public URL
        let publicURL = try supabase.storage
            .from(bucketName)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }
}
