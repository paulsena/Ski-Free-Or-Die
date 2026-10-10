// src/core/state_manager.ts
// Simple game state machine

export interface GameState {
  enter?(...args: any[]): void;
  exit?(): void;
  update?(dt: number): void;
  draw?(): void;
  keypressed?(key: string): void;
  keyreleased?(key: string): void;
  mousepressed?(x: number, y: number, button: number): void;
  wheelmoved?(x: number, y: number): void;
  [key: string]: any;
}

let current_state: GameState | null = null;
let current_state_name: string | null = null;
const states: Record<string, GameState> = {};

const StateManager = {
  register(name: string, state: GameState): void {
    states[name] = state;
  },

  switch(name: string, ...args: any[]): void {
    if (!states[name]) {
      throw new Error(`StateManager: attempted to switch to unknown state '${name}'`);
    }
    if (current_state && current_state.exit) current_state.exit();
    current_state = states[name];
    current_state_name = name;
    if (current_state && current_state.enter) current_state.enter(...args);
  },

  update(dt: number): void {
    current_state?.update?.(dt);
  },

  draw(): void {
    current_state?.draw?.();
  },

  keypressed(key: string): void {
    current_state?.keypressed?.(key);
  },

  keyreleased(key: string): void {
    current_state?.keyreleased?.(key);
  },

  mousepressed(x: number, y: number, button: number): void {
    current_state?.mousepressed?.(x, y, button);
  },

  wheelmoved(x: number, y: number): void {
    current_state?.wheelmoved?.(x, y);
  },

  get_current(): GameState | null {
    return current_state;
  },

  get_current_name(): string | null {
    return current_state_name;
  },
};

export default StateManager;
