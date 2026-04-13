import SwiftUI
import UIKit

struct ConversationComposerEntryRowView: View {
    @Binding var showAttachMenu: Bool
    @Binding var inputText: String
    @Binding var isComposerFocused: Bool
    let voiceManager: VoiceTranscriptionManager
    let isTurnActive: Bool
    let hasAttachment: Bool
    let onPasteImage: (UIImage) -> Void
    let onSendText: () -> Void
    let onStopRecording: () -> Void
    let onStartRecording: () -> Void
    let onInterrupt: () -> Void

    init(
        showAttachMenu: Binding<Bool>,
        inputText: Binding<String>,
        isComposerFocused: Binding<Bool>,
        voiceManager: VoiceTranscriptionManager,
        isTurnActive: Bool,
        hasAttachment: Bool,
        onPasteImage: @escaping (UIImage) -> Void,
        onSendText: @escaping () -> Void,
        onStopRecording: @escaping () -> Void,
        onStartRecording: @escaping () -> Void,
        onInterrupt: @escaping () -> Void
    ) {
        _showAttachMenu = showAttachMenu
        _inputText = inputText
        _isComposerFocused = isComposerFocused
        self.voiceManager = voiceManager
        self.isTurnActive = isTurnActive
        self.hasAttachment = hasAttachment
        self.onPasteImage = onPasteImage
        self.onSendText = onSendText
        self.onStopRecording = onStopRecording
        self.onStartRecording = onStartRecording
        self.onInterrupt = onInterrupt
    }

    private var hasText: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canSend: Bool {
        hasText || hasAttachment
    }

    private var composerCornerRadius: CGFloat {
        LitterTheme.usesRemodexChrome ? 18 : 20
    }

    private var composerButtonSize: CGFloat {
        LitterTheme.usesRemodexChrome ? 34 : 36
    }

    private var composerGlyphSize: CGFloat {
        LitterTheme.usesRemodexChrome ? 16 : 17
    }

    private var textPointSize: CGFloat {
        LitterTheme.usesRemodexChrome ? 16 : 17
    }

    var body: some View {
        HStack(alignment: .center, spacing: LitterTheme.usesRemodexChrome ? 10 : 8) {
            if !voiceManager.isRecording && !voiceManager.isTranscribing && !isTurnActive {
                Button {
                    showAttachMenu = true
                } label: {
                    Image(systemName: "plus")
                        .font(LitterFont.styled(size: composerGlyphSize, weight: .semibold))
                        .foregroundColor(LitterTheme.textPrimary)
                        .frame(width: composerButtonSize, height: composerButtonSize)
                        .modifier(GlassCircleModifier())
                }
                .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    ConversationComposerTextView(
                        text: $inputText,
                        isFocused: $isComposerFocused,
                        onPasteImage: onPasteImage
                    )

                    if inputText.isEmpty {
                        Text("Message litter...")
                            .font(LitterFont.styled(size: textPointSize, weight: LitterTheme.usesRemodexChrome ? .medium : .regular))
                            .foregroundColor(LitterTheme.textMuted)
                            .padding(.leading, 16)
                            .padding(.top, LitterTheme.usesRemodexChrome ? 11 : 10)
                            .allowsHitTesting(false)
                    }
                }

                if canSend {
                    Button(action: onSendText) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(LitterFont.styled(size: LitterTheme.usesRemodexChrome ? 21 : 22))
                            .foregroundColor(LitterTheme.accent)
                            .frame(width: composerButtonSize, height: composerButtonSize)
                            .contentShape(Rectangle())
                    }
                    .padding(.trailing, 4)
                } else if voiceManager.isRecording {
                    AudioWaveformView(level: voiceManager.audioLevel)
                        .frame(width: 48, height: 20)

                    Button(action: onStopRecording) {
                        Image(systemName: "stop.circle.fill")
                            .font(LitterFont.styled(size: LitterTheme.usesRemodexChrome ? 21 : 22))
                            .foregroundColor(LitterTheme.accentStrong)
                            .frame(width: composerButtonSize, height: composerButtonSize)
                            .contentShape(Rectangle())
                    }
                    .padding(.trailing, 4)
                } else if voiceManager.isTranscribing {
                    ProgressView()
                        .tint(LitterTheme.accent)
                        .padding(.trailing, 8)
                } else {
                    Button(action: onStartRecording) {
                        Image(systemName: "mic.fill")
                            .font(LitterFont.styled(size: LitterTheme.usesRemodexChrome ? 14 : 15))
                            .foregroundColor(LitterTheme.textSecondary)
                            .frame(width: composerButtonSize, height: composerButtonSize)
                            .contentShape(Rectangle())
                    }
                    .padding(.trailing, 4)
                }
            }
            .frame(minHeight: 36)
            .modifier(GlassRoundedRectModifier(cornerRadius: composerCornerRadius))

            if isTurnActive {
                Button(action: onInterrupt) {
                    Text("Cancel")
                        .font(LitterFont.styled(size: LitterTheme.usesRemodexChrome ? 14 : 15, weight: .medium))
                        .foregroundColor(LitterTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .modifier(GlassCapsuleModifier())
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

        }
        .animation(.spring(response: 0.3, dampingFraction: 0.86), value: isTurnActive)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }
}
