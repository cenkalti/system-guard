# System Guard

![logo](System%20Guard/Assets.xcassets/AppIcon.appiconset/cpu\(2\).png)

System Guard is a macOS application that monitors system resources and provides notifications for high CPU usage and memory pressure.

## Features

- Runs silently in the menubar
- Monitors individual process CPU usage
- Monitors system-wide memory pressure
- Sends notifications for resource-intensive events
- Automatically starts on system login

## Installation

1. Download the latest release from the [Releases](https://github.com/cenkalti/system-guard/releases) page
2. Drag the System Guard app to your Applications folder
3. Launch System Guard

## Usage

Once installed and running, System Guard operates silently in the background. You'll see its icon in the menubar, indicating that it's active and monitoring your system resources.

The app will automatically send notifications when:
- A process uses more than 80% CPU for over 5 seconds
- System memory pressure exceeds 80%

## Contributing

Contributions to System Guard are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any problems or have any questions, please file an issue on the [GitHub issue tracker](https://github.com/cenkalti/system-guard/issues).
