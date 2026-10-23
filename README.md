# Ajiomart Android app

Flutter Android storefront for the Ajiomart website. It connects to the same Supabase project, Auth users, product and order tables, account cart, Storage bucket, and Edge Functions as the website.

## Run

```sh
flutter pub get
flutter run
```

The app has the Ajiomart Supabase URL and publishable key configured as defaults. To point a build at another Supabase project, pass the client-safe values as Dart defines:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_your-key
```

Create a release APK with:

```sh
flutter build apk --release
```

## Supabase services

The app uses the existing Ajiomart database schema and policies. Product browsing, profiles, saved carts, checkout, order history, admin updates, and product image uploads use Supabase directly. COD checkout calls `place_order`; online checkout calls the existing `create-razorpay-order` and `verify-razorpay-payment` Edge Functions. Admin shipment actions call `delhivery-create-shipment` and `delhivery-track-shipment`.

Run the website repository's SQL setup (`schema.sql`, `stock-management.sql`, `razorpay-payments.sql`, and `delhivery-shipping.sql`) in the same Supabase project, and deploy/configure its Edge Functions before enabling the corresponding checkout and shipping features. Keep Razorpay and Delhivery secret keys in Supabase Edge Function secrets; the Android app only contains the public Supabase publishable key.

Admins use the same Supabase Auth accounts promoted to `admin` in `public.profiles`.
