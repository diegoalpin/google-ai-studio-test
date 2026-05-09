/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
*/

import { create } from 'zustand';
import { io, Socket } from 'socket.io-client';
import { GameState, Player } from '../shared/types';

interface GameStore {
  socket: Socket | null;
  gameState: GameState | null;
  playerId: string | null;
  countdown: number | null;
  lastMilestone: number;
  connect: () => void;
  joinGame: () => void;
  startJoinCountdown: () => void;
  sendPlayerState: (data: any) => void;
  sendCollectOrb: (orbId: string) => void;
}

export const globalGameState: { current: GameState | null } = { current: null };
let lastUiUpdate = 0;

export const useGameStore = create<GameStore>((set, get) => ({
  socket: null,
  gameState: null,
  playerId: null,
  countdown: null,
  lastMilestone: 0,
  connect: () => {
    if (get().socket) return;
    
    const socket = io();

    socket.on('connect', () => {
      console.log('Connected to server');
    });

    socket.on('init', (id: string) => {
      set({ playerId: id });
    });

    socket.on('state', (state: GameState) => {
      globalGameState.current = state;
      const now = Date.now();
      if (now - lastUiUpdate > 100) { // Throttle React updates to 10Hz
        set({ gameState: state });
        lastUiUpdate = now;
      }
    });

    set({ socket });
  },
  startJoinCountdown: () => {
    const start = 3;
    set({ countdown: start });
    
    const tick = (count: number) => {
      if (count <= 0) {
        set({ countdown: 0 }); // Special value for "GO!"
        setTimeout(() => {
          set({ countdown: null });
          get().joinGame();
        }, 500);
        return;
      }
      
      set({ countdown: count });
      setTimeout(() => tick(count - 1), 1000);
    };
    
    tick(start);
  },
  joinGame: () => {
    const { socket } = get();
    if (socket) {
      set({ lastMilestone: 0 });
      socket.emit('join');
    }
  },
  sendPlayerState: (data) => {
    const { socket } = get();
    if (socket) {
      socket.emit('update_state', data);
    }
  },
  sendCollectOrb: (orbId) => {
    const { socket } = get();
    if (socket) {
      socket.emit('collect_orb', orbId);
    }
  },
}));
