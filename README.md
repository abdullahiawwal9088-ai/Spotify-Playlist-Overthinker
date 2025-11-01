# Spotify Playlist Overthinker

A blockchain-based smart contract system that scores emotional context and enforces mood consistency for Spotify playlists. This project leverages Clarity smart contracts on the Stacks blockchain to analyze and validate playlist curation decisions.

## Overview

The Spotify Playlist Overthinker system introduces an analytical layer to playlist curation by quantifying the emotional demands of each song and maintaining strict mood coherence across the entire playlist. By utilizing blockchain technology, these metrics become immutable and verifiable.

## Features

### Core Functionality

- **Emotional Context Scoring**: Evaluates how much emotional processing each song requires before it can be added to a playlist
- **Vibe Consistency Enforcement**: Maintains playlist mood integrity through automated validation
- **Ethical Skip Metrics**: Tracks and calculates fair skip rates for emerging artists

### Smart Contracts

#### 1. Vibe Mismatch Detector
Identifies and flags songs that deviate from the declared playlist mood by more than 18%. This contract ensures that every track aligns with the intended emotional atmosphere.

**Key Capabilities:**
- Mood deviation analysis
- Automated flagging system
- Threshold-based validation
- Historical mismatch tracking

#### 2. Skip Guilt Balancer
Calculates ethical skip rates specifically for artists with under 10,000 monthly listeners. This contract promotes fair treatment of emerging artists while maintaining user autonomy.

**Key Capabilities:**
- Artist listener threshold monitoring
- Skip rate calculation
- Ethical metrics generation
- Artist support tracking

## Technical Architecture

### Smart Contract Platform
- **Blockchain**: Stacks
- **Language**: Clarity
- **Development Framework**: Clarinet

### Design Principles
- No cross-contract dependencies
- Self-contained logic per contract
- Clean, maintainable code structure
- Type-safe operations

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for deployment (optional)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Spotify-Playlist-Overthinker
```

2. Check contract syntax:
```bash
clarinet check
```

3. Run tests:
```bash
npm test
```

### Project Structure

```
Spotify-Playlist-Overthinker/
├── contracts/
│   ├── vibe-mismatch-detector.clar
│   └── skip-guilt-balancer.clar
├── tests/
│   ├── vibe-mismatch-detector.test.ts
│   └── skip-guilt-balancer.test.ts
├── settings/
│   ├── Devnet.toml
│   ├── Testnet.toml
│   └── Mainnet.toml
├── Clarinet.toml
├── package.json
└── README.md
```

## Usage

### Vibe Mismatch Detector

The contract analyzes songs against a baseline playlist mood and flags deviations exceeding 18%.

**Example Use Case:**
A "Chill Vibes" playlist with a declared mood value of 50 (on a scale of 0-100) would flag any song with a mood value below 41 or above 59.

### Skip Guilt Balancer

This contract monitors skip behavior for artists under 10k monthly listeners and calculates ethical skip rates.

**Example Use Case:**
For an artist with 5,000 monthly listeners, the contract might suggest a maximum skip rate of 30% to ensure fair exposure while respecting user preferences.

## Development

### Adding New Features

1. Create a new contract:
```bash
clarinet contract new <contract-name>
```

2. Implement your logic in `contracts/<contract-name>.clar`

3. Write tests in `tests/<contract-name>.test.ts`

4. Validate:
```bash
clarinet check
npm test
```

### Testing

The project uses Vitest for testing. Test files are located in the `tests/` directory.

Run all tests:
```bash
npm test
```

## Configuration

Contract configuration is managed through Clarinet.toml and environment-specific settings files in the `settings/` directory.

### Supported Networks
- **Devnet**: Local development environment
- **Testnet**: Stacks testnet for staging
- **Mainnet**: Stacks mainnet for production

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Write clean, documented code
4. Add tests for new functionality
5. Submit a pull request

## Use Cases

### For Playlist Curators
- Maintain consistent mood across collaborative playlists
- Verify emotional coherence before sharing
- Track curation quality metrics

### For Artists
- Transparent skip rate tracking
- Fair exposure metrics for emerging artists
- Verifiable listener engagement data

### For Music Platforms
- Automated quality control for algorithmic playlists
- User preference analysis
- Mood-based recommendation validation

## Technical Details

### Clarity Data Types Used
- `uint`: Numeric values for scores and thresholds
- `bool`: Validation flags
- `principal`: User/artist identification
- `maps`: Data storage structures
- `optional`: Nullable return values

### Security Considerations
- All contract functions are designed to be read-only or require proper authorization
- No external dependencies minimize attack surface
- Input validation on all public functions

## Roadmap

- [ ] Integration with Spotify API (off-chain)
- [ ] Advanced mood algorithms
- [ ] Multi-playlist support
- [ ] Artist reward mechanisms
- [ ] Community-driven mood definitions

## License

This project is open-source and available under the MIT License.

## Contact

For questions, issues, or contributions, please open an issue in the GitHub repository.

---

**Built with Clarity on Stacks** | **Powered by Clarinet**
