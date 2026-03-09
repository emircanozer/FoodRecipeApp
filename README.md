# FoodApp

## Türkçe (Turkish)
FoodApp, kullanıcıların diyet tercihlerine, ellerindeki malzemelere veya yemek fotoğraflarına göre yemek tarifleri oluşturmasına ve kaydetmesine yardımcı olan, SwiftUI ile geliştirilmiş bir iOS uygulamasıdır. Kullanıcı girdilerinden ve fotoğraflarından yapay zeka destekli tarifler üretmek için **Google Gemini AI** kullanır. Kullanıcı girişi (Authentication) ve tarif veritabanı (Database) işlemleri için ise **Supabase** altyapısını kullanmaktadır.

### Özellikler
- Malzeme veya yemek fotoğrafı ile yapay zeka destekli tarif oluşturma.
- Vegan, vejetaryen ve glütensiz gibi diyet tercihlerine uygun filtreleme.
- İstenmeyen malzemeleri hariç tutma ve pişirme süresine göre tarif önerme.
- Tariflerin Supabase veritabanına kaydedilmesi ve kullanıcı profili yönetimi.

## English
FoodApp is a SwiftUI-based iOS application that helps users generate and save recipes based on their dietary preferences, available ingredients, or photos of food. It utilizes **Google Gemini AI** to generate AI-powered recipes from user text prompts and images. For user authentication and recipe database management, it integrates with **Supabase**.

### Features
- AI-powered recipe generation using ingredients or food photos.
- Filtering based on dietary preferences such as vegan, vegetarian, and gluten-free.
- Excluding unwanted ingredients and getting recommendations based on prep time.
- Saving generated recipes to a Supabase database and user profile management.

---

### Setup Instructions / Kurulum Talimatları
1. Clone the repository.
2. In order to run the app, you need to provide your own API keys.
3. Create a `Secrets.plist` file in the `FoodApp` folder with the following keys:
   - `GeminiAPIKey` (String)
   - `SupabaseURL` (String)
   - `SupabaseAnonKey` (String)
4. Build and run the project using Xcode.
