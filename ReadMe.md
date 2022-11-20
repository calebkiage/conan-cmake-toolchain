# Conan CMake Toolchain

Allows running Conan and installing dependencies automatically for use in CMake projects.
Uses CMakeDeps and CMakeToolchain conan generators.

## Usage:

### CMake >= 3.21

```shell
$ cmake --preset=default
$ cmake --build --preset=default
```


### CMake >= 3.15

```shell
$ cmake -DCONAN_FORCE_BUILD_PACKAGES=OFF -DCONAN_BUILD_PROFILE="./.conan/profiles/default/build" -DCONAN_HOST_PROFILE="./.conan/profiles/default/host" -DCMAKE_TOOLCHAIN_FILE="./.conan/conan_default_toolchain.cmake" -S. -B"./build/default" -G "Visual Studio 17 2022"

$ cmake --build "./build/default" --config Release
```

## Available CMake Cache Variables
`CONAN_FORCE_BUILD_PACKAGES`: Forces local building of packages. Useful for having local debug symbols in the Debug profile. Example values `false` or `"OFF"`, `"<lib1>;<lib2>...<libn>"`

`CONAN_<BUILD|HOST>_<CONF|PROFILE|SETTINGS>`: Translates to `--<conf|profile|settings>:<build|host>` command option. e.g. `CONAN_HOST_PROFILE` becomes `--profile:host`

`CONAN_TOOLCHAIN_FILE`: The path to the generated conan toolchain file. If this is not defined, the default location (`${CMAKE_BINARY_DIR}/conan_toolchain.cmake`) is used.
