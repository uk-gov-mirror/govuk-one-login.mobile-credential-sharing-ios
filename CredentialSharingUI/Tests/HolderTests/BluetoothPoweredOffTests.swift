import DesignSystem
import GDSAnalytics
import SharingLogging
import SharingOrchestration
import SharingPrerequisiteGate
import Testing
import UIKit

@testable import CredentialSharingUI

@MainActor
@Suite("Turn On Bluetooth Screen Tests")
struct BluetoothPoweredOffTests {
    let mockOrchestrator = MockHolderOrchestrator()
    let analyticsService = MockAnalyticsService()


    private func makeViewModel() -> BluetoothPoweredOffViewModel {
        BluetoothPoweredOffViewModel(
            orchestrator: mockOrchestrator,
            analyticsService: analyticsService
        )
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

    @Test("Cancel (didDismiss) routes to the orchestrator and tracks analytics event")
    func cancelRoutesToOrchestrator() throws {
        let viewModel = makeViewModel()
        let expectedEvent = ButtonEvent(
            textKey: "cancel",
            bundle: .module
        )
        
        #expect(analyticsService.logEventCallCount == 0)
        #expect(mockOrchestrator.cancelPresentationCalled == false)

        if case let .action(action) = viewModel.didDismiss {
            action()
        } else {
            Issue.record("Expected a synchronous .action for didDismiss")
        }

        #expect(mockOrchestrator.cancelPresentationCalled)
        #expect(analyticsService.logEventCallCount == 1)
        #expect(analyticsService.loggedEvent?.name == expectedEvent.name.rawValue)
        #expect(analyticsService.loggedParameters != nil)
    }

    @Test("didAppear logs the screen view")
    func didAppearTracksScreenVisit() throws {
        let viewModel = makeViewModel()

        #expect(analyticsService.logEventCallCount == 0)

        if case let .action(action) = viewModel.didAppear {
            action()
        } else {
            Issue.record("Expected a synchronous .action for didAppear")
        }
        
        let parameters = try #require(analyticsService.loggedParameters)

        #expect(analyticsService.logEventCallCount == 1)
        #expect(analyticsService.loggedEvent?.name == ScreenViewEventName.screenView.rawValue)
        #expect(parameters["screen_class"] as? String == ScreenClass.modal.rawValue)
        #expect(parameters["is_error"] as? String == "false")
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
