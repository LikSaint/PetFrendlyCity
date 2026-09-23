package city.petfriendly.shared.place

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.test.runTest

class SelectGooglePlaceTest {
    @Test
    fun `passes stable Google id through the domain boundary`() = runTest {
        val repository = RecordingPlaceRepository()
        val result = SelectGooglePlace(repository)("ChIJ-phase-0", 40.4093, 49.8671)

        assertEquals("ChIJ-phase-0", repository.lastExternalId?.value)
        assertEquals("place-1", result.id.value)
        assertEquals(PlaceStatus.DISCOVERED, result.status)
    }
}

private class RecordingPlaceRepository : PlaceRepository {
    var lastExternalId: ExternalPlaceId? = null

    override suspend fun getOrDiscoverGooglePlace(
        googlePlaceId: ExternalPlaceId,
        latitude: Double,
        longitude: Double,
    ): PlaceSnapshot {
        lastExternalId = googlePlaceId
        return PlaceSnapshot(
            id = PlaceId("place-1"),
            externalPlaceId = googlePlaceId,
            status = PlaceStatus.DISCOVERED,
            latitude = latitude,
            longitude = longitude,
        )
    }
}
