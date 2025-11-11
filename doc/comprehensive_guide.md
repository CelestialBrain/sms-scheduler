# Comprehensive Guide: Flutter SMS Scheduling with eSIM and Load APIs

This guide provides a complete walkthrough of the Flutter SMS scheduling package, including setup, implementation, and integration with eSIM and Philippine load APIs. It is designed to be flexible for use with FlutterFlow and custom Flutter applications.

## 1. Introduction

This project provides a complete solution for building a Flutter application that can:

- Schedule SMS messages to be sent at a future date and time.
- Manage scheduled messages (enable, disable, update, delete).
- Integrate with eSIM providers to programmatically purchase and manage eSIMs.
- Connect to Philippine prepaid load resellers to buy load for any network.

### Key Components

1.  **Flutter Package (`schedulersms`)**: A reusable Flutter package that encapsulates all the core functionality.
2.  **Example App**: A sample Flutter application demonstrating how to use the package.
3.  **Backend API**: A Node.js/Express backend that securely handles API integrations with third-party services.

## 2. How to Set Up and Use the `dart_mcp_server`

The `dart_mcp_server` allows AI-powered development tools to interact with your local Dart and Flutter projects. While not required for this SMS scheduling package to function, it is a powerful tool for AI-assisted development.

### Setting Up `dart_mcp_server`

1.  **Install the Dart SDK**: Ensure you have Dart SDK version 3.9.0 or later.

2.  **Configure Your IDE**:

    -   **VS Code with Gemini Code Assist**: Follow the instructions to [configure the Gemini CLI](https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp_server#gemini-code-assist-in-vs-code).
    -   **Cursor**: Use the "Add to Cursor" button or manually configure the `.cursor/mcp.json` file as described in the [Cursor documentation](https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp_server#cursor).

### Using `dart_mcp_server`

Once configured, you can use your AI assistant (e.g., Gemini, Copilot) to:

-   **Analyze code**: `/analyze` - Get feedback on your code quality.
-   **Run tests**: `/test` - Execute unit tests in your project.
-   **Generate code**: Ask the AI to write functions, classes, or widgets for you.

## 3. Philippine eSIM Providers with APIs

As of late 2024, local Philippine telcos (Globe, Smart, DITO) do **not** offer public APIs for eSIM provisioning. Their services are consumer-facing and require manual activation.

To programmatically purchase and manage eSIMs for the Philippines, you must use an **international eSIM provider** that offers API access and supports Philippine networks.

### Recommended eSIM API Providers

| Provider      | API Documentation                               | Philippine Networks | Key Features                                      |
| :------------ | :---------------------------------------------- | :------------------ | :------------------------------------------------ |
| **Airalo**    | [partners-doc.airalo.com](https://partners-doc.airalo.com/) | Globe, Smart        | Comprehensive REST API, wide range of data plans. |
| **eSIM Access** | [docs.esimaccess.com](https://docs.esimaccess.com/)       | Multiple            | Reseller-focused platform with a straightforward API. |
| **eSIM Go**     | [docs.esim-go.com](https://docs.esim-go.com/)           | Multiple            | Developer-friendly API with global coverage.      |
| **Telnyx**      | [telnyx.com/products/esim](https://telnyx.com/products/esim)         | Global              | Enterprise-grade API with advanced features.      |

### How to Choose a Provider

1.  **Review API Documentation**: Check if the API meets your requirements for purchasing, activating, and managing eSIMs.
2.  **Check Pricing**: Compare the costs of eSIM plans and any API usage fees.
3.  **Developer Support**: Look for a provider with good developer support and a clear onboarding process.

## 4. Philippine Load Reseller APIs

Similar to eSIMs, direct API access for purchasing prepaid load from local telcos is not publicly available. You will need to partner with a **load reseller** that provides an API.

### Recommended Load Reseller APIs

| Provider         | Contact/API Info                               | Notes                                                                                             |
| :--------------- | :--------------------------------------------- | :------------------------------------------------------------------------------------------------ |
| **Loademy**        | `admin@loademy.net`                            | Offers API and bulk eloading solutions. You will need to contact them for API access and pricing. |
| **PrepayNation**   | [prepaynation.com](https://prepaynation.com/) | A global digital prepaid marketplace with a focus on the Philippines. Requires partnership.       |

**Note**: LoadCentral was a popular option but has ceased operations as of October 31, 2024.

### How to Integrate with a Load Reseller

1.  **Register as a Reseller**: You will typically need to register your business and create a reseller account.
2.  **Fund Your Wallet**: Most providers operate on a wallet system, where you deposit funds that are used for load purchases.
3.  **Get API Credentials**: Once registered, you will receive API keys, a UID, a password, and a company prefix for your transactions.

## 5. Flutter Package Implementation (`schedulersms`)

The `schedulersms` package is the core of this solution. It provides all the necessary tools to schedule, send, and manage SMS messages from your Flutter app.

### Package Structure

```
lib/
├── src/
│   ├── api/              # API clients for eSIM and load
│   ├── database/         # SQLite database for SMS storage
│   ├── models/           # Data models (ScheduledSMS, SmsStatus)
│   ├── utils/            # Utility functions (validators)
│   └── schedulersms_service.dart # Main service class
└── schedulersms.dart      # Main library file
```

### Key Classes and Functions

-   `SchedulerSmsService`: The main entry point for all package functionality.
-   `scheduleSms()`: Schedules a new SMS message.
-   `updateScheduledSms()`: Updates an existing scheduled message.
-   `deleteScheduledSms()`: Deletes a scheduled message.
-   `statusStream`: A stream of real-time status updates for scheduled messages.
-   `ESimApiClient`: A client for interacting with eSIM provider APIs.
-   `LoadApiClient`: A client for interacting with load reseller APIs.

For detailed usage examples, please refer to the `README.md` file in the `schedulersms_package` directory.

## 6. Backend API Implementation

For security and scalability, it is highly recommended to use a backend API to manage interactions with third-party services. This prevents your API keys and other sensitive credentials from being exposed in your mobile app.

### Backend Architecture

The provided backend is a simple Node.js/Express application that exposes endpoints for:

-   Fetching eSIM packages.
-   Purchasing eSIMs.
-   Purchasing prepaid load.

### How to Run the Backend

1.  **Install Dependencies**:

    ```bash
    cd schedulersms_package/backend_api
    npm install
    ```

2.  **Configure Environment Variables**: Create a `.env` file in the `backend_api` directory with the following:

    ```
    PORT=3000
    AIRALO_API_KEY=your_airalo_api_key
    LOAD_API_UID=your_load_api_uid
    LOAD_API_PASSWORD=your_load_api_password
    LOAD_COMPANY_PREFIX=ABC
    ```

3.  **Start the Server**:

    ```bash
    npm start
    ```

Your backend will now be running at `http://localhost:3000`.

## 7. Flexibility for Your Friend's App (FlutterFlow)

This solution is designed to be highly flexible and can be easily integrated into a FlutterFlow application.

### Integration Steps for FlutterFlow

1.  **Add the Package**: Add the `schedulersms` package to your FlutterFlow project's `pubspec.yaml` file.

2.  **Create Custom Actions**: In FlutterFlow, create custom actions to call the package's functions. For example, to schedule an SMS:

    ```dart
    import 'package:schedulersms/schedulersms.dart';

    Future<void> scheduleSmsAction(
      String recipient,
      String message,
      DateTime scheduledDate,
    ) async {
      final service = SchedulerSmsService();
      await service.initialize();
      await service.scheduleSms(
        recipient: recipient,
        message: message,
        scheduledDate: scheduledDate,
      );
    }
    ```

3.  **Connect to Backend**: Use FlutterFlow's API call feature to connect to your backend API for eSIM and load purchases.

### Providing Flexibility

-   **Modular Design**: The package is modular, so your friend can choose to use only the SMS scheduling features, or integrate the eSIM and load APIs as needed.
-   **Configurable API Clients**: The `ESimApiClient` and `LoadApiClient` can be configured with different base URLs and credentials, allowing your friend to switch between providers without changing the app's code.
-   **Clear Documentation**: This comprehensive guide provides all the necessary information for your friend to understand and integrate the solution.

## 8. Conclusion

This comprehensive guide provides a complete solution for your Flutter SMS scheduling project. By following the steps outlined here, you can build a powerful and flexible application that meets all of your friend's requirements.

For the complete source code, please refer to the attached `schedulersms_package.zip` file.
