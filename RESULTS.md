# Results

cache-anything-new v2.0.0 and cache-apt-pkgs-action v1.6.3, measured in November 2026 on
GitHub-hosted `ubuntu-24.04` runners and in a `debian:13` container. Five repetitions; the
tables show the median.

## Findings

- **Everything restored by cache-anything-new built and passed its checks**: 23 of 23 restored hits,
  including LaTeX fonts, GDAL with BLAS alternatives, CUDA and the Debian container.
- **cache-apt-pkgs breaks packages that need their install scripts.** The LaTeX build fails
  after every restore, with and without `execute_install_scripts` ("Metric (TFM) file or
  installed font not found"; TeX Live builds its font maps and formats in dpkg triggers, which
  are probably not replayed). python-gdal fails without the scripts (`libblas.so.3` is an
  alternative created by a postinst) and works with them.
- **A hit with cache-anything-new takes 1–14 s**, against 9–114 s to install the packages.
  It saves the most when the install is big or the Ubuntu mirror is slow.
- **A miss makes the job about 40–130 s longer than a plain install**, mostly the scan of the
  file system and the upload of the archive (python-gdal shows more because of a slow mirror).
  Per hit, the job is about 100 s shorter for cpp-boost and latex, 34 s for the Debian
  container, and 0–17 s for small, python-gdal, rust-sys and CUDA (only nvcc and cudart). So the
  cache pays off after one hit for big installs (Boost and friends, TeX Live), after about two
  in the container, and barely or never for a few small packages, where cache-apt-pkgs or a
  plain install is the better choice. rust-sys is even a few seconds slower on a hit.
- **Hosted runners restored 18 of 30 hits (60 %).** During these days GitHub served two builds
  of the `ubuntu-24.04` image (`20261111.127.1` and `20261111.370.1`). The key includes the image
  version and the installed packages, so a job on the other build misses on purpose: restoring
  files from a different image is not safe. Every hit on the same build restored. The
  container scenario, with a fixed image, restored 5 of 5.
- **The Ubuntu mirror dominates the timings.** In the validation runs, the same `apt-get
  install` took between 35 s and 23 min. The medians below hide most of these outliers.

## Tables

Runs: 44301367200, 44293016220, 44285130588, 44266366736, 44266321153 (5 repetitions)  
Runner images: container-, ubuntu24-20261111.127.1, ubuntu24-20261111.370.1

Median of all repetitions. *Setup* is the time from before the install (or the
restore) to after it; *Job* is the whole job, including saving the cache in post
steps. *apt download* is the part of the setup spent downloading packages, which
depends on the Ubuntu mirror. Hits only count when the cache was restored.

### small

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 9 | 0 | 0 | 18 | 5/5 | – | – |
| cache-anything-new: miss | 133 | 0 | 0 | 140 | 5/5 | – | 11M, 7.0M |
| cache-anything-new: hit | 1 | – | 0 | 11 | 3/3 | 3/5 | – |
| cache-apt-pkgs: miss | 8 | – | 0 | 16 | 5/5 | – | – |
| cache-apt-pkgs: hit | 10 | – | 0 | 21 | 5/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 15 | – | 0 | 32 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 4 | – | 0 | 13 | 5/5 | 5/5 | – |

### cpp-boost

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 97 | 71 | 8 | 117 | 5/5 | – | – |
| cache-anything-new: miss | 166 | 11 | 5 | 180 | 5/5 | – | 670M, 675M |
| cache-anything-new: hit | 4 | – | 5 | 17 | 4/4 | 4/5 | – |
| cache-apt-pkgs: miss | 59 | – | 6 | 72 | 5/5 | – | – |
| cache-apt-pkgs: hit | 19 | – | 8 | 43 | 5/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 64 | – | 7 | 77 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 35 | – | 8 | 56 | 5/5 | 5/5 | – |

### latex

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 114 | 42 | 1 | 125 | 5/5 | – | – |
| cache-anything-new: miss | 200 | 3 | 0 | 206 | 5/5 | – | 517M, 521M |
| cache-anything-new: hit | 7 | – | 1 | 20 | 2/2 | 2/5 | – |
| cache-apt-pkgs: miss | 101 | – | 1 | 108 | 5/5 | – | – |
| cache-apt-pkgs: hit | 19 | – | 5 | 33 | 0/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 245 | – | 1 | 255 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 18 | – | 4 | 31 | 0/5 | 5/5 | – |

### python-gdal

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 16 | 2 | 0 | 24 | 5/5 | – | – |
| cache-anything-new: miss | 392 | 215 | 0 | 411 | 5/5 | – | 150M, 154M, 155M |
| cache-anything-new: hit | 3 | – | 0 | 9 | 3/3 | 3/5 | – |
| cache-apt-pkgs: miss | 19 | – | 0 | 26 | 5/5 | – | – |
| cache-apt-pkgs: hit | 6 | – | 0 | 14 | 0/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 26 | – | 0 | 32 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 14 | – | 1 | 23 | 5/5 | 5/5 | – |

### rust-sys

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 11 | 1 | 20 | 38 | 5/5 | – | – |
| cache-anything-new: miss | 143 | 1 | 24 | 171 | 5/5 | – | 20M, 24M |
| cache-anything-new: hit | 6 | – | 25 | 43 | 3/3 | 3/5 | – |
| cache-apt-pkgs: miss | 15 | – | 20 | 41 | 5/5 | – | – |
| cache-apt-pkgs: hit | 4 | – | 18 | 29 | 5/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 17 | – | 20 | 44 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 18 | – | 22 | 51 | 5/5 | 5/5 | – |

### cuda

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 24 | – | 1 | 33 | 5/5 | – | – |
| cache-anything-new: miss | 146 | – | 2 | 157 | 5/5 | – | 418M, 422M |
| cache-anything-new: hit | 4 | – | 3 | 16 | 3/3 | 3/5 | – |

### debian-cpp

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 48 | 5 | 3 | 69 | 5/5 | – | – |
| cache-anything-new: miss | 92 | 4 | 2 | 112 | 5/5 | – | 1.6G |
| cache-anything-new: hit | 14 | – | 3 | 35 | 5/5 | 5/5 | – |

### Failed builds

- latex · apt · hit: 5
- latex · apt-scripts · hit: 5
- python-gdal · apt · hit: 5

[exited with code 0]
