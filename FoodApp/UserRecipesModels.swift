//
//  UserRecipesModels.swift
//  FoodApp
//
//  Created by Emircan Özer on 26.10.2025.
//

import Foundation

struct UserRecipe: Codable, Identifiable, Equatable {
    let id: Int
    let userId: UUID
    let title: String
    let description: String?
    let minutes: Int?
    let ingredients: String?
    let notes: String?
    let isFavorite: Bool
    let isSpicy: Bool
    let cuisine: String?
    let difficulty: String?
    let imageUrl: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case minutes
        case ingredients
        case notes
        case isFavorite = "is_favorite"
        case isSpicy = "is_spicy"
        case cuisine
        case difficulty
        case imageUrl = "image_url"
        case createdAt = "created_at"
    }
}

struct NewUserRecipe: Encodable {
    let userId: UUID
    let title: String
    let description: String?
    let minutes: Int?
    let ingredients: String?
    let notes: String?
    let isFavorite: Bool
    let isSpicy: Bool
    let cuisine: String?
    let difficulty: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case description
        case minutes
        case ingredients
        case notes
        case isFavorite = "is_favorite"
        case isSpicy = "is_spicy"
        case cuisine
        case difficulty
        case imageUrl = "image_url"
    }
}
