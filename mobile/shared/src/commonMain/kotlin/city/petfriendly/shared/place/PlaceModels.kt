package city.petfriendly.shared.place

data class ExternalPlaceId(val value: String) {
    init {
        require(value.isNotBlank()) { "External place id must not be blank" }
    }
}

data class PlaceId(val value: String)

enum class PlaceStatus {
    DISCOVERED,
    COMMUNITY_DATA,
    VERIFIED,
    NEEDS_REVERIFICATION,
}

data class PlaceSnapshot(
    val id: PlaceId,
    val externalPlaceId: ExternalPlaceId,
    val status: PlaceStatus,
    val latitude: Double,
    val longitude: Double,
)

interface PlaceRepository {
    /**
     * Resolves an external provider identifier to our stable Place record.
     * Implementations must be idempotent for the same provider/id pair.
     */
    suspend fun getOrDiscoverGooglePlace(
        googlePlaceId: ExternalPlaceId,
        latitude: Double,
        longitude: Double,
    ): PlaceSnapshot
}
