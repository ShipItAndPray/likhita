// Global test setup — runs once before every test file.
process.env.LIKHITA_RUNTIME = "test";
process.env.STRIPE_WEBHOOK_SECRET = "test-stripe-webhook";
process.env.RAZORPAY_WEBHOOK_SECRET = "test-razorpay-webhook";
process.env.APPLE_BUNDLE_ID_RAMA = "org.likhita.rama";
process.env.APPLE_BUNDLE_ID_RAM = "org.likhita.ram";
