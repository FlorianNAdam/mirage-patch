# Mirage Patch

Simple application for temporarily patching immutable files at runtime for testing purposes.

## Overview

`mirage-patch` allows you to edit immutable files safely using Mirage. It runs as root and opens the target file in your editor (`$EDITOR`, defaults to `nano`).

## Usage

```bash
sudo mirage-patch <path-to-file>
````

## Installation

Build the package from this flake:

```bash
nix build github:FlorianNAdam/mirage-patch#mirage-patch
```

This will produce `result/bin/mirage-patch`.
