# Firebase mobile payments: Cloud Functions for Firebase

## Deploy and test

- Create a Firebase Project using the [Firebase Developer Console](https://console.firebase.google.com)
- Enable billing on your project by switching to the Blaze or Flame plan. See [pricing](https://firebase.google.com/pricing/) for more details. This is required to be able to do requests to non-Google services.
- Enable Google & Email sign-in in your [authentication provider settings](https://console.firebase.google.com/project/_/authentication/providers).
- Install [Firebase CLI Tools](https://github.com/firebase/firebase-tools) if you have not already and log in with `firebase login`.
- Configure this sample to use your project using `firebase use --add` and select your project.
- Install dependencies locally by running: `npm install`
- [Add your Stripe API Secret Key](https://dashboard.stripe.com/account/apikeys) to Firebase config:
  ```bash
  firebase functions:config:set stripe.secret=<YOUR STRIPE SECRET KEY>
  ```
- Deploy your project using `npm run deploy`

### Setting up webhooks

- Run `firebase open functions` to open the Firebase console.
- Copy the URL for the `handleWebhookEvents` functions (e.g. https://region-project-name.cloudfunctions.net/handleWebhookEvents)
- Create a new webhook endpoint with the URL in the [Stripe Dashboard](https://dashboard.stripe.com/webhooks)
- Copy the signing secret (whsec_xxx) and add it to Firebase config:
  ```bash
  firebase functions:config:set stripe.webhooksecret=<YOUR WEBHOOK SECRET>
  ```
- Redeploy the `handleWebhookEvents` function: `firebase deploy --only functions:handleWebhookEvents`

## Accepting live payments

Once you’re ready to go live, you will need to exchange your test keys for your live keys. See the [Stripe docs](https://stripe.com/docs/keys) for further details.

- Update your Stripe secret config:
  ```bash
  firebase functions:config:set stripe.secret=<YOUR STRIPE LIVE SECRET KEY>
  ```
- Set your [live publishable key](https://dashboard.stripe.com/account/apikeys) in your respective client integration.
- Follow the [Setting up webhooks](#Setting-up-webhooks) from above for live mode.
- Redeploy the functions for the changes to take effect `npm run deploy`.
