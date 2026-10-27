import DesignSystem
import SharingOrchestration
import SharingPrerequisiteGate
import Testing
import UIKit

@testable import CredentialSharingUI

@MainActor
@Suite("Turn On Bluetooth Screen Tests")
struct BluetoothPoweredOffTests {
    let mockOrchestrator = MockHolderOrchestrator()

    private func makeViewModel() -> BluetoothPoweredOffViewModel {
        BluetoothPoweredOffViewModel(orchestrator: mockOrchestrator)
    }

    private func textViewModels(in viewModel: BluetoothPoweredOffViewModel) -> [GDSTextViewModel] {
        viewModel.body.compactMap { $0 as? GDSTextViewModel }
    }

    private func lists(in viewModel: BluetoothPoweredOffViewModel) -> [GDSListViewModel] {
        viewModel.body.compactMap { $0 as? GDSListViewModel }
    }

    // MARK: Layout composition

    @Test("Body is title, intro, numbered steps, then footnote")
    func bodyComposition() {
        let viewModel = makeViewModel()
        #expect(viewModel.body.count == 4)

        let identifiers = textViewModels(in: viewModel).map { $0.accessibilityIdentifier }
        #expect(identifiers == [
            "turn-on-bluetooth-title",
            "turn-on-bluetooth-body",
            "turn-on-bluetooth-footnote"
        ])
    }

    @Test("There are no footer or movable footer buttons")
    func noFooterButtons() {
        let viewModel = makeViewModel()
        #expect(viewModel.footer.isEmpty)
        #expect(viewModel.movableFooter.isEmpty)
    }

    @Test("Steps are a numbered list titled 'To do this:' with three items")
    func numberedStepsList() throws {
        let viewModel = makeViewModel()
        let list = try #require(lists(in: viewModel).first)

        #expect(list.style == .numbered)
        #expect(list.items.count == 3)
        #expect(list.title?.stringKey == "turnOnBluetoothListTitle")
        #expect(list.accessibilityIdentifier == "turn-on-bluetooth-steps")
    }

    @Test("Step 1 and step 2 carry bold emphasis attributes")
    func stepsHaveBoldEmphasis() throws {
        let viewModel = makeViewModel()
        let list = try #require(lists(in: viewModel).first)

        #expect(list.items[0].stringAttributes != nil)
        #expect(list.items[1].stringAttributes != nil)
        // Step 3 is short and carries no emphasis.
        #expect(list.items[2].stringAttributes == nil)
    }

    // MARK: Cancel bar button

    @Test("Right bar button is the localised Cancel key")
    func cancelBarButton() throws {
        let title = try #require(makeViewModel().rightBarButtonTitle)
        #expect(title.stringKey == "cancel")
    }

    @Test("Back button is hidden")
    func backButtonHidden() {
        #expect(makeViewModel().backButtonIsHidden)
    }

    // MARK: Interaction

    @Test("Cancel (didDismiss) routes to the orchestrator with no confirmation")
    func cancelRoutesToOrchestrator() throws {
        let viewModel = makeViewModel()
        #expect(mockOrchestrator.cancelPresentationCalled == false)

        if case let .action(action) = viewModel.didDismiss {
            action()
        } else {
            Issue.record("Expected a synchronous .action for didDismiss")
        }

        #expect(mockOrchestrator.cancelPresentationCalled)
        // No confirmation dialogue requested for this screen.
        #expect(mockOrchestrator.confirmCancelCalled == false)
    }

    @Test("didAppear runs without resolving or cancelling (analytics out of scope)")
    func didAppearIsInert() throws {
        let viewModel = makeViewModel()

        if case let .action(action) = viewModel.didAppear {
            action()
        } else {
            Issue.record("Expected a synchronous .action for didAppear")
        }

        #expect(mockOrchestrator.resolveCalled == false)
        #expect(mockOrchestrator.cancelPresentationCalled == false)
    }

    // MARK: View controller selection

    @Test("ReadinessViewController selects the Turn on Bluetooth view model when Bluetooth is powered off")
    func viewControllerSelectsTurnOnBluetooth() {
        let sut = ReadinessViewController(
            presentation: ReadinessPresentation(
                missingPrerequisites: [.bluetooth(.statePoweredOff)],
                cancelRequiresConfirmation: false
            ),
            orchestrator: mockOrchestrator
        )
        _ = sut.view
        #expect(sut.viewModel is BluetoothPoweredOffViewModel)
    }
}
