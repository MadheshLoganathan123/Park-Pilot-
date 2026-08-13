import { Request, Response, NextFunction } from 'express';
import { parkingService } from '../services/parkingService';
import { mapsService } from '../services/mapsService';
import { sendSuccess, sendError } from '../utils/response';
import { AppError } from '../middleware/errorHandler';

export async function getAllParkingSpaces(req: Request, res: Response, next: NextFunction) {
  try {
    const { search, status } = req.query;
    const spaces = await parkingService.getAllParkingSpaces(
      search as string | undefined,
      status as any
    );
    return sendSuccess(res, spaces, 'Parking spaces retrieved successfully');
  } catch (error) {
    next(error);
  }
}

export async function getNearbyParkingSpaces(req: Request, res: Response, next: NextFunction) {
  try {
    const latStr = req.query.lat as string;
    const lngStr = req.query.lng as string;
    const radiusStr = req.query.radius as string;

    if (!latStr || !lngStr) {
      throw new AppError('Latitude (lat) and longitude (lng) query parameters are required.', 400);
    }

    const lat = parseFloat(latStr);
    const lng = parseFloat(lngStr);
    const radius = radiusStr ? parseFloat(radiusStr) : 5.0;

    if (isNaN(lat) || isNaN(lng) || isNaN(radius)) {
      throw new AppError('Invalid numeric value for lat, lng, or radius.', 400);
    }

    const nearbySpaces = await parkingService.getNearbyParkingSpaces(lat, lng, radius);
    return sendSuccess(res, nearbySpaces, `Retrieved ${nearbySpaces.length} nearby parking spaces within ${radius}km`);
  } catch (error) {
    next(error);
  }
}

export async function getParkingSpaceById(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    const space = await parkingService.getParkingSpaceById(id);

    if (!space) {
      throw new AppError('Parking space not found', 404);
    }

    return sendSuccess(res, space, 'Parking space details retrieved successfully');
  } catch (error) {
    next(error);
  }
}

export async function createParkingSpace(req: Request, res: Response, next: NextFunction) {
  try {
    const providerId = req.user?.id;
    if (!providerId) {
      throw new AppError('Unauthenticated provider request', 401);
    }

    const space = await parkingService.createParkingSpace({
      ...req.body,
      providerId,
    });

    return sendSuccess(res, space, 'Parking space created successfully', 201);
  } catch (error) {
    next(error);
  }
}

export async function updateParkingSpace(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    const existingSpace = await parkingService.getParkingSpaceById(id);

    if (!existingSpace) {
      throw new AppError('Parking space not found', 404);
    }

    if (existingSpace.providerId !== req.user?.id) {
      throw new AppError('Unauthorized: You can only update parking spaces you own.', 403);
    }

    const updatedSpace = await parkingService.updateParkingSpace(id, req.body);
    return sendSuccess(res, updatedSpace, 'Parking space updated successfully');
  } catch (error) {
    next(error);
  }
}

export async function deleteParkingSpace(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    const existingSpace = await parkingService.getParkingSpaceById(id);

    if (!existingSpace) {
      throw new AppError('Parking space not found', 404);
    }

    if (existingSpace.providerId !== req.user?.id) {
      throw new AppError('Unauthorized: You can only delete parking spaces you own.', 403);
    }

    await parkingService.deleteParkingSpace(id);
    return sendSuccess(res, { id }, 'Parking space deleted successfully');
  } catch (error) {
    next(error);
  }
}

export async function calculateRouteToParking(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params;
    const originLatStr = req.query.originLat as string;
    const originLngStr = req.query.originLng as string;

    if (!originLatStr || !originLngStr) {
      throw new AppError('originLat and originLng parameters are required.', 400);
    }

    const space = await parkingService.getParkingSpaceById(id);
    if (!space) {
      throw new AppError('Parking space not found', 404);
    }

    const directions = await mapsService.getDirections(
      parseFloat(originLatStr),
      parseFloat(originLngStr),
      space.latitude,
      space.longitude
    );

    return sendSuccess(res, directions, 'Directions calculated successfully');
  } catch (error) {
    next(error);
  }
}
