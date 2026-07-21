import SwiftUI

extension ChatView {
    var isPendingTribunalOpening: Bool {
        conversation.isTribunal && sortedMessages.count == 1 && sortedMessages[0].messageRole == .guide
    }

    var canDeliverVerdicts: Bool {
        successfulExchangeCount >= max(pendingCommitments.count, 1)
    }

    func deliverVerdicts() {
        guard !isInputLocked, !chatService.isGeneratingVerdicts.contains(conversation.id), canDeliverVerdicts else { return }
        Task {
            let verdicts = await chatService.generateVerdicts(for: conversation, modelContext: modelContext)
            guard !verdicts.isEmpty, chatService.verdictErrors[conversation.id] == nil else { return }
            tribunalVerdicts = verdicts
            isVerdictOverlayShown = true
        }
    }

    func setupSealIfNeeded() {
        guard conversation.isTribunal, !hasPlayedSealIntro else { return }
        hasPlayedSealIntro = true
        showSeal = true

        if isPendingTribunalOpening {
            sealDocked = false
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                    sealDocked = true
                }
            }
        } else {
            sealDocked = true
        }
    }

    @ViewBuilder
    var tribunalVerdictOverlayContent: some View {
        if isVerdictOverlayShown {
            TribunalVerdictOverlay(
                verdicts: $tribunalVerdicts,
                onConfirm: { finalVerdicts in
                    chatService.applyVerdicts(finalVerdicts, for: conversation, modelContext: modelContext)
                    isVerdictOverlayShown = false
                },
                onCancel: { isVerdictOverlayShown = false }
            )
        }
    }

    @ViewBuilder
    var sealCenterOverlayContent: some View {
        if showSeal && !sealDocked {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)

            TribunalSealBanner(isDocked: false)
                .matchedGeometryEffect(id: "sealBanner", in: sealNamespace)
        }
    }
}
