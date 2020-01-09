// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// Contributed by Mr Ledrug
// Translated to zig by Travis Staloch
// MAKE, RUN:
// zig build-exe --release-fast pidigits.zig && time ./pidigits 1000

const std = @import("std");
const warn = std.debug.warn;
const BigInt = std.math.big.Int;

var tmp1: BigInt = undefined;
var tmp2: BigInt = undefined;
var rem: BigInt = undefined;
var acc: BigInt = undefined;
var den: BigInt = undefined;
var num: BigInt = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const a = &arena.allocator;
    const args = try std.process.argsAlloc(a);
    defer std.process.argsFree(a, args);
    const n = try std.fmt.parseInt(u32, args[1], 10);
    const stdout = &std.io.getStdOut().outStream().stream;

    tmp1 = try BigInt.init(a);
    tmp2 = try BigInt.init(a);
    rem = try BigInt.init(a);
    acc = try BigInt.initSet(a, 0);
    den = try BigInt.initSet(a, 1);
    num = try BigInt.initSet(a, 1);
    const two = try BigInt.initSet(a, 2);

    var k: u32 = 0;
    var i: u32 = 0;
    while (i < n) {
        k += 1;
        try next_term(k, two);
        if (num.cmp(acc) > 0)
            continue;

        const d = try extract_digit(3);
        if (d != try extract_digit(4))
            continue;

        _ = try stdout.write(&[_]u8{'0' + @truncate(u8, d)});
        i += 1;
        if (i % 10 == 0)
            _ = try stdout.print("\t:{}\n", .{i});
        try eliminate_digit(d);
    }
}

fn next_term(k: u32, two: BigInt) !void {
    const k2 = k * 2 + 1;
    try tmp1.mul(num, two);
    try acc.add(acc, tmp1);

    try tmp1.set(k);
    try tmp2.set(k2);
    try acc.mul(acc, tmp2);
    try den.mul(den, tmp2);
    try num.mul(num, tmp1);
}

fn eliminate_digit(d: u32) !void {
    try tmp1.set(d);
    try tmp2.mul(den, tmp1);
    try acc.sub(acc, tmp2);
    try tmp1.set(10);
    try acc.mul(acc, tmp1);
    try num.mul(num, tmp1);
}

fn extract_digit(comptime nth: u32) !u32 {
    // joggling between tmp1 and tmp2, so GMP won't have to use temp buffers
    try tmp2.set(nth);
    try tmp1.mul(num, tmp2);
    try tmp2.add(tmp1, acc);
    try tmp1.divFloor(&rem, tmp2, den);
    return tmp1.to(u32);
}
