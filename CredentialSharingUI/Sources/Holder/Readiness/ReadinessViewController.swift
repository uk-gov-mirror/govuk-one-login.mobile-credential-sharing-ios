import DesignSystem
import Logging
import SharingOrchestration
import SharingPrerequisiteGate

@MainActor
final class ReadinessViewController: GDSScreen {
    init(
        presentation: ReadinessPresentation,
        orchestrator: HolderOrchestratorProtocol,
        analyticsService: AnalyticsService? = nil
    ) {
        super.init(
            viewModel: Self.viewModel(
                for: presentation,
                orchestrator: orchestrator,
                analyticsService: analyticsService
                
            )
        )
    }
    
    /// Maps a `ReadinessPresentation` to the view model for its state.
    static func viewModel(
        for presentation: ReadinessPresentation,
        orchestrator: HolderOrchestratorProtocol,
        analyticsService: AnalyticsService? = nil
    ) -> GDSScreenViewModel {
        switch presentation.missingPrerequisites.first {
        case .bluetooth(.statePoweredOff):
            return BluetoothPoweredOffViewModel(
                orchestrator: orchestrator,
                analyticsService: analyticsService
            )
        case .bluetooth(.authorizationNotDetermined):
            return GetReadyToShareViewModel(
                presentation: presentation,
                orchestrator: orchestrator,
                analyticsService: analyticsService
            )
        default:
            return GetReadyToShareViewModel(
                presentation: presentation,
                orchestrator: orchestrator,
                analyticsService: analyticsService
            )
        }
        
    }
}
