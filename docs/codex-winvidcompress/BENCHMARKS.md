# Benchmark protocol

Keep the default profile unchanged while gathering evidence. Use short synthetic clips for repeatability and owner-approved copies for representative talking heads, low light, movement and on-screen text. Avoid uploading original interviews or sensitive filenames. A private input can be referenced by an opaque local test ID in committed reports.

Record source codec/dimensions/rotation/FPS/duration, input bytes, tool/build versions, hardware/host, exact encoder settings, elapsed encode/finalization/validation time, output bytes, percentage change, selected streams and structural/playback results. Save actual command tokens safely. Repeated runs and their spread matter more than a single impressive timing.

Size change = `(inputBytes - outputBytes) / inputBytes * 100` when inputBytes > 0. Label a negative result as growth. Do not calculate a ratio from unknown/zero input size. Do not imply a CRF value sets an output size or guarantees every clip shrinks.

Keep any candidate CRF/preset/codec experiment clearly separate from the production default. A perceptual metric is not a substitute for checking facial detail, text, motion, sync and audio playback. No benchmark result or user judgment exists until actually measured/recorded. Never auto-delete a larger valid output or recompress until it meets a marketing target.

Report only measured examples on the website, including source context/settings and an explicit statement that results vary. Owner approval is required before changing the default based on the measurements.
