# Time Capsule App

A beautiful Flutter mobile application that allows users to create digital time capsules - storing memories, messages, and files to be opened at future dates. Share special moments with loved ones or keep personal reflections for your future self.

##  Features

### Core Functionality
- **Digital Time Capsules**: Create capsules with text, images, and files
- **Scheduled Opening**: Set future dates for capsule unlocking
- **Secure Storage**: Encrypted data storage with PostgreSQL backend
- **Multi-media Support**: Text messages, images, documents, and more
- **Sharing System**: Share capsules with friends and family

### User Experience
- **Multi-language Support**: Arabic and English localization
- **Dark/Light Themes**: Customizable appearance
- **Push Notifications**: Reminders when capsules are ready to open
- **Responsive Design**: Optimized for phones and tablets
- **Offline Capabilities**: View opened capsules without internet

### Advanced Features
- **Dashboard Analytics**: Track your capsule statistics
- **User Authentication**: Secure login and registration
- **Background Processing**: Automatic capsule management
- **File Management**: Secure file upload and storage
- **Social Features**: Share and collaborate on capsules

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- PostgreSQL database
- Android Studio / VS Code
- Android/iOS device or emulator

### MVVM Pattern
lib/
├── models/           # Data models (User, Capsule)
├── services/         # Business logic and API calls
├── view_models/      # State management with Provider
├── views/           # UI screens and pages
├── widgets/         # Reusable UI components
└── utils/           # Helper functions and constants


### Key Components
- **AuthService**: User authentication and session management
- **CapsuleService**: Core capsule CRUD operations
- **NotificationService**: Push notifications and scheduling
- **RemoteDB**: PostgreSQL database connection and queries
- **ViewModels**: State management with ChangeNotifier pattern

##  Technical Stack

- **Frontend**: Flutter/Dart
- **State Management**: Provider pattern
- **Database**: PostgreSQL
- **Authentication**: Custom JWT implementation
- **Notifications**: Flutter Local Notifications
- **File Storage**: Base64 encoding with database storage
- **Localization**: Flutter Intl
- **Architecture**: MVVM with Service Layer

## Usage

### Creating a Time Capsule
1. Tap the "+" button on the home screen
2. Add your message, photos, or files
3. Set the opening date
4. Choose privacy settings (private/shared)
5. Save your capsule

### Opening a Capsule
1. Wait for the scheduled opening date
2. Receive a notification when ready
3. Tap to open and view your memories
4. Share or save the contents

### Sharing Capsules
1. Create a capsule with sharing enabled
2. Add recipients by email or username
3. Recipients receive notifications when capsule opens
4. Collaborate on group memories

## Configuration

### Database Configuration
\`\`\`dart
// lib/services/remote_db.dart
static const String _host = 'your-database-host';
static const int _port = 5432;
static const String _databaseName = 'time_capsule_db';
static const String _username = 'your-username';
static const String _password = 'your-password';
\`\`\`

### Notification Setup
\`\`\`dart
// Configure notification channels and scheduling
// See lib/services/notification_service.dart
\`\`\`

**Made with ❤️ using Flutter**

