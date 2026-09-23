package city.petfriendly.shared.place

class SelectGooglePlace(
    private val repository: PlaceRepository,
) {
    suspend operator fun invoke(
        googlePlaceId: String,
        latitude: Double,
        longitude: Double,
    ): PlaceSnapshot = repository.getOrDiscoverGooglePlace(
        googlePlaceId = ExternalPlaceId(googlePlaceId),
        latitude = latitude,
        longitude = longitude,
    )
}

/**
 * Callback surface kept deliberately simple for the first Swift interop spike.
 * Production code can replace it with a lifecycle-aware Flow bridge after the
 * Phase 0 cancellation/error checks are complete.
 */
class PlacePreviewPresenter(
    private val selectGooglePlace: SelectGooglePlace,
) {
    suspend fun select(
        googlePlaceId: String,
        latitude: Double,
        longitude: Double,
    ): PlacePreview = selectGooglePlace(googlePlaceId, latitude, longitude).toPreview()
}

data class PlacePreview(
    val id: String,
    val googlePlaceId: String,
    val status: String,
)

private fun PlaceSnapshot.toPreview() = PlacePreview(
    id = id.value,
    googlePlaceId = externalPlaceId.value,
    status = status.name,
)
