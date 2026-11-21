# Results

Five repetitions per version on GitHub-hosted `ubuntu-24.04` runners and in a `debian:13`
container; the tables show the median. Compared with cache-apt-pkgs-action v1.6.3.

## v2.1.0 (fanotify detection), 21 November 2026

cache-anything-new at commit `361efb7` (main after
[PR #8](https://github.com/airvzxf/cache-anything-new-action/pull/8)).

### Findings

- **A miss now costs about the same as a plain install.** The job was 3–7 s longer than
  without a cache on hosted runners (rust-sys was even 6 s shorter), against 40–130 s with
  v2.0.0. Detecting the changed files takes about a second with fanotify instead of one or two
  minutes of scanning. The Debian container has no `python3`, so it still scans (+43 s).
- **Every hit saves time.** Job time without a cache → on a hit: cpp-boost 85 → 22 s, latex
  84 → 12 s, python-gdal 43 → 13 s, CUDA 45 → 18 s, rust-sys 50 → 30 s, Debian container
  62 → 40 s, small 23 → 19 s. So the cache pays off from the first hit.
- **Everything restored built and passed its checks**: 23 of 23 restored hits.
- **Hosted runners restored 18 of 30 hits.** `ubuntu-24.04` runs on two clouds (the kernel
  ends in `-azure` or `-aws`), with different image builds and packages, so the key differs on
  purpose; every hit on the same variant restored. This benchmark makes one miss and one hit
  per key, so the hit lands on the other variant about half of the time. In regular use each
  variant builds its cache on its first miss and restores it from then on. The container,
  with a fixed image, restored 5 of 5.
- **cache-apt-pkgs-action could not install cpp-boost and latex in any run.** Its download
  got `404 Not Found` from `security.ubuntu.com` for packages that had just received a security
  update (mesa for cpp-boost, OpenJDK 21 for latex), and it still reported success and saved a cache with 0 packages, so the
  builds failed on the miss and on the hit. A plain `apt-get update && apt-get install` in the
  same runs worked. python-gdal again failed after its restore without
  `execute_install_scripts`.
- **The Ubuntu mirror was fast this time**: the apt download took 0–26 s in every job.

### Tables

Runs: 44921492419, 44921131195, 44920771556, 44920412848, 44920059016 (5 repetitions)  
Runner images: container- (aws), container- (azure), ubuntu24-20261116.133.1 (aws), ubuntu24-20261116.376.1 (azure)

Median of all repetitions. *Setup* is the time from before the install (or the
restore) to after it; *Job* is the whole job, including saving the cache in post
steps. *apt download* is the part of the setup spent downloading packages, which
depends on the mirror; *Setup without download* is the rest, which is what the caching
actions change. Hits only count when the cache was restored.

#### small

| Variant | Setup (s) | apt download (s) | Setup without download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| No cache | 12 | 0 | 12 | 0 | 23 | 5/5 | – | – |
| cache-anything-new: miss | 16 | 0 | 16 | 0 | 29 | 5/5 | – | 11M |
| cache-anything-new: hit | 7 | – | – | 0 | 19 | 3/3 | 3/5 | – |
| cache-apt-pkgs: miss | 16 | – | – | 0 | 29 | 5/5 | – | – |
| cache-apt-pkgs: hit | 6 | – | – | 0 | 13 | 5/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 13 | – | – | 0 | 28 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 14 | – | – | 0 | 27 | 5/5 | 5/5 | – |

#### cpp-boost

| Variant | Setup (s) | apt download (s) | Setup without download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| No cache | 65 | 21 | 43 | 6 | 85 | 5/5 | – | – |
| cache-anything-new: miss | 72 | 22 | 53 | 6 | 89 | 5/5 | – | 714M, 718M |
| cache-anything-new: hit | 6 | – | – | 5 | 22 | 2/2 | 2/5 | – |
| cache-apt-pkgs: miss | 18 | – | – | 1 | 26 | 0/5 | – | – |
| cache-apt-pkgs: hit | 11 | – | – | 2 | 23 | 0/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 24 | – | – | 3 | 35 | 0/5 | – | – |
| cache-apt-pkgs + scripts: hit | 4 | – | – | 2 | 13 | 0/5 | 5/5 | – |

#### latex

| Variant | Setup (s) | apt download (s) | Setup without download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| No cache | 73 | 4 | 67 | 0 | 84 | 5/5 | – | – |
| cache-anything-new: miss | 78 | 4 | 73 | 0 | 89 | 5/5 | – | 521M |
| cache-anything-new: hit | 6 | – | – | 1 | 12 | 3/3 | 3/5 | – |
| cache-apt-pkgs: miss | 14 | – | – | 0 | 21 | 0/5 | – | – |
| cache-apt-pkgs: hit | 6 | – | – | 0 | 13 | 0/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 27 | – | – | 0 | 37 | 0/5 | – | – |
| cache-apt-pkgs + scripts: hit | 10 | – | – | 0 | 20 | 0/5 | 5/5 | – |

#### python-gdal

| Variant | Setup (s) | apt download (s) | Setup without download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| No cache | 31 | 4 | 26 | 0 | 43 | 5/5 | – | – |
| cache-anything-new: miss | 37 | 5 | 31 | 0 | 50 | 5/5 | – | 150M, 154M |
| cache-anything-new: hit | 2 | – | – | 0 | 13 | 5/5 | 5/5 | – |
| cache-apt-pkgs: miss | 31 | – | – | 0 | 44 | 5/5 | – | – |
| cache-apt-pkgs: hit | 7 | – | – | 0 | 16 | 0/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 36 | – | – | 0 | 49 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 19 | – | – | 1 | 33 | 5/5 | 5/5 | – |

#### rust-sys

| Variant | Setup (s) | apt download (s) | Setup without download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| No cache | 22 | 1 | 21 | 18 | 50 | 5/5 | – | – |
| cache-anything-new: miss | 14 | 1 | 14 | 20 | 44 | 5/5 | – | 20M, 24M |
| cache-anything-new: hit | 1 | – | – | 18 | 30 | 3/3 | 3/5 | – |
| cache-apt-pkgs: miss | 26 | – | – | 20 | 59 | 5/5 | – | – |
| cache-apt-pkgs: hit | 10 | – | – | 20 | 47 | 5/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 14 | – | – | 20 | 50 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 11 | – | – | 19 | 43 | 5/5 | 5/5 | – |

#### cuda

| Variant | Setup (s) | apt download (s) | Setup without download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| No cache | 32 | – | – | 3 | 45 | 5/5 | – | – |
| cache-anything-new: miss | 35 | – | – | 3 | 48 | 5/5 | – | 422M |
| cache-anything-new: hit | 3 | – | – | 4 | 18 | 2/2 | 2/5 | – |

#### debian-cpp

| Variant | Setup (s) | apt download (s) | Setup without download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| No cache | 43 | 4 | 39 | 3 | 62 | 5/5 | – | – |
| cache-anything-new: miss | 87 | 4 | 84 | 2 | 105 | 5/5 | – | 1.6G |
| cache-anything-new: hit | 18 | – | – | 3 | 40 | 5/5 | 5/5 | – |

#### apt download time by runner

| Runner | Jobs | Median (s) | Min (s) | Max (s) |
|---|---:|---:|---:|---:|
| container- (aws) | 5 | 4 | 3 | 5 |
| container- (azure) | 5 | 4 | 4 | 4 |
| ubuntu24-20261116.133.1 (aws) | 37 | 4 | 0 | 26 |
| ubuntu24-20261116.376.1 (azure) | 22 | 2 | 0 | 25 |

#### Failed builds

- cpp-boost · apt · hit: 5
- cpp-boost · apt · miss: 5
- cpp-boost · apt-scripts · hit: 5
- cpp-boost · apt-scripts · miss: 5
- latex · apt · hit: 5
- latex · apt · miss: 5
- latex · apt-scripts · hit: 5
- latex · apt-scripts · miss: 5
- python-gdal · apt · hit: 5

[exited with code 0]

## v2.0.0 (scan detection), 18 November 2026

### Findings

- **Everything restored by cache-anything-new built and passed its checks**: 23 of 23
  restored hits, including LaTeX fonts, GDAL with BLAS alternatives, CUDA and the Debian
  container.
- **cache-apt-pkgs-action breaks packages that need their install scripts.** The LaTeX build
  fails after every restore, with and without `execute_install_scripts` ("Metric (TFM) file
  or installed font not found"; TeX Live builds its font maps and formats in dpkg triggers,
  which are probably not replayed). python-gdal fails without the scripts (`libblas.so.3` is
  an alternative created by a postinst) and works with them.
- **A miss made the job about 40–130 s longer than a plain install**, mostly the scan of the
  file system. Fixed in v2.1.0.
- **Hosted runners restored 18 of 30 hits**, because of the two runner variants described
  above (image builds `20261111.127.1` and `20261111.370.1`).
- **The apt download depended on the runner variant**: 215–455 s on `20261111.127.1` and
  2–4 s on `20261111.370.1` for python-gdal, and up to 23 min for cpp-boost. The medians of
  this round include those slow downloads.

### Tables


Runs: 44301367200, 44293016220, 44285130588, 44266366736, 44266321153 (5 repetitions)  
Runner images: container-, ubuntu24-20261111.127.1, ubuntu24-20261111.370.1

Median of all repetitions. *Setup* is the time from before the install (or the
restore) to after it; *Job* is the whole job, including saving the cache in post
steps. *apt download* is the part of the setup spent downloading packages, which
depends on the Ubuntu mirror. Hits only count when the cache was restored.

#### small

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 9 | 0 | 0 | 18 | 5/5 | – | – |
| cache-anything-new: miss | 133 | 0 | 0 | 140 | 5/5 | – | 11M, 7.0M |
| cache-anything-new: hit | 1 | – | 0 | 11 | 3/3 | 3/5 | – |
| cache-apt-pkgs: miss | 8 | – | 0 | 16 | 5/5 | – | – |
| cache-apt-pkgs: hit | 10 | – | 0 | 21 | 5/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 15 | – | 0 | 32 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 4 | – | 0 | 13 | 5/5 | 5/5 | – |

#### cpp-boost

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 97 | 71 | 8 | 117 | 5/5 | – | – |
| cache-anything-new: miss | 166 | 11 | 5 | 180 | 5/5 | – | 670M, 675M |
| cache-anything-new: hit | 4 | – | 5 | 17 | 4/4 | 4/5 | – |
| cache-apt-pkgs: miss | 59 | – | 6 | 72 | 5/5 | – | – |
| cache-apt-pkgs: hit | 19 | – | 8 | 43 | 5/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 64 | – | 7 | 77 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 35 | – | 8 | 56 | 5/5 | 5/5 | – |

#### latex

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 114 | 42 | 1 | 125 | 5/5 | – | – |
| cache-anything-new: miss | 200 | 3 | 0 | 206 | 5/5 | – | 517M, 521M |
| cache-anything-new: hit | 7 | – | 1 | 20 | 2/2 | 2/5 | – |
| cache-apt-pkgs: miss | 101 | – | 1 | 108 | 5/5 | – | – |
| cache-apt-pkgs: hit | 19 | – | 5 | 33 | 0/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 245 | – | 1 | 255 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 18 | – | 4 | 31 | 0/5 | 5/5 | – |

#### python-gdal

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 16 | 2 | 0 | 24 | 5/5 | – | – |
| cache-anything-new: miss | 392 | 215 | 0 | 411 | 5/5 | – | 150M, 154M, 155M |
| cache-anything-new: hit | 3 | – | 0 | 9 | 3/3 | 3/5 | – |
| cache-apt-pkgs: miss | 19 | – | 0 | 26 | 5/5 | – | – |
| cache-apt-pkgs: hit | 6 | – | 0 | 14 | 0/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 26 | – | 0 | 32 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 14 | – | 1 | 23 | 5/5 | 5/5 | – |

#### rust-sys

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 11 | 1 | 20 | 38 | 5/5 | – | – |
| cache-anything-new: miss | 143 | 1 | 24 | 171 | 5/5 | – | 20M, 24M |
| cache-anything-new: hit | 6 | – | 25 | 43 | 3/3 | 3/5 | – |
| cache-apt-pkgs: miss | 15 | – | 20 | 41 | 5/5 | – | – |
| cache-apt-pkgs: hit | 4 | – | 18 | 29 | 5/5 | 5/5 | – |
| cache-apt-pkgs + scripts: miss | 17 | – | 20 | 44 | 5/5 | – | – |
| cache-apt-pkgs + scripts: hit | 18 | – | 22 | 51 | 5/5 | 5/5 | – |

#### cuda

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 24 | – | 1 | 33 | 5/5 | – | – |
| cache-anything-new: miss | 146 | – | 2 | 157 | 5/5 | – | 418M, 422M |
| cache-anything-new: hit | 4 | – | 3 | 16 | 3/3 | 3/5 | – |

#### debian-cpp

| Variant | Setup (s) | apt download (s) | Build (s) | Job (s) | Builds OK | Restored | Size |
|---|---:|---:|---:|---:|---:|---:|---:|
| No cache | 48 | 5 | 3 | 69 | 5/5 | – | – |
| cache-anything-new: miss | 92 | 4 | 2 | 112 | 5/5 | – | 1.6G |
| cache-anything-new: hit | 14 | – | 3 | 35 | 5/5 | 5/5 | – |

#### Failed builds

- latex · apt · hit: 5
- latex · apt-scripts · hit: 5
- python-gdal · apt · hit: 5

[exited with code 0]
