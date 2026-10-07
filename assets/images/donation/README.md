# Donation (Abuloy) assets

Drop the family's GCash QR here as:

  gcash-qr.png

Referenced by `DonationDetails.qrAssetPath` and rendered by
`lib/views/condolences/donation_section.dart`. Until the file exists,
the section shows a graceful placeholder (no error).

Also update the real values in `lib/core/constants/donation.dart`:
`accountName` + `gcashNumber`.
