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

const fontset: [FONTSET_SIZE]u8 =
    .{
        0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
        0x20, 0x60, 0x20, 0x20, 0x70, // 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
        0x90, 0x90, 0xF0, 0x10, 0x10, // 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
        0xF0, 0x10, 0x20, 0x40, 0x40, // 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, // A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
        0xF0, 0x80, 0x80, 0x80, 0xF0, // C
        0xE0, 0x90, 0x90, 0x90, 0xE0, // D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
        0xF0, 0x80, 0xF0, 0x80, 0x80, // F
    };

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

    prng: std.Random.DefaultPrng,

    table: [0xF + 1]*const fn (*Chip8) void,
    table0: [0xE + 1]*const fn (*Chip8) void,
    table8: [0xE + 1]*const fn (*Chip8) void,
    tableE: [0xE + 1]*const fn (*Chip8) void,
    tableF: [0x65 + 1]*const fn (*Chip8) void,
};

pub fn Chip8__init(init: std.process.Init) Chip8 {
    var memory: [MEMORY_SIZE]u8 = [_]u8{0} ** (MEMORY_SIZE);

    for (0..FONTSET_SIZE) |i| {
        memory[FONTSET_START_ADDRESS + i] = fontset[i];
    }

    const current_time = std.Io.Clock.now(.real, init.io);
    const zero_time = std.Io.Timestamp.zero;
    const duration = zero_time.durationTo(current_time);
    const duration_ms = duration.toMilliseconds();
    const seed: u64 = @as(u64, @intCast(duration_ms));

    var table: [0xF + 1]*const fn (*Chip8) void = undefined;
    table[0x0] = &Table0;
    table[0x1] = &OP_1nnn;
    table[0x2] = &OP_2nnn;
    table[0x3] = &OP_3xkk;
    table[0x4] = &OP_4xkk;
    table[0x5] = &OP_5xy0;
    table[0x6] = &OP_6xkk;
    table[0x7] = &OP_7xkk;
    table[0x8] = &Table8;
    table[0x9] = &OP_9xy0;
    table[0xA] = &OP_Annn;
    table[0xB] = &OP_Bnnn;
    table[0xC] = &OP_Cxkk;
    table[0xD] = &OP_Dxyn;
    table[0xE] = &TableE;
    table[0xF] = &TableF;

    var table0: [0xE + 1]*const fn (*Chip8) void = undefined;
    var table8: [0xE + 1]*const fn (*Chip8) void = undefined;
    var tableE: [0xE + 1]*const fn (*Chip8) void = undefined;
    var tableF: [0x65 + 1]*const fn (*Chip8) void = undefined;

    for (0..(0xE + 1)) |i| {
        table0[i] = &OP_NULL;
        table8[i] = &OP_NULL;
        tableE[i] = &OP_NULL;
    }

    table0[0x0] = &OP_00E0;
    table0[0xE] = &OP_00EE;

    table8[0x0] = &OP_8xy0;
    table8[0x1] = &OP_8xy1;
    table8[0x2] = &OP_8xy2;
    table8[0x3] = &OP_8xy3;
    table8[0x4] = &OP_8xy4;
    table8[0x5] = &OP_8xy5;
    table8[0x6] = &OP_8xy6;
    table8[0x7] = &OP_8xy7;
    table8[0xE] = &OP_8xyE;

    tableE[0x1] = &OP_ExA1;
    tableE[0xE] = &OP_Ex9E;

    for (0..(0x65 + 1)) |i| {
        tableF[i] = &OP_NULL;
    }

    tableF[0x07] = &OP_Fx07;
    tableF[0x0A] = &OP_Fx0A;
    tableF[0x15] = &OP_Fx15;
    tableF[0x18] = &OP_Fx18;
    tableF[0x1E] = &OP_Fx1E;
    tableF[0x29] = &OP_Fx29;
    tableF[0x33] = &OP_Fx33;
    tableF[0x55] = &OP_Fx55;
    tableF[0x65] = &OP_Fx65;

    return Chip8{
        .keypad = [_]u8{0} ** (KEY_COUNT),
        .video = [_]u32{0} ** (VIDEO_HEIGHT * VIDEO_WIDTH),

        .memory = memory,
        .registers = [_]u8{0} ** (REGISTER_COUNT),
        .index = 0,
        .pc = @intCast(START_ADDRESS),
        .delayTimer = 0,
        .soundTimer = 0,
        .stack = [_]u16{0} ** STACK_LEVELS,
        .sp = 0,
        .opcode = 0,

        .prng = std.Random.DefaultPrng.init(seed),
        .table = table,
        .table0 = table0,
        .table8 = table8,
        .tableE = tableE,
        .tableF = tableF,
    };
}

pub fn LoadROM(self: *Chip8, init: std.process.Init, filename: [:0]const u8) !void {
    const file = try std.Io.Dir.cwd().openFile(init.io, filename, .{ .mode = .read_only });
    defer file.close(init.io);
    var i_buffer: [1024]u8 = undefined;
    i_buffer[0] = 0;
    var reader = file.reader(init.io, &i_buffer);

    const file_stat = try file.stat(init.io);
    const file_size = file_stat.size;

    _ = try reader.interface.readSliceAll(self.memory[START_ADDRESS .. START_ADDRESS + file_size]);
}

pub fn Cycle(self: *Chip8) void {
    self.opcode = (@as(u16, self.memory[self.pc]) << 8) | (@as(u16, self.memory[self.pc + 1]));

    self.pc += 2;

    _ = self.table[(self.opcode & 0xF000) >> 12](self);

    if (self.delayTimer > 0) {
        self.delayTimer -= 1;
    }

    if (self.soundTimer > 0) {
        self.soundTimer -= 1;
    }
}

fn Table0(self: *Chip8) void {
    _ = self.table0[self.opcode & 0x000F](self);
}

fn Table8(self: *Chip8) void {
    _ = self.table8[self.opcode & 0x000F](self);
}

fn TableE(self: *Chip8) void {
    _ = self.tableE[self.opcode & 0x000F](self);
}

fn TableF(self: *Chip8) void {
    _ = self.tableF[self.opcode & 0x00FF](self);
}

fn OP_NULL(self: *Chip8) void {
    _ = self;
}

fn OP_00E0(self: *Chip8) void {
    @memset(&self.video, 0);
}

fn OP_00EE(self: *Chip8) void {
    self.sp -= 1;
    self.pc = self.stack[self.sp];
}

fn OP_1nnn(self: *Chip8) void {
    const address: u16 = self.opcode & 0x0FFF;
    self.pc = address;
}

fn OP_2nnn(self: *Chip8) void {
    const address: u16 = self.opcode & 0x0FFF;

    self.stack[self.sp] = self.pc;
    self.sp += 1;
    self.pc = address;
}

fn OP_3xkk(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const byte: u8 = @intCast((self.opcode & 0x00FF));
    if (self.registers[Vx] == byte) {
        self.pc += 2;
    }
}

fn OP_4xkk(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const byte: u8 = @intCast((self.opcode & 0x00FF));
    if (self.registers[Vx] != byte) {
        self.pc += 2;
    }
}

fn OP_5xy0(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const Vy: u8 = @intCast((self.opcode & 0x00F0) >> 4);

    if (self.registers[Vx] == self.registers[Vy]) {
        self.pc += 2;
    }
}

fn OP_6xkk(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const byte: u8 = @intCast((self.opcode & 0x00FF));

    self.registers[Vx] = byte;
}

fn OP_7xkk(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const byte: u8 = @intCast((self.opcode & 0x00FF));

    self.registers[Vx] +%= byte;
}

fn OP_8xy0(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const Vy: u8 = @intCast((self.opcode & 0x00F0) >> 4);

    self.registers[Vx] = self.registers[Vy];
}

fn OP_8xy1(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const Vy: u8 = @intCast((self.opcode & 0x00F0) >> 4);

    self.registers[Vx] |= self.registers[Vy];
}

fn OP_8xy2(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const Vy: u8 = @intCast((self.opcode & 0x00F0) >> 4);

    self.registers[Vx] &= self.registers[Vy];
}

fn OP_8xy3(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const Vy: u8 = @intCast((self.opcode & 0x00F0) >> 4);

    self.registers[Vx] ^= self.registers[Vy];
}

fn OP_8xy4(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const Vy: u8 = @intCast((self.opcode & 0x00F0) >> 4);

    const sum: u16 = @as(u16, @intCast(self.registers[Vx])) + @as(u16, @intCast(self.registers[Vy]));

    self.registers[Vx] = @intCast(sum & 0xFF);

    if (sum > 255) {
        self.registers[0xF] = 1;
    } else {
        self.registers[0xF] = 0;
    }
}

fn OP_8xy5(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const Vy: u8 = @intCast((self.opcode & 0x00F0) >> 4);

    const vx = self.registers[Vx];
    const vy = self.registers[Vy];

    const flag: u8 = if (vx >= vy) 1 else 0;

    self.registers[Vx] -%= self.registers[Vy];
    self.registers[0xF] = flag;
}

fn OP_8xy6(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);

    const flag = (self.registers[Vx] & 1);
    self.registers[Vx] >>= 1;
    self.registers[0xF] = (flag & 1);
}

fn OP_8xy7(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const Vy: u8 = @intCast((self.opcode & 0x00F0) >> 4);

    const vx = self.registers[Vx];
    const vy = self.registers[Vy];

    const flag: u8 = if (vy >= vx) 1 else 0;

    self.registers[Vx] = self.registers[Vy] -% self.registers[Vx];
    self.registers[0xF] = flag;
}

fn OP_8xyE(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);

    const flag = self.registers[Vx] & 0x80;
    self.registers[Vx] <<= 1;
    self.registers[0xF] = (flag) >> 7;
}

fn OP_9xy0(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const Vy: u8 = @intCast((self.opcode & 0x00F0) >> 4);

    if (self.registers[Vx] != self.registers[Vy]) {
        self.pc += 2;
    }
}

fn OP_Annn(self: *Chip8) void {
    const address: u16 = self.opcode & 0x0FFF;
    self.index = address;
}

fn OP_Bnnn(self: *Chip8) void {
    const address: u16 = self.opcode & 0x0FFF;
    self.pc = @as(u16, self.registers[0]) + address;
}

fn OP_Cxkk(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const byte: u8 = @intCast((self.opcode & 0x00FF));

    const randByte: u8 = self.prng.random().int(u8);

    self.registers[Vx] = randByte & byte;
}

fn OP_Dxyn(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const Vy: u8 = @intCast((self.opcode & 0x00F0) >> 4);
    const height: u8 = @intCast((self.opcode & 0x000F));

    const xPos: usize = self.registers[Vx] % @as(u8, VIDEO_WIDTH);
    const yPos: usize = self.registers[Vy] % @as(u8, VIDEO_HEIGHT);

    self.registers[0xF] = 0;

    for (0..height) |row| {
        if ((yPos + row) >= VIDEO_HEIGHT) break;
        const spriteByte: u8 = self.memory[self.index + row];

        for (0..8) |col| {
            if ((xPos + col) >= VIDEO_WIDTH) break;

            const spritePixel: u8 = spriteByte & (@as(u8, 0x80) >> @intCast(col));
            const screenPixel: *u32 = &self.video[(yPos + row) * VIDEO_WIDTH + (xPos + col)];

            if (spritePixel != 0) {
                if (screenPixel.* == 0xFFFFFFFF) {
                    self.registers[0xF] = 1;
                }
                screenPixel.* ^= 0xFFFFFFFF;
            }
        }
    }
}

fn OP_Ex9E(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const key: u8 = self.registers[Vx];

    if (self.keypad[key] != 0) {
        self.pc += 2;
    }
}

fn OP_ExA1(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const key: u8 = self.registers[Vx];

    if (self.keypad[key] == 0) {
        self.pc += 2;
    }
}

fn OP_Fx07(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);

    self.registers[Vx] = self.delayTimer;
}

fn OP_Fx0A(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);

    if (self.keypad[0] != 0) {
        self.registers[Vx] = 0;
    } else if (self.keypad[1] != 0) {
        self.registers[Vx] = 1;
    } else if (self.keypad[2] != 0) {
        self.registers[Vx] = 2;
    } else if (self.keypad[3] != 0) {
        self.registers[Vx] = 3;
    } else if (self.keypad[4] != 0) {
        self.registers[Vx] = 4;
    } else if (self.keypad[5] != 0) {
        self.registers[Vx] = 5;
    } else if (self.keypad[6] != 0) {
        self.registers[Vx] = 6;
    } else if (self.keypad[7] != 0) {
        self.registers[Vx] = 7;
    } else if (self.keypad[8] != 0) {
        self.registers[Vx] = 8;
    } else if (self.keypad[9] != 0) {
        self.registers[Vx] = 9;
    } else if (self.keypad[10] != 0) {
        self.registers[Vx] = 10;
    } else if (self.keypad[11] != 0) {
        self.registers[Vx] = 11;
    } else if (self.keypad[12] != 0) {
        self.registers[Vx] = 12;
    } else if (self.keypad[13] != 0) {
        self.registers[Vx] = 13;
    } else if (self.keypad[14] != 0) {
        self.registers[Vx] = 14;
    } else if (self.keypad[15] != 0) {
        self.registers[Vx] = 15;
    } else {
        self.pc -= 2;
    }
}

fn OP_Fx15(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);

    self.delayTimer = self.registers[Vx];
}

fn OP_Fx18(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);

    self.soundTimer = self.registers[Vx];
}

fn OP_Fx1E(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);

    self.index += self.registers[Vx];
}

fn OP_Fx29(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    const digit = self.registers[Vx];

    self.index = @as(u16, FONTSET_START_ADDRESS) + @as(u16, (5 * digit));
}

fn OP_Fx33(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);
    var value = self.registers[Vx];

    // Ones-place
    self.memory[self.index + 2] = value % 10;
    value /= 10;

    // Tens-place
    self.memory[self.index + 1] = value % 10;
    value /= 10;

    // Hundreds-place
    self.memory[self.index] = value % 10;
}

fn OP_Fx55(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);

    for (0..(Vx + 1)) |i| {
        self.memory[@as(usize, self.index) + i] = self.registers[i];
    }
}

fn OP_Fx65(self: *Chip8) void {
    const Vx: u8 = @intCast((self.opcode & 0x0F00) >> 8);

    for (0..(Vx + 1)) |i| {
        self.registers[i] = self.memory[@as(usize, self.index) + i];
    }
}
