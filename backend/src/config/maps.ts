import { Client } from '@googlemaps/google-maps-services-js';
import { env } from './env';

export const googleMapsClient = new Client({});

export const hasGoogleMapsKey = Boolean(env.GOOGLE_MAPS_API_KEY && env.GOOGLE_MAPS_API_KEY !== 'your_google_maps_api_key_here');

if (hasGoogleMapsKey) {
  console.log('🗺️ Google Maps Platform SDK configured with API Key.');
} else {
  console.log('ℹ️ Google Maps API Key not set. Using built-in geospatial fallback calculations.');
}
