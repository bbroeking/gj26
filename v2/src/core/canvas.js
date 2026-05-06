// Canvas + global render constants. World dimensions live in data/config.js.
import { CONFIG } from '../data/config.js';

export const TILE = CONFIG.tile;        // 32
export const COLS = CONFIG.world.cols;  // 40
export const ROWS = CONFIG.world.rows;  // 28
export const WORLD_W = COLS * TILE;
export const WORLD_H = ROWS * TILE;

export const canvas = document.getElementById('game');
export const ctx = canvas.getContext('2d');
ctx.imageSmoothingEnabled = false;

export const VIEW_W = canvas.width;
export const VIEW_H = canvas.height;
