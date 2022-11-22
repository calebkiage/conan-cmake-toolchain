from conan import ConanFile


class HelloConanCmake(ConanFile):
    requires = ["fmt/9.1.0", "libsodium/1.0.18"]
    settings = "os", "compiler", "build_type", "arch"
    generators = ["CMakeDeps", "CMakeToolchain"]
    options = {"build_shared": [False, True]}
    default_options = {"build_shared": False}

    def configure(self):
        # Conan dependencies have no debug (pdb) symbols. If we want debugger
        # support, run conan install . --build DEP_YOU_WANT_TO_DEBUG or
        # conan install . --build * to build everything.
        if self.options.build_shared:
            self.options["*"].shared = True

    def imports(self):
        # Add this directory to PATH on Windows to allow running
        # executables in the binary directory
        self.copy("*.dll", f"bin/{self.settings.build_type}", "@bindirs")
