declare module '@googlemaps/google-maps-services-js' {
  export class Client {
    constructor(config?: any);
    geocode(params: any): Promise<any>;
    reverseGeocode(params: any): Promise<any>;
    placesNearby(params: any): Promise<any>;
    distancematrix(params: any): Promise<any>;
    directions(params: any): Promise<any>;
  }

  export enum TravelMode {
    driving = 'driving',
    walking = 'walking',
    bicycles = 'bicycles',
    transit = 'transit',
  }
}
