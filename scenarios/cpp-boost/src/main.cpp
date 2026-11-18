// Links against every library the scenario installs and checks that each one works
// without a display or audio device.
#include <boost/filesystem.hpp>
#include <boost/program_options.hpp>
#include <SDL.h>
#include <GL/glew.h>
#include <AL/alc.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <vorbis/codec.h>

#include <cstdlib>
#include <iostream>

namespace fs = boost::filesystem;
namespace po = boost::program_options;

static int fail(const char* what) {
  std::cerr << "FAIL: " << what << '\n';
  return EXIT_FAILURE;
}

int main(int argc, char** argv) {
  po::options_description options("Options");
  options.add_options()("self-test", "check every library");
  po::variables_map vm;
  po::store(po::parse_command_line(argc, argv, options), vm);
  if (!vm.count("self-test")) {
    std::cout << options;
    return EXIT_SUCCESS;
  }

  const fs::path tmp = fs::temp_directory_path() / fs::unique_path();
  fs::create_directories(tmp);
  if (!fs::is_directory(tmp)) return fail("boost::filesystem");
  fs::remove_all(tmp);

  SDL_version sdl;
  SDL_GetVersion(&sdl);
  if (SDL_Init(0) != 0) return fail("SDL_Init");
  SDL_Quit();

  const auto* glew = reinterpret_cast<const char*>(glewGetString(GLEW_VERSION));
  if (glew == nullptr) return fail("GLEW");

  ALCint major = 0;
  alcGetIntegerv(nullptr, ALC_MAJOR_VERSION, 1, &major);

  FT_Library ft;
  if (FT_Init_FreeType(&ft) != 0) return fail("FreeType");
  FT_Int ft_major, ft_minor, ft_patch;
  FT_Library_Version(ft, &ft_major, &ft_minor, &ft_patch);
  FT_Done_FreeType(ft);

  std::cout << "Boost " << BOOST_VERSION / 100000 << '.' << BOOST_VERSION / 100 % 1000
            << ", SDL " << int(sdl.major) << '.' << int(sdl.minor) << '.' << int(sdl.patch)
            << ", GLEW " << glew << ", OpenAL ALC " << major << ", FreeType " << ft_major
            << '.' << ft_minor << '.' << ft_patch << ", " << vorbis_version_string() << '\n';
  return EXIT_SUCCESS;
}
