import { Socket } from 'socket.io';
import { gameManager } from '../../game/game-manager';
import { C2S, S2C } from '../../types/events';

export function registerGameHandlers(socket: Socket): void {
  socket.on(C2S.GAME_REVEAL, (data: { cardIds: string[] }) => {
    const playerId = socket.data.playerId;
    const roomCode = socket.data.roomCode;
    if (!roomCode) return;

    const game = gameManager.getGame(roomCode);
    if (!game) return;

    game.handleReveal(playerId, data.cardIds);
  });

  socket.on(C2S.GAME_SKIP_REVEAL, () => {
    const playerId = socket.data.playerId;
    const roomCode = socket.data.roomCode;
    if (!roomCode) return;

    const game = gameManager.getGame(roomCode);
    if (!game) return;

    game.handleSkipReveal(playerId);
  });

  socket.on(C2S.GAME_PLAY, (data: { cardIds: string[] }) => {
    const playerId = socket.data.playerId;
    const roomCode = socket.data.roomCode;
    if (!roomCode) return;

    const game = gameManager.getGame(roomCode);
    if (!game) return;

    game.handlePlay(playerId, data.cardIds);
  });

  socket.on(C2S.GAME_PASS, () => {
    const playerId = socket.data.playerId;
    const roomCode = socket.data.roomCode;
    if (!roomCode) return;

    const game = gameManager.getGame(roomCode);
    if (!game) return;

    game.handlePass(playerId);
  });

  socket.on(C2S.GAME_TRIBUTE_RETURN, (data: { cardIds: string[] }) => {
    const playerId = socket.data.playerId;
    const roomCode = socket.data.roomCode;
    if (!roomCode) return;

    const game = gameManager.getGame(roomCode);
    if (!game) return;

    game.handleTributeReturn(playerId, data.cardIds);
  });
}
