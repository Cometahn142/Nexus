# Installation

This page covers the common ways to add Nexus to a Roblox project.

## Method 1: Wally

If your project already uses Wally:

```toml
[dependencies]
Nexus = "cometahn142/nexus@^0.3"
```

Because Nexus depends on shared packages such as Snap, Promise, Signal, and Janitor, Wally is usually the easiest way to keep everything versioned together.

## Method 2: Manual or vendored source

If you vendor libraries directly:

1. Copy Nexus into your shared package location.
2. Make sure its dependencies are also available.
3. Expose the package in the same place on both server and client.

For Rojo-based projects, keeping Nexus inside a dedicated third-party or packages folder tends to be the cleanest layout.

## Verification

A successful install should allow this on both peers:

```luau
local Nexus = require(Packages.Nexus)
print(Nexus.Version)
```

## Next

- [Usage Patterns](./usage-patterns.md)
- [Nexus API](./nexus.md)
- [Services and Controllers](./services-and-controllers.md)

## License

MIT. See `LICENSE`.
