// src/gfx/sprites/index.ts
// Registry of every sprite by name.

import { Sprite } from "../sprite_def";
import OBSTACLE_SPRITES from "./obstacles";
import GATE_SPRITES from "./gate";
import SKIER_SPRITES from "./skier";
import YETI_SPRITES from "./yeti";
import UI_SPRITES from "./ui";

const SPRITES: Record<string, Sprite> = {
  ...OBSTACLE_SPRITES,
  ...GATE_SPRITES,
  ...SKIER_SPRITES,
  ...YETI_SPRITES,
  ...UI_SPRITES,
};

export default SPRITES;
