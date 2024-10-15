# Contrived example

This is a contrived example to demonstrate some toolchains targeting
hexagon linux.  Here we illustrate how to use Rust, Zig, and C++ to
write programs portable to hexagon similarly to how one would
target other architectures.

We can use the upstream Rust toolchain with lld to make programs for hexagon
linux.  There might be yet-undiscovered bugs, but there's no known limitations
for this platform.

As of September 2024, Zig does not yet have support for hexagon linux, only
`hexagon-freestanding` (baremetal hexagon).  This is primarily because the
C library support is not yet upstreamed to `musl`.  As a consequence we
cannot yet `@import("std")`.  Also, with any zig code, compiler-emitted
calls to the compiler builtin libraries could result in some "unresolved
symbol" link errors.  These could probably be solved with some creative
workarounds/linker command-line overrides.  See the [issue at the
zig project for details](https://github.com/ziglang/zig/issues/21579).

## Dependencies

[Download zig](https://ziglang.org/download/), unpack the tarball and put
the `zig` executable in your `PATH`.

[Install rust using the instructions from the Rust Project website](https://www.rust-lang.org/learn/get-started)
and then install the nightly:

    rustup toolchain install nightly
    rustup override set nightly
    rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu

Download and install the hexagon open source toolchain from https://github.com/quic/toolchain_for_hexagon/releases - version 19.1.0 or later.

## Setup

Edit the `.cargo/config` to point to your toolchain's C library:

    ...
    runner = "qemu-hexagon -L /inst/clang+llvm-19.1.0-cross-hexagon-unknown-linux-musl/x86_64-linux-gnu/target/hexagon-unknown-linux-musl/usr"
    ...


## Build and run

Build/run the demo with QEMU hexagon:

    export TARGET_CC=hexagon-unknown-linux-musl-clang
    export PATH=/inst/clang+llvm-19.1.0-cross-hexagon-unknown-linux-musl/x86_64-linux-gnu/bin/:$PATH
    export QEMU_LD_PREFIX=/inst/clang+llvm-19.1.0-cross-hexagon-unknown-linux-musl/x86_64-linux-musl/target/hexagon-unknown-linux-musl/usr/

    cargo +nightly build --target=hexagon-unknown-linux-musl -Zbuild-std  -Zbuild-std-features=llvm-libunwind
    cargo +nightly run --target=hexagon-unknown-linux-musl -Zbuild-std  -Zbuild-std-features=llvm-libunwind

Try experimenting with some different input arguments to see how this impacts
the cycles consumed.

As a simpler reference, you can also run this natively on an `x86_64` host
(you might need to manually clean up some `*.a` / `*.a.o` files):

    CXX=clang++ CC=clang cargo run --target=x86_64-unknown-linux-gnu

