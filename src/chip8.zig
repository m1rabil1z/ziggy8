const std = @import("std");

const FONTSET_SIZE: u32 = 80;
const FONTSET_START_ADDRESS: u32 = 0x50;
const START_ADDRESS: u32 = 0x200;
const KEY_COUNT: u32 = 16;
const MEMORY_SIZE: u32 = 4096;
const REGISTER_COUNT: u32 = 16;
const STACK_LEVELS: u32 = 16;
pub const VIDEO_HEIGHT: u32 = 32;
pub const VIDEO_WIDTH: u32 = 64;

const Chip8 = struct {
    keypad: [KEY_COUNT]u8,
    video: [VIDEO_HEIGHT * VIDEO_WIDTH]u32,

    memory: [MEMORY_SIZE]u8,
    registers: [REGISTER_COUNT]u8,
    index: u16,
    pc: u16,
    delayTimer: u8,
    soundTimer: u8,
    stack: [STACK_LEVELS]u16,
    sp: u8,
    opcode: u16,

    random: u8,

    table: [0xF + 1]*const fn (*Chip8) void,
    table0: [0xE + 1]*const fn (*Chip8) void,
    table8: [0xE + 1]*const fn (*Chip8) void,
    tableE: [0xE + 1]*const fn (*Chip8) void,
    tableF: [0x65 + 1]*const fn (*Chip8) void,
};
