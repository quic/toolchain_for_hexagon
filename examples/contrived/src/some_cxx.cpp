// Copyright(c) 2024 Qualcomm Innovation Center, Inc. All Rights Reserved.
// SPDX-License-Identifier: BSD-3-Clause

#include <stdint.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc23-extensions"

static const int32_t raw_data[] = {
#embed "lut.dat"
};
#pragma clang diagnostic pop


#define ARRAY_ELTS(x) (sizeof(x) / sizeof(x[0]))

int32_t get_val(unsigned int index) {
    return raw_data[index % ARRAY_ELTS(raw_data)];
}

extern "C" uint64_t get_cycles() {
    return __builtin_readcyclecounter();
}

#if !defined(__clang_major__) || __clang_major__ < 19
#error "requires clang 19.1.x or later"
#endif

extern "C" uint64_t get_time() {
    return __builtin_readsteadycounter();
}
