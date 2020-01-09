// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// Contributed by Mark C. Lewis.
// Modified slightly by Chad Whipkey.
// Converted from Java to C++ and added SSE support by Branimir Maksimovic.
// Converted from C++ to C by Alexey Medvedchikov.
// Modified by Jeremy Zerfas.
// Converted to zig by Travis Staloch

// zig version 0.5.0+e9536ca10 from 1/2/2020
// a port of https://benchmarksgame-team.pages.debian.net/benchmarksgame/program/nbody-gcc-8.html
//
// MAKE:
//  zig build-exe --release-fast nbody.zig
// COMMAND LINE:
//  ./nbody 50000000
// MAKE, RUN, CLEANUP:
// zig build-exe --release-fast nbody.zig --name nbody.zig-1.run && time ./nbody.zig-1.run 50000000 && rm nbody.zig-1.run nbody.zig-1.run.o

const std = @import("std");
const warn = std.debug.warn;

const F64Vec2 = @Vector(2, f64);

const pi: f64 = 3.141592653589793;
const solar_mass: f64 = 4.0 * pi * pi;
const year: f64 = 365.24;
const n_bodies: u8 = 5;
const INTERACTIONS_COUNT = @divTrunc(n_bodies * (n_bodies - 1), 2);
const ROUNDED_INTERACTIONS_COUNT = (INTERACTIONS_COUNT + (INTERACTIONS_COUNT % 2));
const dt: f64 = 0.01;

const Body = struct {
    x: @Vector(3, f64),
    v: @Vector(3, f64),
    mass: f64,
};

const bodies = [_]Body{
    // Sun
    .{
        .x = .{ 0.0, 0.0, 0.0 },
        .v = .{ 0.0, 0.0, 0.0 },
        .mass = solar_mass,
    },
    // Jupiter
    .{
        .x = .{ 4.84143144246472090e+00, -1.16032004402742839e+00, -1.03622044471123109e-01 },
        .v = .{ 1.66007664274403694e-03 * year, 7.69901118419740425e-03 * year, -6.90460016972063023e-05 * year },
        .mass = 9.54791938424326609e-04 * solar_mass,
    },
    // Saturn
    .{
        .x = .{ 8.34336671824457987e+00, 4.12479856412430479e+00, -4.03523417114321381e-01 },
        .v = .{ -2.76742510726862411e-03 * year, 4.99852801234917238e-03 * year, 2.30417297573763929e-05 * year },
        .mass = 2.85885980666130812e-04 * solar_mass,
    },
    // Uranus
    .{
        .x = .{ 1.28943695621391310e+01, -1.51111514016986312e+01, -2.23307578892655734e-01 },
        .v = .{ 2.96460137564761618e-03 * year, 2.37847173959480950e-03 * year, -2.96589568540237556e-05 * year },
        .mass = 4.36624404335156298e-05 * solar_mass,
    },
    // Neptune
    .{
        .x = .{ 1.53796971148509165e+01, -2.59193146099879641e+01, 1.79258772950371181e-01 },
        .v = .{ 2.68067772490389322e-03 * year, 1.62824170038242295e-03 * year, -9.51592254519715870e-05 * year },
        .mass = 5.15138902046611451e-05 * solar_mass,
    },
};

pub fn energy(bs: []Body) f64 {
    var e: f64 = 0;
    var delta: @Vector(3, f64) = undefined;

    var i: u8 = 0;
    while (i < bs.len) : (i += 1) {
        const v_squared = bs[i].v * bs[i].v;
        e += 0.5 * bs[i].mass * (v_squared[0] + v_squared[1] + v_squared[2]);

        var j: u8 = i + 1;
        while (j < bs.len) : (j += 1) {
            delta = bs[i].x - bs[j].x;

            const d_squared = delta * delta;
            const d_squared_sum = d_squared[0] + d_squared[1] + d_squared[2];
            const distance = std.math.sqrt(d_squared_sum);

            e -= (bs[i].mass * bs[j].mass) / distance;
        }
    }
    return e;
}

pub fn offsetMomentum(bs: []Body) void {
    for (bs) |body| {
        bs[0].v -= body.v * @splat(3, body.mass / solar_mass);
    }
}

const dts3 = @splat(3, dt);
const dts2 = @splat(2, dt);
const ones = @splat(2, @as(f64, 1.0));

pub fn advance(bs: []Body) void {
    @setFloatMode(.Optimized);

    var position_Deltas: [3][ROUNDED_INTERACTIONS_COUNT]f64 align(@alignOf(F64Vec2)) = undefined;
    var magnitudes: [ROUNDED_INTERACTIONS_COUNT]f64 align(@alignOf(F64Vec2)) = undefined;
    const magnitudes_ptr = @ptrCast([*]F64Vec2, @alignCast(@alignOf(F64Vec2), &magnitudes));

    var i: u8 = 0;
    var k: u8 = 0;
    while (i < n_bodies - 1) : (i += 1) {
        var j: u8 = i + 1;
        while (j < n_bodies) : (j += 1) {
            var m: u8 = 0;
            while (m < 3) : (m += 1)
                position_Deltas[m][k] = bs[i].x[m] - bs[j].x[m];
            k += 1;
        }
    }

    i = 0;
    while (i < ROUNDED_INTERACTIONS_COUNT / 2) : (i += 1) {
        var position_Delta: [3]F64Vec2 = undefined;
        for (position_Delta) |*e, m|
            e.* = @ptrCast([*]F64Vec2, @alignCast(@alignOf(F64Vec2), &position_Deltas[m]))[i];

        const distance_Squared = position_Delta[0] * position_Delta[0] +
            position_Delta[1] * position_Delta[1] +
            position_Delta[2] * position_Delta[2];

        var distance_Reciprocal = ones / @sqrt(distance_Squared);
        magnitudes_ptr[i] = dts2 / distance_Squared * distance_Reciprocal;
    }

    i = 0;
    k = 0;
    while (i < n_bodies - 1) : (i += 1) {
        var j: u8 = i + 1;
        while (j < n_bodies) : (j += 1) {
            const i_mass_magnitude = @splat(3, bs[i].mass * magnitudes[k]);
            const j_mass_magnitude = @splat(3, bs[j].mass * magnitudes[k]);
            const v = @Vector(3, f64){ position_Deltas[0][k], position_Deltas[1][k], position_Deltas[2][k] };
            bs[i].v -= v * j_mass_magnitude;
            bs[j].v += v * i_mass_magnitude;
            k += 1;
        }
    }

    i = 0;
    while (i < n_bodies) : (i += 1) {
        bs[i].x += dts3 * bs[i].v;
    }
}

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);
    var n = try std.fmt.parseInt(usize, args[1], 10);
    const _n = n;
    var bs = bodies;

    offsetMomentum(bs[0..]);
    var e = energy(bs[0..]);
    std.debug.warn("{d:.9}\n", .{e});
    std.debug.assert(std.math.approxEq(f64, e, -0.169075164, 0.000000001));

    while (n > 0) : (n -= 1)
        advance(bs[0..]);

    e = energy(bs[0..]);
    std.debug.warn("{d:.9}\n", .{e});
    if (_n == 50000000) {
        const expected_e = @as(f64, -0.169059907);
        if (!std.math.approxEq(f64, e, expected_e, 0.000000001)) {
            warn("{d:.9} was expected\n", .{expected_e});
            std.debug.assert(false);
        }
    }
}
