/// Abuloy (GCash) details for the Pakikiramay tab.
///
/// Send abuloy to either account below. Each account owns its QR image
/// ([DonationAccount.qrAssetPath]); tapping a name shows that account's QR.
/// Names/numbers are intentionally masked on screen (e.g. "0909063 ****"),
/// while copy always uses the full [copyNumber].
/// The section still renders with a graceful placeholder when a QR asset
/// is absent, so the app never shows an error to a mourning visitor.
class DonationAccount {
  const DonationAccount({
    required this.accountName,
    required this.displayNumber,
    required this.copyNumber,
    required this.qrAssetPath,
  });

  /// Masked display name shown above the number (e.g. "MA*C AR**L S.").
  final String accountName;

  /// Masked number shown in the UI (e.g. "0909063 ****" — last 4 hidden).
  final String displayNumber;

  /// Plain full digits actually copied to the clipboard (e.g. "09090634076").
  final String copyNumber;

  /// Bundled QR image for this account.
  final String qrAssetPath;
}

class DonationDetails {
  DonationDetails._();

  /// Family GCash accounts visitors can send abuloy to.
  static const List<DonationAccount> accounts = [
    DonationAccount(
      accountName: 'MA*C AR**L S.',
      displayNumber: '0909063 ****',
      copyNumber: '09090634076',
      qrAssetPath: 'assets/images/donation/arvel_gcash.jpg',
    ),
    DonationAccount(
      accountName: 'LO**E S.',
      displayNumber: '0946835 ****',
      copyNumber: '09468357721',
      qrAssetPath: 'assets/images/donation/lorie_gcash.jpg',
    ),
  ];

  /// First account — kept so older call sites keep working.
  static String get accountName => accounts.first.accountName;

  /// First account number — kept so older call sites keep working.
  static String get gcashNumber => accounts.first.copyNumber;

  /// First account QR — kept so older call sites keep working.
  static String get qrAssetPath => accounts.first.qrAssetPath;
}
