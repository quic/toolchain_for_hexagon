
# Examples of the Opensource Hexagon Toolchain

* Building/running C, C++ programs for linux

```
$ wget https://artifacts.codelinaro.org/artifactory/codelinaro-toolchain-for-hexagon/18.1.0-rc1_02/clang+llvm-18.1.0-rc1-cross-hexagon-unknown-linux-musl.tar.xz
$ sudo tar xf clang+llvm-18.1.0-rc1-cross-hexagon-unknown-linux-musl.tar.xz -C /opt
$ export PATH=/opt/clang+llvm-18.1.0-rc1-cross-hexagon-unknown-linux-musl/x86_64-linux-gnu/bin:$PATH
$ cat <<EOF > example.cpp
#include <iostream>

int main(int argc, const char *argv[]) {
    std::cout << "Hello, world!\n";
}
EOF
$ hexagon-unknown-linux-musl-clang++ -static -o ./example_static example.cpp
$ qemu-hexagon ./example_static
Hello, world!

$ hexagon-unknown-linux-musl-clang++ -o ./example example.cpp
$ qemu-hexagon -L /opt/clang+llvm-18.1.0-rc1-cross-hexagon-unknown-linux-musl/x86_64-linux-gnu/target/hexagon-unknown-linux-musl ./example
Hello, world!

```

* See [demo of Rust + zig](contrived/README.md)
