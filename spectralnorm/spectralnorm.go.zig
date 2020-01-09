// The Computer Language Benchmarks Game
//   https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//   contributed by K P anonymous
//   corrected by Isaac Gouy
//   translated to zig by Travis Staloch
//   translated from https://benchmarksgame-team.pages.debian.net/benchmarksgame/program/spectralnorm-go-4.html
//
// MAKE, RUN:
// $ zig build-exe --release-fast --name spectralnorm.go.zig.run spectralnorm.go.zig && time ./spectralnorm.go.zig.run 5500

const std = @import("std");
const warn = std.debug.warn;
pub const io_mode = .evented;

fn Times(v: []f64, ii: usize, n: usize, u: []f64, c: *std.event.Channel(usize)) void {
    @setFloatMode(.Optimized);
    const ul = u.len;
    var i = ii;
    while (i < n) : (i += 1) {
        var vi: f64 = 0;
        var j: usize = 0;
        while (j < ul) : (j += 1) {
            vi += u[j] / A(i, j);
        }
        v[i] = vi;
    }
    c.put(1);
}

fn TimesTransp(v: []f64, ii: usize, n: usize, u: []f64, c: *std.event.Channel(usize)) void {
    @setFloatMode(.Optimized);
    const ul = u.len;
    var i = ii;
    while (i < n) : (i += 1) {
        var vi: f64 = 0;
        var j: usize = 0;
        while (j < ul) : (j += 1) {
            vi += u[j] / A(j, i);
        }
        v[i] = vi;
    }
    c.put(1);
}

fn wait(c: *std.event.Channel(usize), nCPU: usize) void {
    var i: usize = 0;
    while (i < nCPU) : (i += 1) {
        _ = c.get();
    }
}

fn ATimesTransp(v: []f64, u: []f64, n: usize) !void {
    @setFloatMode(.Optimized);
    const a = std.heap.page_allocator;
    const nCPU = try std.Thread.cpuCount();
    var x = try a.alloc(f64, n);
    var c: std.event.Channel(usize) = undefined;
    c.init(&[_]usize{nCPU}); //, nCPU)
    var framesT = try a.alloc(@Frame(Times), n);
    defer a.free(framesT);
    var framesTT = try a.alloc(@Frame(TimesTransp), n);
    defer a.free(framesTT);

    var i: usize = 0;
    while (i < nCPU) : (i += 1) {
        framesT[i] = async Times(x, i * v.len / nCPU, (i + 1) * v.len / nCPU, u, &c);
    }
    wait(&c, nCPU);
    i = 0;
    while (i < nCPU) : (i += 1) {
        framesTT[i] = async TimesTransp(v, i * v.len / nCPU, (i + 1) * v.len / nCPU, x, &c);
    }
    wait(&c, nCPU);
}

fn A(_i: usize, _j: usize) f64 {
    @setFloatMode(.Optimized);
    const i = @intToFloat(f64, _i);
    const j = @intToFloat(f64, _j);
    return ((i + j) * (i + j + 1) / 2 + i + 1);
}

pub fn main() !void {
    const a = std.heap.page_allocator;
    const args = try std.process.argsAlloc(a);
    defer std.process.argsFree(a, args);
    var n = std.fmt.parseInt(usize, args[1], 10) catch 2000;

    var mem = try a.alloc(f64, n * 2);
    defer a.free(mem);

    var u = mem[0..n];
    for (u) |*_u| _u.* = 1.0;
    var v = mem[n .. n * 2];

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        try ATimesTransp(v, u, n);
        try ATimesTransp(u, v, n);
    }

    var vBv: f64 = 0;
    var vv: f64 = 0;
    for (v) |vi, ii| {
        vBv += u[ii] * vi;
        vv += vi * vi;
    }
    warn("{d:.9}\n", .{@sqrt(vBv / vv)});
}
