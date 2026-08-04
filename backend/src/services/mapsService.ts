import { googleMapsClient, hasGoogleMapsKey } from '../config/maps';
import { env } from '../config/env';
import { calculateHaversineDistance, estimateDrivingMetrics } from '../utils/geo';
import { TravelMode } from '@googlemaps/google-maps-services-js';

export class MapsService {
  /**
   * Geocode an address to latitude & longitude coordinates
   */
  async geocode(address: string) {
    if (hasGoogleMapsKey) {
      try {
        const response = await googleMapsClient.geocode({
          params: {
            address,
            key: env.GOOGLE_MAPS_API_KEY,
          },
        });

        if (response.data.results.length > 0) {
          const location = response.data.results[0].geometry.location;
          return {
            formattedAddress: response.data.results[0].formatted_address,
            latitude: location.lat,
            longitude: location.lng,
          };
        }
      } catch (error) {
        console.warn('⚠️ Google Maps Geocode API Error, using fallback:', error);
      }
    }

    // Default Fallback (Chennai Center default)
    return {
      formattedAddress: address,
      latitude: 13.0827,
      longitude: 80.2707,
    };
  }

  /**
   * Reverse Geocode lat/lng coordinates to formatted street address
   */
  async reverseGeocode(latitude: number, longitude: number) {
    if (hasGoogleMapsKey) {
      try {
        const response = await googleMapsClient.reverseGeocode({
          params: {
            latlng: [latitude, longitude],
            key: env.GOOGLE_MAPS_API_KEY,
          },
        });

        if (response.data.results.length > 0) {
          return {
            address: response.data.results[0].formatted_address,
            placeId: response.data.results[0].place_id,
          };
        }
      } catch (error) {
        console.warn('⚠️ Google Maps Reverse Geocode Error, using fallback:', error);
      }
    }

    return {
      address: `Location near (${latitude.toFixed(4)}, ${longitude.toFixed(4)}), Chennai, TN`,
      placeId: `mock_place_${latitude}_${longitude}`,
    };
  }

  /**
   * Search places around a location
   */
  async searchPlaces(query: string, latitude?: number, longitude?: number) {
    if (hasGoogleMapsKey && latitude && longitude) {
      try {
        const response = await googleMapsClient.placesNearby({
          params: {
            location: [latitude, longitude],
            radius: 5000,
            keyword: query || 'parking',
            key: env.GOOGLE_MAPS_API_KEY,
          },
        });

        return response.data.results.map((place: any) => ({
          placeId: place.place_id,
          name: place.name,
          address: place.vicinity,
          latitude: place.geometry?.location.lat,
          longitude: place.geometry?.location.lng,
          rating: place.rating,
        }));
      } catch (error) {
        console.warn('⚠️ Google Maps Places Nearby API Error:', error);
      }
    }

    return [
      {
        placeId: 'place_express_avenue',
        name: 'Express Avenue Parking',
        address: 'Royapettah, Chennai',
        latitude: 13.0587,
        longitude: 80.2641,
        rating: 4.8,
      },
      {
        placeId: 'place_tnagar_mlp',
        name: 'T. Nagar MLP Complex',
        address: 'Thyagaraya Nagar, Chennai',
        latitude: 13.0418,
        longitude: 80.2341,
        rating: 4.6,
      },
    ];
  }

  /**
   * Calculate distance matrix between origin and destination
   */
  async calculateDistance(originLat: number, originLng: number, destLat: number, destLng: number) {
    if (hasGoogleMapsKey) {
      try {
        const response = await googleMapsClient.distancematrix({
          params: {
            origins: [[originLat, originLng]],
            destinations: [[destLat, destLng]],
            mode: TravelMode.driving,
            key: env.GOOGLE_MAPS_API_KEY,
          },
        });

        const element = response.data.rows[0]?.elements[0];
        if (element && element.status === 'OK') {
          return {
            distanceKm: Math.round((element.distance.value / 1000) * 100) / 100,
            durationMinutes: Math.round(element.duration.value / 60),
            formattedDistance: element.distance.text,
            formattedDuration: element.duration.text,
          };
        }
      } catch (error) {
        console.warn('⚠️ Google Maps Distance Matrix API Error, using Haversine calculation:', error);
      }
    }

    const haversineDist = calculateHaversineDistance(originLat, originLng, destLat, destLng);
    return estimateDrivingMetrics(haversineDist);
  }

  /**
   * Fetch directions / routes between origin and destination
   */
  async getDirections(originLat: number, originLng: number, destLat: number, destLng: number) {
    if (hasGoogleMapsKey) {
      try {
        const response = await googleMapsClient.directions({
          params: {
            origin: [originLat, originLng],
            destination: [destLat, destLng],
            mode: TravelMode.driving,
            key: env.GOOGLE_MAPS_API_KEY,
          },
        });

        const route = response.data.routes[0];
        if (route) {
          const leg = route.legs[0];
          return {
            summary: route.summary,
            distanceText: leg.distance.text,
            durationText: leg.duration.text,
            startAddress: leg.start_address,
            endAddress: leg.end_address,
            overviewPolyline: route.overview_polyline.points,
            steps: leg.steps.map((step: any) => ({
              instruction: step.html_instructions.replace(/<[^>]*>?/gm, ''),
              distance: step.distance.text,
              duration: step.duration.text,
            })),
          };
        }
      } catch (error) {
        console.warn('⚠️ Google Maps Directions API Error:', error);
      }
    }

    const dist = calculateHaversineDistance(originLat, originLng, destLat, destLng);
    const metrics = estimateDrivingMetrics(dist);

    return {
      summary: 'Direct city route via main arterial roads',
      distanceText: metrics.formattedDistance,
      durationText: metrics.formattedDuration,
      startAddress: `Origin (${originLat}, ${originLng})`,
      endAddress: `Destination Parking (${destLat}, ${destLng})`,
      overviewPolyline: `mock_polyline_${originLat}_${destLat}`,
      steps: [
        { instruction: 'Head towards destination parking space', distance: metrics.formattedDistance, duration: metrics.formattedDuration },
      ],
    };
  }
}

export const mapsService = new MapsService();
