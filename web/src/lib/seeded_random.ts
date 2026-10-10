// src/lib/seeded_random.ts
// Deterministic seeded random number generator
// Uses a simple but effective Linear Congruential Generator (LCG)
// Same seed always produces same sequence of numbers
// (state * 48271 < 2^53, so JS doubles give the exact same sequence as Lua)

// LCG parameters (same as MINSTD)
const MULTIPLIER = 48271;
const MODULUS = 2147483647; // 2^31 - 1 (Mersenne prime)

// Lua's % is floored modulo (result has the sign of the divisor)
function lua_mod(a: number, b: number): number {
  return a - Math.floor(a / b) * b;
}

export default class SeededRandom {
  seed: number;
  state: number;

  constructor(seed?: number) {
    this.seed = seed ?? Math.floor(Date.now() / 1000);
    this.state = lua_mod(this.seed, MODULUS);
    if (this.state === 0) this.state = 1; // Avoid zero state
  }

  static new(seed?: number): SeededRandom {
    return new SeededRandom(seed);
  }

  // Get next random number in range [0, 1)
  random(): number {
    this.state = (this.state * MULTIPLIER) % MODULUS;
    return this.state / MODULUS;
  }

  // Get random integer in range [min, max]; random_int(n) returns [1, n]
  random_int(min: number, max?: number): number {
    if (max === undefined) {
      max = min;
      min = 1;
    }
    return min + Math.floor(this.random() * (max - min + 1));
  }

  // Get random float in range [min, max]
  random_float(min: number, max: number): number {
    return min + this.random() * (max - min);
  }

  // Get random boolean with given probability of true
  random_bool(probability = 0.5): boolean {
    return this.random() < probability;
  }

  // Choose random element from array (same RNG draw as the 1-based Lua version)
  choose<T>(array: T[]): T | undefined {
    if (array.length === 0) return undefined;
    return array[this.random_int(1, array.length) - 1];
  }

  // Shuffle array in place (Fisher-Yates), same draw order as the Lua version
  shuffle<T>(array: T[]): T[] {
    for (let i = array.length; i >= 2; i--) {
      const j = this.random_int(1, i);
      const tmp = array[i - 1];
      array[i - 1] = array[j - 1];
      array[j - 1] = tmp;
    }
    return array;
  }

  // Weighted random selection
  // weights is an object of {item: weight, ...} (iterated in insertion order)
  weighted_choice(weights: Record<string, number>): string | undefined {
    let total = 0;
    for (const k in weights) total += weights[k];

    const roll = this.random() * total;
    let cumulative = 0;
    for (const k in weights) {
      cumulative += weights[k];
      if (roll <= cumulative) return k;
    }

    // Fallback (shouldn't happen)
    for (const k in weights) return k;
    return undefined;
  }

  // Reset to initial seed
  reset(): void {
    this.state = lua_mod(this.seed, MODULUS);
    if (this.state === 0) this.state = 1;
  }

  // Get current state for save/load
  get_state(): number {
    return this.state;
  }

  // Set state for save/load
  set_state(state: number): void {
    this.state = state;
  }

  // Get the original seed
  get_seed(): number {
    return this.seed;
  }
}
