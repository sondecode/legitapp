//
//  DiscoverView.swift
//  LegitApp
//
//  Created by Milán Várady on 2022. 10. 14..
//

import SwiftUI

/// Shows apps in categories
struct DiscoverView: View {
    @EnvironmentObject var caskManager: CaskManager
    @Binding var navigationSelection: SidebarItem
    @State var currentPage: Float = 0

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                // MARK: - Hero Banner
                HerobannerView()
                    .padding(.bottom, 8)

                ForEach(caskManager.categories) { category in
                    DiscoverSectionView(category: category, navigationSelection: $navigationSelection)

                    Divider()
                        .padding(.vertical, 20)
                }
            }
            .padding()
        }

    }
}

// MARK: - Hero Banner
private struct HerobannerView: View {
    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.95),
                    Color(red: 0.96, green: 0.38, blue: 0.24),
                    Color(red: 1.0, green: 0.72, blue: 0.32)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            FivePointStar()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.18).opacity(0.34))
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(-16))
                .offset(x: 360, y: -72)

            FivePointStar()
                .stroke(Color(red: 1.0, green: 0.86, blue: 0.22).opacity(0.42), lineWidth: 12)
                .frame(width: 142, height: 142)
                .rotationEffect(.degrees(12))
                .offset(x: 474, y: 48)

            FivePointStar()
                .fill(Color(red: 1.0, green: 0.86, blue: 0.22).opacity(0.22))
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(20))
                .offset(x: 300, y: 72)

            VStack(alignment: .leading, spacing: 12) {
                Text("Kho ứng dụng Mac dành cho bạn", comment: "Discover hero headline")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(
                    "Khám phá, cài đặt và cập nhật những ứng dụng cần thiết cho công việc, học tập và sáng tạo chỉ trong vài cú nhấp.",
                    comment: "Discover hero subtitle"
                )
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(2)
                .frame(maxWidth: 520, alignment: .leading)

                HStack(spacing: 8) {
                    HeroPill(icon: "sparkles", text: "Ứng dụng tuyển chọn")
                    HeroPill(icon: "keyboard", text: "Bộ gõ tiếng Việt")
                    HeroPill(icon: "brain.head.profile", text: "AI Apps")
                }
            }
            .padding(22)
        }
        .frame(minHeight: 172)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.accentColor.opacity(0.28), radius: 16, x: 0, y: 8)
        .padding(.bottom, 4)
    }
}

private struct FivePointStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.382
        var path = Path()

        for index in 0..<10 {
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = -CGFloat.pi / 2 + CGFloat(index) * CGFloat.pi / 5
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

private struct HeroPill: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.16))
            .clipShape(Capsule())
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(navigationSelection: .constant(.home))
            .environmentObject(CaskManager())
    }
}
