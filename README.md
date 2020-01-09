# zig_benchmarksgame
benchmarksgame implementations in zig

https://benchmarksgame-team.pages.debian.net/benchmarksgame/description/summary.html

Until I figure out how to publish these solutions on the benchmarksgame website, I will keep them here.

# measurements
Some very naive performance measurements.  These are simply first run timings.
```
OS: Debian GNU/Linux 10 (buster) x86_64
CPU: Intel i7-4790 (8) @ 4.000GHz
```

### nbody
```sh
$ time ./nbody.gcc-8.gcc_run 50000000 #c
-0.169075164
-0.169059907

real	0m2.501s
user	0m2.479s
sys	0m0.012s
```

```sh
$ time ./nbody.zig-1.run 50000000 #zig
-0.169075164
-0.169059907

real	0m2.483s
user	0m2.483s
sys	0m0.000s
```

### spectralnorm
```sh
$ time ./spectralnorm.gcc-5.gcc_run 5500 #c
1.274224153

real	0m0.636s
user	0m4.562s
sys	0m0.028s
```

```sh
$ time ./spectralnorm 5500 #zig
1.274224153

real	0m0.586s
user	0m4.291s
sys	0m0.052s
```

```sh
$ time ./spectralnorm.go.run 5500 #go
1.274224153

real	0m1.141s
user	0m4.514s
sys	0m0.004s
```

```sh
# TODO: make this concurrent
$ time ./spectralnorm.go.zig.run 5500 #zig
1.274224153

real	0m4.399s
user	0m4.377s
sys	0m0.016s
```

### pidigits
```sh
$ time ./pidigits.gcc-1_run 10000 #c
...
real	0m0.646s
user	0m0.645s
sys	0m0.000s
```

```sh
$ time ./pidigits-gmp 10000 #zig
...
real	0m0.642s
user	0m0.638s
sys	0m0.004s
```