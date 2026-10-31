import Observation
import ServiceManagement

@MainActor
@Observable
final class LoginItemService {
    private(set) var isEnabled = false
    private(set) var needsApproval = false
    private(set) var hasError = false

    init() { refresh() }

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        needsApproval = status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            hasError = false
        } catch {
            hasError = true
        }
        refresh()
    }
}
