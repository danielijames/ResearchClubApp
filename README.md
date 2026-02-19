# ResearchClubApp

A macOS stock data visualization application built with SwiftUI and Clean Architecture.

## Features

- **Stock Data Fetching**: Fetch stock aggregate data from Massive API (Polygon.io)
- **Configurable Granularity**: Support for 1min, 5min, 15min, 30min, and 1hr time intervals
- **Multiple Chart Types**: 
  - Candlestick charts
  - Line charts
  - Dot/Point charts
  - Histogram/Bar charts
- **Interactive Charts**: 
  - Two-finger pinch-to-zoom (directional: horizontal for X-axis, vertical for Y-axis)
  - One-finger pan/scroll
  - Reset zoom functionality
- **Secure Credential Storage**: macOS Keychain integration for API key storage
- **Data Visualization**: 
  - Datadog-inspired data table with sortable columns
  - Color-coded price changes
  - Volume indicators
- **Clean Architecture**: 
  - Domain Layer (models)
  - Data Layer (repositories)
  - Use Cases (business logic)
  - Presentation Layer (SwiftUI views)

## Architecture

The app follows Clean Architecture principles:

```
ResearchClubApp/
├── Domain/              # Domain models and entities
├── DataLayer/           # Repository implementations and API clients
├── UseCases/            # Business logic and interactors
└── Presentation/       # SwiftUI views and view models
```

## Requirements

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Clone the repository
2. Open `ResearchClubApp.xcodeproj` in Xcode
3. Build and run the project

## API Configuration

The app uses the Massive API (Polygon.io) for stock data. You'll need:

1. An API key from [Polygon.io](https://polygon.io/)
2. Enter your API key in the app's credential input field
3. Optionally save it securely using the Keychain option

## License

[Add your license here]

## Version History

### v1.0
- Initial release
- Stock data fetching and visualization
- Multiple chart types
- Interactive zoom and pan
- Secure credential storage
