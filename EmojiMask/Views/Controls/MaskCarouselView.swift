import SwiftUI

public struct MaskCarouselView: View {
    @ObservedObject var localization = LocalizationManager.shared
    @Binding var selectedMask: EmojiMaskType
    let onMaskSelected: (EmojiMaskType) -> Void

    public init(
        selectedMask: Binding<EmojiMaskType>,
        onMaskSelected: @escaping (EmojiMaskType) -> Void
    ) {
        self._selectedMask = selectedMask
        self.onMaskSelected = onMaskSelected
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 12) {
                    ForEach(EmojiMaskType.allCases) { mask in
                        let isSelected = (mask == selectedMask)

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedMask = mask
                            onMaskSelected(mask)
                        }) {
                            VStack(spacing: 4) {
                                Text(mask.emoji)
                                    .font(.system(size: 34))
                                    .scaleEffect(isSelected ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                                Text(localization.string(for: mask.localizationKey))
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? Color.emojiGold : Color.white.opacity(0.85))
                                    .lineLimit(1)
                            }
                            .frame(width: 72, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(isSelected ? Color.white.opacity(0.18) : Color.black.opacity(0.35))
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(isSelected ? Color.emojiGold : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                                    )
                            )
                            .shadow(color: isSelected ? Color.emojiGold.opacity(0.4) : Color.clear, radius: 8)
                        }
                        .id(mask)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .onAppear {
                    proxy.scrollTo(selectedMask, anchor: .center)
                }
            }
        }
    }
}
