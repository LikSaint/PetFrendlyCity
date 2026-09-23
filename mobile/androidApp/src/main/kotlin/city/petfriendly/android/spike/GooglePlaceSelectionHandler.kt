package city.petfriendly.android.spike

import city.petfriendly.shared.place.PlacePreview
import city.petfriendly.shared.place.PlacePreviewPresenter

/**
 * Native Google Maps callbacks should be adapted here immediately. Keeping SDK
 * types outside shared code prevents Google from leaking into the domain layer.
 */
class GooglePlaceSelectionHandler(
    private val presenter: PlacePreviewPresenter,
) {
    suspend fun onPoiSelected(
        googlePlaceId: String,
        latitude: Double,
        longitude: Double,
    ): PlacePreview = presenter.select(googlePlaceId, latitude, longitude)
}
