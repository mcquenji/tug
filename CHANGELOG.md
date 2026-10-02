# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## 0.2.0 (2026-10-02)

### ⚠ BREAKING CHANGES

* **config:** coolify.yaml no longer accepts connection profiles, context selection, or per-environment domains; store instance-specific settings in .coolify/local.yaml or global contexts.

### Features

* **cli:** embed build version and expose --version ([e8b71f9](https://github.com/mcquenji/tug/commit/e8b71f9e4ae731b10b8bda7f3171cb6ddfc73535))
* **config:** separate portable manifests from private deployment settings ([6d7a96a](https://github.com/mcquenji/tug/commit/6d7a96a0e7ddf9ac3fa5b13f780caa0d123fcc1d))
* **config:** support environment variable references for runtime env ([df15898](https://github.com/mcquenji/tug/commit/df15898f6b3dbeb6f6fb8c8578b60e2ad50899c8))
* **terminal:** add colored progress and verbose diagnostics ([ddf34c6](https://github.com/mcquenji/tug/commit/ddf34c6266738e5c0d745319b94f4c8bfafa48bc))

### Bug Fixes

* **ci:** preserve runtime files in FVM distributions ([52ce992](https://github.com/mcquenji/tug/commit/52ce992eec2a3895743e713ebf0b1114980c05ca))
* **context:** select deployment servers per checkout ([80665f7](https://github.com/mcquenji/tug/commit/80665f76f0c821266924fbf5d6066179df6f3e8d))
* **coolify:** distinguish empty environment values from redaction ([97ce733](https://github.com/mcquenji/tug/commit/97ce73362ebe505c8a21d500cdcb55a1a3210a97))
* **coolify:** reconcile health checks and verify deployment outcomes ([cb662c3](https://github.com/mcquenji/tug/commit/cb662c337f758c4da2e05e16456b17c1aebc65af))
* **coolify:** send repository slugs for GitHub App deployments ([10d7b11](https://github.com/mcquenji/tug/commit/10d7b1198266b390d80dab7bbcbf6fc96ed0efb7))
* **coolify:** use valid project markers and retain legacy ownership ([6d606a8](https://github.com/mcquenji/tug/commit/6d606a878e552c0d82b9157098da5841f5692a6b))
* **reconcile:** clarify ownership conflicts and verify stale-state recovery ([d18b2cc](https://github.com/mcquenji/tug/commit/d18b2cc371547f62bcebd5c1e351387a6f74e63b))
* **windows:** normalize project paths and build native executables ([326690b](https://github.com/mcquenji/tug/commit/326690b84d2642687bac713ed5db9c06ba0322bd))
