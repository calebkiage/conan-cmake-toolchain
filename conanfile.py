from conan import ConanFile
from conan.tools.cmake import CMakeToolchain
from conan.tools.microsoft import MSBuildToolchain

# conan install . -if ./build/default -pr:b .\.conan-profiles\default

class HelloConanCmake(ConanFile):
    requires = ["fmt/9.1.0", "libsodium/1.0.18"]
    settings = "os", "compiler", "build_type", "arch"
    generators = ["CMakeDeps", "CMakeToolchain"]
    
    def configure(self):
        # Statically link conan dependencies on Windows.
        # Conan dependencies have no debug (pdb) symbols. If we want debugger
        # support, run conan install . --build DEP_YOU_WANT_TO_DEBUG or
        # conan install . --build * to debug everything.
        if self.settings.os == "Windows":
            self.options["*"].shared = False


