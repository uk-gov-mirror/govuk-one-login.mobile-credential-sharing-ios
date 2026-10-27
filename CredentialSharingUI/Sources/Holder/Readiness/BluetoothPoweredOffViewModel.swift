import DesignSystem
import GDSAnalytics
import Logging
import SharingLogging
import SharingOrchestration
import SharingPrerequisiteGate

@MainActor
struct BluetoothPoweredOffViewModel: GDSScreenViewModel, BaseViewModel {
    let screenStyle: GDSScreenStyle = .top
    let body: [any ContentViewModel]
    let movableFooter: [any ContentViewModel] = []
    let footer: [any ContentViewModel] = []
    let rightBarButtonTitle: GDSLocalisedString? = GDSLocalisedString(
        stringKey: "cancel",
        bundle: .module
    )
    let backButtonTitle: GDSLocalisedString? = nil
    let backButtonIsHidden: Bool = true
    let didAppear: DesignSystem.Action?
    let didDismiss: DesignSystem.Action?
    
    let analyticsService: AnalyticsService?
    private let orchestrator: HolderOrchestratorProtocol
    
    // swiftlint:disable:next function_body_length
    init(
        orchestrator: HolderOrchestratorProtocol,
        analyticsService: AnalyticsService? = nil
    ) {
        self.orchestrator = orchestrator
        self.analyticsService = analyticsService

        let title = GDSTextViewModel(
            title: GDSLocalisedString(stringKey: "turnOnBluetoothTitle", bundle: .module),
            titleFont: DesignSystem.Font.Base.largeTitleBold,
            accessibilityTraits: .header,
            accessibilityIdentifier: "turn-on-bluetooth-title",
            verticalPadding: .vertical(DesignSystem.Spacing.default)
        )

        let intro = GDSTextViewModel(
            title: GDSLocalisedString(stringKey: "turnOnBluetoothParagraph1", bundle: .module),
            accessibilityIdentifier: "turn-on-bluetooth-body"
        )

        let steps = GDSListViewModel(
            title: GDSLocalisedString(stringKey: "turnOnBluetoothListTitle", bundle: .module),
            titleConfig: (font: DesignSystem.Font.Base.body, isHeader: false),
            items: [
                GDSLocalisedString(
                    stringKey: "turnOnBluetoothStep1",
                    stringAttributes: [
                        (GDSLocalisedString(stringKey: "turnOnBluetoothStep1Bold", bundle: .module).value,
                         [.font: DesignSystem.Font.Base.bodyBold])
                    ],
                    bundle: .module
                ),
                GDSLocalisedString(
                    stringKey: "turnOnBluetoothStep2",
                    stringAttributes: [
                        (GDSLocalisedString(stringKey: "turnOnBluetoothStep2Bold", bundle: .module).value,
                         [.font: DesignSystem.Font.Base.bodyBold])
                    ],
                    bundle: .module
                ),
                GDSLocalisedString(stringKey: "turnOnBluetoothStep3", bundle: .module)
            ],
            style: .numbered,
            accessibilityIdentifier: "turn-on-bluetooth-steps",
            verticalPadding: .vertical(DesignSystem.Spacing.default)
        )

        let footnote = GDSTextViewModel(
            title: GDSLocalisedString(stringKey: "turnOnBluetoothParagraph2", bundle: .module),
            accessibilityIdentifier: "turn-on-bluetooth-footnote"
        )

        self.body = [title, intro, steps, footnote]

        self.didAppear = .action {
            analyticsService?.trackScreenEvent(
                ScreenViewEventName.screenView,
                title: AnalyticsScreen.turnOnBluetooth.rawValue,
                screenClass: .modal,
                screenID: AnalyticsScreen.turnOnBluetooth.id,
            )
        }

        self.didDismiss = .action {
            let event = ButtonEvent(textKey: "cancel", bundle: .module)
            analyticsService?.trackButtonEvent(event)
            orchestrator.userDidTapCancel()
        }
    }
}
