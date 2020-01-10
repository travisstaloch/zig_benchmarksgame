// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// Contributed by Mr Ledrug
// Translated to zig by Travis Staloch
// MAKE:
// $ zig build-exe pidigits-gmp.zig -lgmp -lc --library-path /usr/lib/x86_64-linux-gnu/ -isystem /usr/include/x86_64-linux-gnu/

const std = @import("std");
const c = std.c;

pub extern "c" fn putchar(u8) c_int;

const gmp = @cImport(@cInclude("gmp.h"));
pub extern fn __gmpz_init(gmp.mpz_t) void;
pub extern fn __gmpz_init_set_ui(gmp.mpz_t, ui) void;
pub extern fn __gmpz_add(gmp.mpz_t, gmp.mpz_t, gmp.mpz_t) void;
pub extern fn __gmpz_mul_ui(gmp.mpz_t, gmp.mpz_t, ui) void;
pub extern fn __gmpz_tdiv_q(gmp.mpz_t, gmp.mpz_t, gmp.mpz_t) void;
pub extern fn __gmpz_addmul_ui(gmp.mpz_t, gmp.mpz_t, ui) void;
pub extern fn __gmpz_submul_ui(gmp.mpz_t, gmp.mpz_t, ui) void;
pub extern fn __gmpz_cmp(gmp.mpz_t, gmp.mpz_t) c_int;
pub extern fn __gmpz_get_ui(gmp.mpz_t) ui;

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

    __gmpz_init(tmp1);
    __gmpz_init(tmp2);

    __gmpz_init_set_ui(acc, 0);
    __gmpz_init_set_ui(den, 1);
    __gmpz_init_set_ui(num, 1);

    var k: u32 = 0;
    var i: u32 = 0;
    while (i < n) {
        k += 1;
        next_term(k);
        if (__gmpz_cmp(num, acc) > 0)
            continue;

        const d = extract_digit(3);
        if (d != extract_digit(4))
            continue;

        _ = putchar('0' + @truncate(u8, d));
        i += 1;

        if (i % 10 == 0) {
            _ = c.printf("\t:%u\n", i);
        }
        eliminate_digit(d);
    }
}

fn extract_digit(nth: ui) ui {
    // joggling between tmp1 and tmp2, so GMP won't have to use temp buffers
    __gmpz_mul_ui(tmp1, num, nth);
    __gmpz_add(tmp2, tmp1, acc);
    __gmpz_tdiv_q(tmp1, tmp2, den);
    return __gmpz_get_ui(tmp1);
}

fn eliminate_digit(d: ui) void {
    __gmpz_submul_ui(acc, den, d);
    __gmpz_mul_ui(acc, acc, 10);
    __gmpz_mul_ui(num, num, 10);
}

fn next_term(k: ui) void {
    const k2 = k * 2 + 1;

    __gmpz_addmul_ui(acc, num, 2);
    __gmpz_mul_ui(acc, acc, k2);
    __gmpz_mul_ui(den, den, k2);
    __gmpz_mul_ui(num, num, k);
}
