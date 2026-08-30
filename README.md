# FMUG Conference Application

## Development setup

The application uses Ruby 3.4.2 and PostgreSQL. After creating the development
database, run:

    bin/rails db:setup

The development seed creates or updates the administrator account for Patrick
Koers (`pkoers75@gmail.com`). It sets the existing `Chair FMUG` role and the
`admin` flag. The seed is idempotent and runs only when `Rails.env.development?`
is true; it does not create identities, invitations, registrations, or magic
links.

To provision or re-provision the account explicitly:

    bin/rails db:seed

### Development login

The application has no password login. To use the existing magic-link
authentication without sending email, create a link in a development Rails
console:

    bin/rails console
    user = User.find_by!(email: "pkoers75@gmail.com")
    login_magic_link = user.login_magic_links.create!
    puts "http://localhost:3000/login-magic-links/#{login_magic_link.raw_token}"

Open the printed URL in the local development browser. This creates only the
digest-backed login-link record and signs in that user when the URL is opened;
it does not call `EmailDeliveryService` or Brevo. Do not use this procedure
against production or shared staging data.

Alternatively, when Google OAuth is configured for development, signing in
with the Google account whose email is `pkoers75@gmail.com` matches the seeded
user by email and attaches the Google identity through the normal callback.

## Tests

Run the Rails test suite with:

    bin/rails test
