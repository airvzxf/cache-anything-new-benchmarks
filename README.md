# Cache Anything New: benchmarks

Real projects that install system packages and toolchains, built with and without
[cache-anything-new-action](https://github.com/airvzxf/cache-anything-new-action), to measure how
much time the cache saves and to check that everything still builds after a restore.

## Results

See [RESULTS.md](RESULTS.md). In short, with cache-anything-new v2.0.0:

- Every restore built and passed its checks, also where cache-apt-pkgs-action breaks (LaTeX
  fonts, BLAS alternatives for GDAL).
- A hit takes 1–14 s; a miss makes the job about 40–130 s longer than a plain install.
- It pays off after one hit for big installs (Boost and friends, TeX Live) and not for a few
  small packages.

## Scenarios

| Scenario | What it installs | What it checks |
|---|---|---|
| `small` | jq, tree | Both run |
| `cpp-boost` | Boost, SDL2, GLEW, OpenAL, FreeType, Vorbis, CMake | CMake build and a ctest self-test |
| `latex` | TeX Live XeTeX, Noto fonts, poppler | XeLaTeX PDF with the embedded font and text |
| `python-gdal` | GDAL with Python and NumPy | GeoTIFF, reprojection and `ogr2ogr` |
| `rust-sys` | OpenSSL headers, protoc | `cargo test` and run with `openssl` and `prost` |
| `cuda` | CUDA nvcc and cudart (Jimver/cuda-toolkit) | Compiles a kernel |
| `debian-cpp` | Same as `cpp-boost` in a `debian:13` container | Same as `cpp-boost` |

Each scenario runs without a cache, then as a miss and a hit with cache-anything-new and with
cache-apt-pkgs-action (with and without `execute_install_scripts`). cache-apt-pkgs-action is
left out for CUDA, which is not installed with apt, and for the container, where it needs sudo.

## Running it

Run the **Benchmark** workflow from the Actions tab (or `gh workflow run benchmark.yml`) once
per repetition; the runs queue one after another. Every run uses its own cache keys and deletes
its caches at the end. Then aggregate the runs:

```sh
scripts/report.py RUN_ID [RUN_ID ...] > report.md
```

Pushes to other branches than `main` run the benchmark too, to test changes to it.
