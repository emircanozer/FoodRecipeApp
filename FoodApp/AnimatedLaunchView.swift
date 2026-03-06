// AnimatedLaunchView.swift

import SwiftUI

struct AnimatedLaunchView: View {
    @Binding var isShowingLaunchAnimation: Bool
    
    // Animasyon Durumları
    @State private var contentVisible = false // İçerik görünürlüğü
    @State private var blobAnimation = false  // Arka plan hareketi
    
    var body: some View {
        ZStack {
            // 1. TATLI & HAREKETLİ ARKA PLAN
            ZStack {
                Color.white.ignoresSafeArea() // Temiz Beyaz Zemin
                
                // Pastel Renk Baloncukları (Sürekli hareket eder)
                // Mor Baloncuk
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: blobAnimation ? 120 : -120, y: blobAnimation ? -80 : 80)
                
                // Mavi Baloncuk
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 350, height: 350)
                    .blur(radius: 70)
                    .offset(x: blobAnimation ? -100 : 100, y: blobAnimation ? 100 : -100)
                
                // Turuncu/Sarı Baloncuk
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(y: blobAnimation ? 150 : 250)
            }
            .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: blobAnimation)
            
            // 2. ANA İÇERİK
            VStack(spacing: 40) {
                Spacer()
                
                // --- LOGO VE İSİM ---
                VStack(spacing: 20) {
                    // Logo (Gölge ve Yuvarlatma ile)
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 140, height: 140)
                            // Renkli, yumuşak gölge (Glow etkisi)
                            .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Image("AppLogo") // Assets'teki
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .clipShape(Circle()) // Tam yuvarlak
                            .overlay {
                                if UIImage(named: "AppLogo") == nil {
                                    Image(systemName: "fork.knife.circle.fill")
                                        .resizable()
                                        .foregroundStyle(
                                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                }
                            }
                    }
                    
                    // İsim - "Rounded" Font
                    Text("Çek Pişir")
                        .font(.system(size: 50, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        // Yazıya hafif gölge
                        .shadow(color: .purple.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                
                Spacer()
                
                // --- ÖZELLİK KARTLARI (YAN YANA) ---
                // Düz ikon yerine minik kartlar kullanıyoruz
                HStack(spacing: 15) {
                    CuteFeatureCard(icon: "brain.head.profile", title: "Yapay Zeka", color: .purple)
                    CuteFeatureCard(icon: "timer", title: "Hızlı Tarif", color: .orange)
                    CuteFeatureCard(icon: "star.fill", title: "Keşfet", color: .yellow)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // --- İMZA (MODERN & TEMİZ) ---
                VStack(spacing: 5) {
                    Text("Created by")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.gray.opacity(0.8))
                    
                    Text("Emircan Özer")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                }
                .padding(.bottom, 50)
            }
            // --- GİRİŞ / ÇIKIŞ EFEKTİ ---
            .scaleEffect(contentVisible ? 1.0 : 0.5) // Büyüyerek gelme (Pop effect)
            .opacity(contentVisible ? 1.0 : 0.0)
        }
        .onAppear {
            // 1. Arka plan hareketi
            blobAnimation = true
            
            // 2. İçerik Girişi (Yaylanan/Bouncy Animasyon)
           
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
                contentVisible = true
            }
            
            // 3. Çıkış (Süre dolunca)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Çıkarken daha yumuşak gitsin
                withAnimation(.easeIn(duration: 0.4)) {
                    contentVisible = false
                }
                
                // 4. Ana Ekrana Geçiş
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isShowingLaunchAnimation = false
                }
            }
        }
    }
}

// --- Tatlı Özellik Kartı ---
struct CuteFeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            // İkonun kendisi
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                // İkonun arkasındaki hafif renkli daire
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            // Başlık
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        // Kartın kendisi (Beyaz kutu + Gölge)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    AnimatedLaunchView(isShowingLaunchAnimation: .constant(true))
}

