/// Abuloy (GCash) details for the Pakikiramay tab.
///
/// Fill in the family's real values here. The QR image itself lives at
/// [qrAssetPath] — drop the file at `assets/images/donation/gcash-qr.png`.
/// Until both are set, the section still renders with a graceful
/// placeholder so the app never shows an error to a mourning visitor.
class DonationDetails {
  DonationDetails._();

  /// Display name shown under the QR (e.g. "Lorie S.").
  // TODO(family): replace with the real GCash account name.
  static const String accountName = 'Family GCash';

  /// GCash mobile number visitors send abuloy to.
  // TODO(family): replace with the real GCash number, e.g. '0917 123 4567'.
  static const String gcashNumber = '09xx xxx xxxx';

  /// Bundled QR image. Add the file at this path; the widget falls back
  /// to a placeholder when it is absent.
  static const String qrAssetPath = 'assets/images/donation/gcash-qr.png';
}
