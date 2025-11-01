## Overview

This pull request introduces two smart contracts for analyzing and managing playlist curation decisions on the Stacks blockchain. The system evaluates emotional context and enforces ethical listening behavior for emerging artists.

## Changes

### New Contracts

#### 1. **Vibe Mismatch Detector** (`vibe-mismatch-detector.clar`)
- **Lines**: 319
- **Purpose**: Automatically flags songs that deviate from declared playlist mood by more than 18%

**Key Features**:
- Playlist creation with mood declaration (0-100 scale)
- Real-time song compatibility checking
- Automated flagging system for mood violations
- Statistical tracking of mismatch rates
- Per-playlist threshold customization
- Historical deviation analysis

**Core Functions**:
- `create-playlist`: Initialize playlist with mood baseline
- `add-song`: Add and validate songs against mood threshold
- `update-threshold`: Adjust mismatch tolerance per playlist
- `check-song-compatibility`: Pre-check songs before adding
- `get-mismatch-rate`: Calculate overall playlist consistency

#### 2. **Skip Guilt Balancer** (`skip-guilt-balancer.clar`)
- **Lines**: 421
- **Purpose**: Calculates ethical skip rates for artists under 10,000 monthly listeners

**Key Features**:
- Artist registration with listener count tracking
- Dynamic ethical skip rate calculation
- Per-user skip behavior monitoring
- Guilt score computation based on excessive skipping
- Support metrics for emerging artists
- Recommended skip limits

**Core Functions**:
- `register-artist`: Add artists to the tracking system
- `record-play`: Log complete song plays
- `record-skip`: Track skip events and calculate guilt
- `update-listener-count`: Update artist popularity metrics
- `is-user-ethical`: Check user's skip behavior
- `get-recommended-max-skips`: Calculate fair skip limits

### Technical Implementation

**Data Structures**:
- Maps for artist/playlist/song registry
- Counters for ID generation
- Statistical aggregation for tracking metrics
- User-specific behavior tracking

**Design Principles**:
- ✅ No cross-contract dependencies
- ✅ Self-contained business logic
- ✅ Clean separation of concerns
- ✅ Type-safe Clarity operations
- ✅ Read-only functions for queries
- ✅ Authorization checks on mutations

**Validation**:
- All contracts pass `clarinet check` with zero errors
- Input validation on all public functions
- Proper error handling with descriptive codes
- Safe arithmetic operations

## Testing

Both contracts include test scaffolding in the `tests/` directory:
- `tests/vibe-mismatch-detector.test.ts`
- `tests/skip-guilt-balancer.test.ts`

## Configuration

Updated `Clarinet.toml` with both contract definitions for proper build configuration.

## Contract Stats

| Contract | Lines of Code | Public Functions | Read-Only Functions | Maps | Data Vars |
|----------|--------------|------------------|---------------------|------|-----------|
| vibe-mismatch-detector | 319 | 5 | 6 | 5 | 1 |
| skip-guilt-balancer | 421 | 5 | 8 | 5 | 2 |

## Use Cases

### Vibe Mismatch Detector
- Maintain consistency in curated playlists
- Automatically validate song additions
- Track curation quality over time
- Enforce collaborative playlist rules

### Skip Guilt Balancer
- Support emerging artists fairly
- Provide transparency in listening behavior
- Educate users about artist exposure
- Calculate ethical consumption metrics

## Security Considerations

- Proper access control on mutations (owner/user-specific)
- No external dependencies or cross-contract calls
- Input validation prevents invalid state
- Safe division operations with zero-checks
- Principal-based authorization

## Future Enhancements

Potential improvements for future iterations:
- Integration with off-chain Spotify data
- Advanced mood calculation algorithms
- Cross-playlist recommendations
- Artist reward mechanisms
- Community-driven definitions

## Breaking Changes

None - this is the initial implementation.

## Migration Notes

No migration needed for first deployment.
