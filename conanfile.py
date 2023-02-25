from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain
from conan.tools.files import copy
import os


class HelloConanCmake(ConanFile):
    requires = ["fmt/9.1.0", "libsodium/1.0.18"]
    settings = "os", "compiler", "build_type", "arch"
    options = {"build_shared": [False, True]}
    default_options = {"build_shared": False}

    def config_options(self):
        if self.options.build_shared:
            self.options["*"].shared = True

    def configure(self):
        # NOTE: Conan dependencies have no debug (pdb) symbols. If we want debugger
        # support, run conan install . --build DEP_YOU_WANT_TO_DEBUG or
        # conan install . --build * to build everything.
        pass

    def generate(self):
        tc = CMakeToolchain(self)
        # Disable generating user presets file.
        # Presets file is manually managed
        tc.user_presets_path = False
        tc.generate()
        cmake = CMakeDeps(self)
        cmake.generate()
        # Don't check for build shared before copying dlls.
        # Useful when a library can only be built as a dynamic library
        for dep in self.dependencies.values():
            for bin_dir in dep.cpp_info.bindirs:
                copy(self, "*.dll", bin_dir, os.path.join(self.generators_folder, "bin", str(self.settings.build_type)))
