// Copyright(c) 2024 Qualcomm Innovation Center, Inc. All Rights Reserved.
// SPDX-License-Identifier: BSD-3-Clause

use std::process::Command;

fn main() {
    println!("cargo::rerun-if-changed=src/hex_sys.cpp");

    cc::Build::new()
        .file("src/some_cxx.cpp")
        .compile("libsome_cxx.a");
    println!("cargo:rustc-link-lib=some_cxx");

    let arch = build_target::target_arch().unwrap();
    let arch = arch.as_str();

    let zig_tgt = match arch {
        "hexagon" => "hexagon-freestanding",
        "x86_64" => "x86_64-linux-gnu",
        _ => panic!("unsupported target"),
    };

    println!("cargo::rerun-if-changed=src/some_sys.zig");
    let rc = Command::new("zig")
        .arg("build-lib")
        .arg("-fPIC")
        .arg("-target")
        .arg(zig_tgt)
        .arg("src/some_sys.zig")
        .status()
        .expect("failed to spawn process");
    assert!(rc.success());

    println!("cargo:rustc-link-search=.");
    println!("cargo:rustc-link-lib=some_sys");
}
