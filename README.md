# Cache Anything New: benchmarks

Real projects that install system packages and toolchains, built with and without
[cache-anything-new-action](https://github.com/airvzxf/cache-anything-new-action), to measure how
much time the cache saves and to check that everything still builds after a restore.

## Results

See [RESULTS.md](RESULTS.md). In short, with cache-anything-new v2.1.0:

- Every restore built and passed its checks, also where cache-apt-pkgs-action breaks (LaTeX
  fonts, BLAS alternatives for GDAL).
- A miss costs about the same as a plain install (a few seconds more), and a hit takes
  1–7 s on hosted runners, so the cache pays off from the first hit: for example 85 → 22 s for
  the C++/Boost job and 84 → 12 s for the LaTeX job.
- Hosted `ubuntu-24.04` runners come in two variants (clouds), and each one builds its own
  cache.

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

## When to run a new round

Run a round for every release of cache-anything-new that can change its timing, not for every
release:

- a change to what runs on a miss or a hit: how changes are detected (fanotify or the scan),
  how the archive is built, compressed or extracted;
- a new major version of `actions/cache`, which uploads and downloads the archive;
- a new runner image, such as `ubuntu-26.04`, even without a release of the action;
- a new version of cache-apt-pkgs-action, to keep the comparison current.

Releases that only change docs, tests or messages keep the last round. Compare each round with
its own "No cache" row and not with older rounds: the same job varies by several seconds
between runners (the cloud, the apt mirror, the image build of the day).

## Running a round

1. Pin the new version in [`_measure.yml`](.github/workflows/_measure.yml) (the three `uses:` of
   `airvzxf/cache-anything-new-action`), and merge that to `main`.
2. Run five repetitions and write the report (needs `gh`, authenticated, and `jq`):

   ```sh
   scripts/round.sh -o report.md            # all scenarios, 5 runs on main
   scripts/round.sh -n 2 -s small -r BRANCH # a quick check of a change to the benchmark
   ```

   It dispatches the **Benchmark** workflow one run at a time and checks each result before
   starting the next. Every run uses its own cache keys and
   deletes its caches at the end. A failed run is replaced, up to two times.
3. Add the round at the top of [RESULTS.md](RESULTS.md): the version and commit, the run ids,
   the findings and the tables of `report.md`. Keep the older rounds below it, and update the
   summary at the top of this README.

To aggregate runs by hand: `scripts/report.py [--scenarios a,b] RUN_ID [RUN_ID ...]`.

Pushes to other branches than `main` run the benchmark too, to test changes to it.
