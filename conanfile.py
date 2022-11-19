from conan import ConanFile

# conan install . -if ./build/default -pr:b .\.conan-profiles\default

class HelloConanCmake(ConanFile):
    requires = ["fmt/9.1.0", "libsodium/1.0.18"]
    settings = "os", "compiler", "build_type", "arch"
    generators = ["CMakeDeps", "CMakeToolchain"]
    
    def configure(self):
        # Statically link conan dependencies on Windows if the build type
        # is Debug
        # Conan dependencies have no debug (pdb) symbols. If we want debugger
        # support, run conan install . --build DEP_YOU_WANT_TO_DEBUG or
        # conan install . --build * to debug everything.
        if self.settings.os == "Windows" and self.settings.build_type == "Debug":
            self.options["*"].shared = False

