// Copyright(c) 2024 Qualcomm Innovation Center, Inc. All Rights Reserved.
// SPDX-License-Identifier: BSD-3-Clause

const builtin = @import("builtin");

// Ehh...it's not really the same thing between these
// architectures, but ¯\_(ツ)_/¯ we are just illustrating
// concepts here...

export fn read_activity() u64 {
    if (comptime builtin.cpu.arch == .hexagon) {
        return asm volatile ("%[value] = upcycle"
            : [value] "=&r" (-> u64),
        );
    } else if (comptime builtin.cpu.arch == .x86_64) {
        var high: u64 = 0;
        var low: u64 = 0;

        asm volatile (
            \\rdtsc
            : [low] "={eax}" (low),
              [high] "={edx}" (high),
        );
        return (@as(u64, high) << 32) | @as(u64, low);
    } else {
        const std = @import("std");
        const msg = std.fmt.comptimePrint("unsupported architecture: '{s}'", .{@tagName(builtin.cpu.arch)});

        @compileError(msg);
    }
}
