# iOS SwiftUI client

This example uses Stripe’s new [prebuilt payment UI](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet&uikit-swiftui=swiftui). This integration combines all of the steps required to pay, collecting payment details, and confirming the payment into a single sheet that displays on top of your app.

![Screenshots of prebuilt payment UI](https://b.stripecdn.com/docs/assets/overview-complete.f08cdac19b6948ac6035828dd35c59aa.png)

## Configuration

### 1. Configure the app with Firebase

- Follow steps 1-3 in the [Firebase setup instructions](https://firebase.google.com/docs/ios/setup).
- Use `stripe.example.Firestripe` as the bundle id.

### 2. Install the dependencies

- Run `pod install`

### 3. Open, build, and run the project

- Open `Firestripe.xcworkspace` in Xcode.
- Set your publishable key in the `FirestripeApp.swift` file.
- Build and run the project.
