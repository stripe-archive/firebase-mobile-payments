# Firebase Mobile Payments

## Setup

- Create a Firebase Project using the [Firebase Developer Console](https://console.firebase.google.com)
- Enable billing on your project by switching to the Blaze or Flame plan. See [pricing](https://firebase.google.com/pricing/) for more details. This is required to be able to do requests to non-Google services.
- Enable Google & Email sign-in in your [authentication provider settings](https://console.firebase.google.com/project/_/authentication/providers).
- Install [Firebase CLI Tools](https://github.com/firebase/firebase-tools) if you have not already and log in with `firebase login`.
- Configure this sample to use your project using `firebase use --add` and select your project.
- Install dependencies locally by running: `cd functions; npm install; cd -`
- [Add your Stripe API Secret Key](https://dashboard.stripe.com/account/apikeys) to firebase config:
  ```bash
  firebase functions:config:set stripe.secret=<YOUR STRIPE SECRET KEY>
  firebase functions:config:set stripe.webhooksecret=<YOUR WEBHOOK SECRET>
  ```
- Deploy your project using `cd functions; npm run deploy; cd -`
