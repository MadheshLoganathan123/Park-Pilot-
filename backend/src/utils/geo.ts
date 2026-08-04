/**
 * Calculates the Haversine distance in kilometers between two GPS coordinates.
 */
export function calculateHaversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth's mean radius in kilometers
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;

  return Math.round(distance * 100) / 100; // Round to 2 decimal places
}

function toRad(degrees: number): number {
  return (degrees * Math.PI) / 180;
}

/**
 * Estimates driving distance and duration (ETA) based on straight-line distance with standard urban traffic factor.
 */
export function estimateDrivingMetrics(distanceKm: number) {
  const estimatedRoadDistanceKm = Math.round(distanceKm * 1.3 * 100) / 100;
  const estimatedDurationMinutes = Math.round((estimatedRoadDistanceKm / 30) * 60); // Assuming 30 km/h avg urban speed

  return {
    distanceKm: estimatedRoadDistanceKm,
    durationMinutes: estimatedDurationMinutes,
    formattedDistance: `${estimatedRoadDistanceKm} km`,
    formattedDuration: `${estimatedDurationMinutes} mins`,
  };
}
