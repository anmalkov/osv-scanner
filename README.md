# OSV-Scanner

![Build Status](https://github.com/anmalkov/osv-scanner/actions/workflows/build-image.yml/badge.svg)

This repository contains a script to build a container image for the latest release of Google OSV-Scanner tool and push it to Docker Hub.

The image is available at [anmalkov/osv-scanner](https://hub.docker.com/r/anmalkov/osv-scanner).

You can find the official Google OSV-Scanner repository [here](https://github.com/google/osv-scanner).

## What is Google OSV-Scanner

Use OSV-Scanner to find existing vulnerabilities affecting your project's dependencies.

OSV-Scanner provides an officially supported frontend to the [OSV database](https://osv.dev/) that connects a project’s list of dependencies with the vulnerabilities that affect them. Since the OSV.dev database is open source and distributed, it has several benefits in comparison with closed source advisory databases and scanners:

- Each advisory comes from an open and authoritative source (e.g. the [RustSec Advisory Database](https://github.com/rustsec/advisory-db))
- Anyone can suggest improvements to advisories, resulting in a very high quality database
- The OSV format unambiguously stores information about affected versions in a machine-readable format that precisely maps onto a developer’s list of packages

The above all results in fewer, more actionable vulnerability notifications, which reduces the time needed to resolve them.

## How to use this image

### Pull an image from Docker Hub

```bash
$ docker pull anmalkov/osv-scanner
```

### Scan a directory

Walks through a list of directories to find:

- Lockfiles
- SBOMs
- git directories for the latest commit hash

which is used to build the list of dependencies to be matched against OSV vulnerabilities.

Can be configured to recursively walk through subdirectories with the `--recursive` / `-r` flag.

Searching for git commit hash is intended to work with projects that use git submodules or a similar mechanism where dependencies are checked out as real git repositories.

#### Example

```bash
$ docker run -v /path/to/your/dir:/data anmalkov/osv-scanner -r /data
```

### Input an SBOM

[SPDX] and [CycloneDX] SBOMs using [Package URLs] are supported. The format is
auto-detected based on the input file contents.

[SPDX]: https://spdx.dev/
[CycloneDX]: https://cyclonedx.org/
[Package URLs]: https://github.com/package-url/purl-spec

#### Example

```bash
$ docker run -v /path/to/your/dir-with-sbom-file:/data anmalkov/osv-scanner --sbom=/data/sbom.json
```

### Input a lockfile

A wide range of lockfiles are supported by utilizing this [lockfile package](https://github.com/google/osv-scanner/tree/main/pkg/lockfile). This is the current list of supported lockfiles:

- `Cargo.lock`
- `package-lock.json`
- `yarn.lock`
- `pnpm-lock.yaml`
- `composer.lock`
- `Gemfile.lock`
- `go.mod`
- `mix.lock`
- `poetry.lock`
- `pubspec.lock`
- `pom.xml`[\*](https://github.com/google/osv-scanner/issues/35)
- `requirements.txt`[\*](https://github.com/google/osv-scanner/issues/34)
- `gradle.lockfile`
- `buildscript-gradle.lockfile`

#### Example

```bash
$ docker run -v /path/to/your/dir-with-your-lock-files:/data anmalkov/osv-scanner --lockfile=/data/first-directory/package-lock.json --lockfile=/data/another-directory/Cargo.lock
```

### JSON output

By default osv-scanner outputs a human readable table. To have osv-scanner output JSON instead, pass the `--json` flag when calling osv-scanner.

When using the --json flag, only the JSON output will be printed to stdout, with all other outputs being directed to stderr. So to save only the json output to file, you can redirect the output with `osv-scanner --json ... > /path/to/file.json`

#### Example

```bash
$ docker run -v /path/to/your/dir-with-your-lock-file:/data anmalkov/osv-scanner --lockfile=/data/yarn.lock --json > /folder/to/store/scanning/results/results.json
```

#### Output Format

```json5
{
  "results": [
    {
      "packageSource": {
        "path": "/absolute/path/to/go.mod",
        // One of: lockfile, sbom, git, docker
        "type": "lockfile"
      },
      "packages": [
        {
          "Package": {
            "name": "github.com/gogo/protobuf",
            "version": "1.3.1",
            "ecosystem": "Go"
          },
          "vulnerabilities": [
            {
              "id": "GHSA-c3h9-896r-86jm",
              "aliases": [
                "CVE-2021-3121"
              ],
              // ... Full OSV
            },
            {
              "id": "GO-2021-0053",
              "aliases": [
                "CVE-2021-3121",
                "GHSA-c3h9-896r-86jm"
              ],
              // ... Full OSV
            }
          ],
          // Grouping based on aliases, if two vulnerability share the same alias, or alias each other,
          // they are considered the same vulnerability, and is grouped here under the id field.
          "groups": [
            {
              "ids": [
                "GHSA-c3h9-896r-86jm",
                "GO-2021-0053"
              ]
            }
          ]
        }
      ]
    },
    {
      "packageSource": {
        "path": "/absolute/path/to/Cargo.lock",
        "type": "lockfile"
      },
      "packages": [
        {
          "Package": {
            "name": "regex",
            "version": "1.5.1",
            "ecosystem": "crates.io"
          },
          "vulnerabilities": [
            {
              "id": "GHSA-m5pq-gvj9-9vr8",
              "aliases": [
                "CVE-2022-24713"
              ],
              // ... Full OSV
            },
            {
              "id": "RUSTSEC-2022-0013",
              "aliases": [
                "CVE-2022-24713"
              ],
              // ... Full OSV
            }
          ],
          "groups": [
            {
              "ids": [
                "GHSA-m5pq-gvj9-9vr8",
                "RUSTSEC-2022-0013"
              ]
            }
          ]
        }
      ]
    }
  ]
}
```
