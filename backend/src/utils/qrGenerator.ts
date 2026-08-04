import QRCode from 'qrcode';
import { v4 as uuidv4 } from 'uuid';

export interface GeneratedQrData {
  qrCode: string; // Plain verification token string
  qrCodeDataUrl: string; // Base64 PNG image data URL
}

export async function generateBookingQrCode(bookingIdPrefix = 'PARKPILOT'): Promise<GeneratedQrData> {
  const uniqueToken = `${bookingIdPrefix}-${uuidv4().substring(0, 8).toUpperCase()}`;

  const payload = JSON.stringify({
    system: 'ParkPilot',
    token: uniqueToken,
    timestamp: new Date().toISOString(),
  });

  const qrCodeDataUrl = await QRCode.toDataURL(payload, {
    errorCorrectionLevel: 'H',
    type: 'image/png',
    margin: 2,
    color: {
      dark: '#1E293B',
      light: '#FFFFFF',
    },
  });

  return {
    qrCode: uniqueToken,
    qrCodeDataUrl,
  };
}
