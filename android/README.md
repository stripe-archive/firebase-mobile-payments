## Configurations before running this application

1. Registering this application to the firebase project
- Following [firebase guide](https://firebase.google.com/docs/android/setup#register-app)
- Register this package name `com.example.firebasemobilepayments` into your firebase project
- Download the google-services.json file from step 2 and replace the one under app/google-services.json

2. Login to your stripe dashboard and go to [Api Keys page](https://dashboard.stripe.com/test/apikeys)
Open `gradle.properties` file and replace `stripePublishableKey="pk_test_xxxxx"` with your actual API publishable keys

