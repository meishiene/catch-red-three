export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  host: process.env.HOST || '0.0.0.0',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  roomCodeLength: 6,
  roomCodeChars: 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
  identityRevealTimeoutMs: 15000,
  turnTimeoutMs: 30000,
  gameStartCountdownMs: 3000,
  roomCleanupIntervalMs: 60000,
  roomMaxIdleMs: 30 * 60 * 1000,
  maxReconnectAttempts: 5,
  reconnectTimeoutMs: 30000,
};
