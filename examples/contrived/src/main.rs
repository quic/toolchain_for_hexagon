// Copyright(c) 2024 Qualcomm Innovation Center, Inc. All Rights Reserved.
// SPDX-License-Identifier: BSD-3-Clause

use std::env;

extern "C" {
    fn read_activity() -> u64;
    fn get_cycles() -> u64;
    fn get_time() -> u64;
}

fn fibonacci(n: u32) -> u32 {
    match n {
        0 => 1,
        1 => 1,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn main() {
    let arg: String = env::args().nth(1).unwrap_or("16".to_string());
    let in_val = arg.parse::<u32>().unwrap_or(16);

    let t0 = unsafe { read_activity() };
    let v = fibonacci(in_val);
    let dur_cycl = unsafe { read_activity() } - t0;

    println!("fibonacci({}): {}", in_val, v);
    println!("cycles elapsed: {}", dur_cycl);

    let t0 = unsafe { get_cycles() };
    let v_ = fibonacci(in_val);
    let t_end = unsafe { get_cycles() } - t0;

    println!("fibonacci({}): {}", in_val, v_);
    println!("cycles elapsed: {}", t_end);

    println!("cur time: {}", unsafe { get_time() });
}
