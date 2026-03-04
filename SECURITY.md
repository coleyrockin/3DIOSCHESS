# Security Policy

## Supported Versions

The following versions of 3D iOS Chess are currently supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in 3D iOS Chess, please report it responsibly:

### How to Report
- **Email**: Send details to the project maintainer via GitHub
- **GitHub Issues**: For non-sensitive issues, you may create a GitHub issue
- **Response Time**: You can expect an initial response within 48 hours

### What to Include
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested fix (if available)

### What to Expect
- **Accepted vulnerabilities**: We will work on a fix and coordinate disclosure
- **Declined reports**: We will explain why the issue doesn't qualify as a security vulnerability
- **Updates**: Regular status updates during the resolution process

## Security Measures

This project implements the following security practices:

### Code Security
- No hardcoded secrets or API keys
- Secure Game Center authentication handling
- Input validation for all user data
- Memory-safe Swift code practices

### Network Security
- Game Center's secure networking for online play
- No custom network protocols that could introduce vulnerabilities
- Encrypted data transmission through Apple's GameKit framework

### Data Protection
- No sensitive user data stored locally
- Game state persistence uses standard iOS secure storage
- No third-party analytics or tracking

## Dependencies

This project minimizes external dependencies to reduce attack surface:
- Uses only Apple's native frameworks (GameKit, SceneKit, SwiftUI)
- No third-party networking libraries
- No external authentication providers beyond Game Center
