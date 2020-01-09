// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// Contributed by Mr Ledrug
// Translated to zig by Travis Staloch
// MAKE:
// $ zig build-exe pidigits-gmp.zig -lgmp -lc --library-path /usr/lib/x86_64-linux-gnu/ -isystem /usr/include/x86_64-linux-gnu/

const std = @import("std");

const gmp = @cImport(@cInclude("gmp.h"));
const c = @cImport(@cInclude("stdio.h"));

const ui = u32;
var tmp1: gmp.mpz_t = undefined;
var tmp2: gmp.mpz_t = undefined;
var acc: gmp.mpz_t = undefined;
var den: gmp.mpz_t = undefined;
var num: gmp.mpz_t = undefined;

pub fn main() !void {
    const a = std.heap.page_allocator;
    const args = try std.process.argsAlloc(a);
    defer std.process.argsFree(a, args);
    const n = try std.fmt.parseInt(u32, args[1], 10);
    const stdout = &std.io.getStdOut().outStream().stream;
    var buf: [10]u8 = undefined;

    gmp.mpz_init(&tmp1);
    gmp.mpz_init(&tmp2);

    gmp.mpz_init_set_ui(&acc, 0);
    gmp.mpz_init_set_ui(&den, 1);
    gmp.mpz_init_set_ui(&num, 1);

    var k: u32 = 0;
    var i: u32 = 0;
    while (i < n) {
        k += 1;
        next_term(k);
        if (gmp.mpz_cmp(&num, &acc) > 0)
            continue;

        const d = extract_digit(3);
        if (d != extract_digit(4))
            continue;

        _ = c.putchar('0' + @truncate(u8, d));
        i += 1;

        if (i % 10 == 0) {
            _ = c.printf("\t:%u\n", i);
        }
        eliminate_digit(d);
    }
}

fn extract_digit(nth: ui) ui {
    // joggling between tmp1 and tmp2, so GMP won't have to use temp buffers
    gmp.mpz_mul_ui(&tmp1, &num, nth);
    gmp.mpz_add(&tmp2, &tmp1, &acc);
    gmp.mpz_tdiv_q(&tmp1, &tmp2, &den);
    return mpz_get_ui(&tmp1);
}

fn mpz_get_ui(__gmp_z: gmp.mpz_srcptr) ui {
    const __gmp_p = __gmp_z[0]._mp_d;
    const __gmp_n = __gmp_z[0]._mp_size;
    const __gmp_l = __gmp_p[0];
    return @intCast(ui, if (__gmp_n != 0) __gmp_l else 0);
}

fn eliminate_digit(d: ui) void {
    gmp.mpz_submul_ui(&acc, &den, d);
    gmp.mpz_mul_ui(&acc, &acc, 10);
    gmp.mpz_mul_ui(&num, &num, 10);
}

fn next_term(k: ui) void {
    const k2 = k * 2 + 1;

    gmp.mpz_addmul_ui(&acc, &num, 2);
    gmp.mpz_mul_ui(&acc, &acc, k2);
    gmp.mpz_mul_ui(&den, &den, k2);
    gmp.mpz_mul_ui(&num, &num, k);
}
