import Foundation
import Combine
import Shared

@MainActor
final class PlacePreviewViewModel: ObservableObject {
    @Published private(set) var preview: PlacePreview?
    @Published private(set) var errorMessage: String?

    private let presenter: PlacePreviewPresenter

    init(presenter: PlacePreviewPresenter) {
        self.presenter = presenter
    }

    func selectGooglePlace(id: String, latitude: Double, longitude: Double) async {
        do {
            preview = try await presenter.select(
                googlePlaceId: id,
                latitude: latitude,
                longitude: longitude
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
