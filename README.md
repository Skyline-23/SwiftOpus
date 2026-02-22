# SwiftOpus

SwiftOpus is a clean-slate Swift package maintained by Skyline-23 for low-latency Opus encode/decode on Apple platforms.

## Status

This repository is intentionally initialized from scratch and currently contains a minimal package scaffold.

## Next Steps

1. Add vendored libopus source (or pinned submodule) with reproducible build settings.
2. Implement safe Swift wrappers for decoder/encoder lifecycle.
3. Add RTP-oriented decode tests and PCM conformance checks.
4. Add CI matrix for iOS/macOS/tvOS/watchOS/visionOS.
