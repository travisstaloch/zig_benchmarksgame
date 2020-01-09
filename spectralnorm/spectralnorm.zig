//  The Computer Language Benchmarks Game
//  https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
//  contributed by Ledrug
//  algorithm is a straight copy from Steve Decker et al's Fortran code
//  with GCC SSE2 intrinsics
//  translated to zig by Travis Staloch
//  MAKE, RUN:
// $ zig build-exe --release-fast spectralnorm.zig && time ./spectralnorm 5500

const std = @import("std");
const warn = std.debug.warn;

const Vec2d = @Vector(2, f64);

const Ctx = struct {
    v: []f64,
    out: []f64,
    n: u32,
    start_i: u32,
    end_i: u32,
};

// return element i,j of infinite matrix A
inline fn A(i: u32, j: u32) f64 {
    return @intToFloat(f64, (i + j) * (i + j + 1) / 2 + i + 1);
}

fn dot(v: []f64, u: []f64, n: u32) f64 {
    @setFloatMode(.Optimized);
    var i: u32 = 0;
    var sum: f64 = 0;
    while (i < n) : (i += 1)
        sum += v[i] * u[i];
    return sum;
}

fn mult_Av(v: []f64, out: []f64, n: u32, worker_count: usize, threads: []*std.Thread) !void {
    try mult_worker(v, out, n, worker_count, threads, worker_Av);
}

// multiply vector v by matrix A
fn worker_Av(ctx: Ctx) void {
    @setFloatMode(.Optimized);
    var i = ctx.start_i;
    while (i < ctx.end_i) : (i += 1) {
        var sum: Vec2d = .{ 0, 0 };

        var j: u32 = 0;
        while (j < ctx.n) : (j += 2) {
            const b: Vec2d = .{ ctx.v[j], ctx.v[j + 1] };
            const a: Vec2d = .{ A(i, j), A(i, j + 1) };
            sum += b / a;
        }
        ctx.out[i] = sum[0] + sum[1];
    }
}

// multiply vector v by matrix A transposed
fn mult_Atv(v: []f64, out: []f64, n: u32, worker_count: usize, threads: []*std.Thread) !void {
    try mult_worker(v, out, n, worker_count, threads, worker_Atv);
}

fn mult_worker(v: []f64, out: []f64, n: u32, worker_count: usize, threads: []*std.Thread, comptime worker_fn: fn (Ctx) void) !void {
    const partition_size = @intCast(u32, @divTrunc(n, worker_count));
    var i: u32 = 0;
    var thread_i: u8 = 0;
    while (i < n) : (i += partition_size) {
        var ctx = Ctx{ .v = v, .out = out, .n = n, .start_i = i, .end_i = std.math.min(i + partition_size, n) };
        threads[thread_i] = try std.Thread.spawn(ctx, worker_fn);
        thread_i += 1;
    }
}

fn worker_Atv(ctx: Ctx) void {
    @setFloatMode(.Optimized);
    var i = ctx.start_i;
    while (i < ctx.end_i) : (i += 1) {
        var sum: Vec2d = .{ 0, 0 };
        var j: u32 = 0;
        while (j < ctx.n) : (j += 2) {
            const b: Vec2d = .{ ctx.v[j], ctx.v[j + 1] };
            const a: Vec2d = .{ A(j, i), A(j + 1, i) };
            sum += b / a;
        }
        ctx.out[i] = sum[0] + sum[1];
    }
}

// multiply vector v by matrix A and then by matrix A transposed
fn mult_AtAv(v: []f64, out: []f64, tmp: []f64, n: u32, worker_count: usize) !void {
    const a = std.heap.page_allocator;
    const threads_Av = try a.alloc(*std.Thread, worker_count);
    defer a.free(threads_Av);
    try mult_Av(v, tmp, n, worker_count, threads_Av);
    for (threads_Av) |t| t.wait();

    const threads_Atv = try a.alloc(*std.Thread, worker_count);
    defer a.free(threads_Atv);
    try mult_Atv(tmp, out, n, worker_count, threads_Atv);
    for (threads_Atv) |t| t.wait();
}

pub fn main() anyerror!void {
    const a = std.heap.page_allocator;
    const args = try std.process.argsAlloc(a);
    defer std.process.argsFree(a, args);
    var n = std.fmt.parseInt(u32, args[1], 10) catch 2000;

    if (n & 1 == 1) n += 1;
    var mem = try a.alloc(f64, n * 3);
    var u = mem[0..n];
    var v = mem[n .. n * 2];
    var tmp = mem[n * 2 .. n * 3];
    const worker_count = try std.Thread.cpuCount();

    for (u) |_, i| u[i] = 1;
    var i: u8 = 0;
    while (i < 10) : (i += 1) {
        try mult_AtAv(u, v, tmp, n, worker_count);
        try mult_AtAv(v, u, tmp, n, worker_count);
    }
    const norm = std.math.sqrt(dot(u, v, n) / dot(v, v, n));
    if (n == 5500)
        std.debug.assert(std.math.approxEq(f64, norm, 1.274224153, 0.000000001));
    if (n == 100)
        std.debug.assert(std.math.approxEq(f64, norm, 1.274219991, 0.000000001));

    warn("{d:.9}\n", .{norm});
}
