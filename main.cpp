#include <fmt/core.h>
#include <sodium.h>

int main() {
  fmt::print("Hello fmt :-)\n");

  if (sodium_init() < 0) {
    fmt::print("Sodium did not react. Exiting...");
    return 0;
  }

  fmt::print("Sodium is ready!");
}