# SwiftOpus

SwiftOpus is a Swift package maintained by Skyline-23 for low-latency Opus decode paths on Apple platforms.

## Version

- Current package stream: `0.1.0`

## What is implemented

- Vendored upstream `libopus` via submodule pinned to `v1.6.1`
- Typed runtime surface (`OpusSampleRate`, `OpusChannelLayout`, `OpusDecoderConfiguration`, `OpusError`)
- Hardware-friendly low-copy decode path:
  - single-stream decode (`opus_decode` / `opus_decode_float`)
  - multistream decode (`opus_multistream_decode` / `opus_multistream_decode_float`)
- Output conversion helpers for non-interleaved `AVAudioPCMBuffer`
- Swift Testing coverage for config/layout/decode guardrails

## Quick usage

```swift
import SwiftOpus

let config = try OpusDecoderConfiguration(
    sampleRate: .hz48k,
    channels: 2,
    pcmFormat: .float32
)
let decoder = try OpusDecoder(configuration: config)

if let pcm = try decoder.decodeToPCMBuffer(payload: packetData) {
    // enqueue into audio output path
}
```

## Notes

- Decoder APIs are built for realtime paths and avoid per-call decoder reallocation.
- Multistream layout for 5.1/7.1 follows standard Opus mapping.

## Static COpus product

`COpus` is an explicit static SwiftPM product. Native consumers can build an
archive for the architecture they are linking instead of relying on a
Homebrew or machine-local `libopus.a`:

```bash
swift build -c release \
  --product COpus \
  --triple arm64-apple-macosx14.0

swift build -c release \
  --product COpus \
  --triple x86_64-apple-macosx14.0
```

The resulting `libCOpus.a` lives under the selected SwiftPM scratch directory
and contains only the requested target architecture. Universal applications
should link the matching archive while building each architecture rather than
linking a host-architecture Homebrew archive into every slice.
