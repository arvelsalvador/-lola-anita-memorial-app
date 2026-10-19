part of 'admin_page.dart';

class _AdminPinDialog extends StatefulWidget {
  const _AdminPinDialog();

  @override
  State<_AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<_AdminPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _wrong = false;
  bool _checking = false;
  // Brute-force guard state (see [AdminPinGate]): after 5 wrong entries
  // the gate locks for 60s, in memory only.
  String? _lockError;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  /// Human-readable lockout note for the admin dialog (English-only
  /// page, like all admin copy).
  static String _lockMessage() =>
      'Too many wrong attempts — locked for ${AdminPinGate.secondsLeft}s.';

  void _submit() async {
    if (_checking) return;
    if (AdminPinGate.isLocked) {
      setState(() {
        _wrong = false;
        _lockError = _lockMessage();
      });
      return;
    }
    setState(() {
      _checking = true;
      _wrong = false;
      _lockError = null;
    });
    final expected = await _effectiveAdminPin();
    if (!mounted) return;
    if (_pinController.text.trim() == expected) {
      AdminPinGate.record(failed: false);
      Navigator.of(context).pop();
      Navigator.of(context).push(fadeRoute(const _ReportsAdminPage()));
      return;
    }
    AdminPinGate.record(failed: true);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _wrong = true;
      _lockError = AdminPinGate.isLocked ? _lockMessage() : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _adminText('admin_pin_title'),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _adminText('admin_pin_subtitle'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: _adminText('admin_pin_hint'),
              counterText: '',
              filled: true,
              fillColor: AppColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              errorText: _lockError ??
                  (_wrong ? _adminText('admin_pin_wrong') : null),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_adminText('admin_pin_cancel')),
        ),
        ElevatedButton(
          onPressed: (_checking || AdminPinGate.isLocked) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warmDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(_adminText('admin_pin_open')),
        ),
      ],
    );
  }
}

/// Change-PIN dialog, opened from the lock button in [_AdminHeader].
/// Verifies the current PIN, then saves a new 6-digit family PIN
/// on this device. Returns true when the PIN was changed.
class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog();

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  String? _errorKey;
  int _errorIndex = 2;
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _isPin(String v) => RegExp(r'^\d{6}$').hasMatch(v.trim());

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    final expected = await _effectiveAdminPin();
    if (!mounted) return;
    if (_currentCtrl.text.trim() != expected) {
      setState(() {
        _saving = false;
        _errorIndex = 0;
        _errorKey = 'admin_change_pin_wrong';
      });
      return;
    }
    if (!_isPin(_newCtrl.text) || !_isPin(_confirmCtrl.text)) {
      setState(() {
        _saving = false;
        _errorIndex = 1;
        _errorKey = 'admin_change_pin_invalid';
      });
      return;
    }
    if (_newCtrl.text.trim() != _confirmCtrl.text.trim()) {
      setState(() {
        _saving = false;
        _errorIndex = 2;
        _errorKey = 'admin_change_pin_mismatch';
      });
      return;
    }
    // [AdminCredential.changePin] re-hashes the PIN on the server first
    // and only saves on-device after the server accepts, so the database
    // verification (`pakikiramay_admin_change_pin`) and this device
    // always share one credential. A failed server call saves nothing.
    final synced = await AdminCredential.changePin(
      oldPin: _currentCtrl.text.trim(),
      newPin: _newCtrl.text.trim(),
    );
    if (!mounted) return;
    if (!synced) {
      setState(() {
        _saving = false;
        _errorIndex = 0;
        _errorKey = 'admin_report_action_failed';
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _adminText('admin_change_pin_title'),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.warmDark,
          height: 1.25,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pinField(
              controller: _currentCtrl,
            label: _adminText('admin_change_pin_current'),
            obscure: _obscureCurrent,
            onToggleEye: () =>
                setState(() => _obscureCurrent = !_obscureCurrent),
            errorText: _errorIndex == 0 && _errorKey != null
                ? _adminText(_errorKey!)
                : null,
            autofocus: true,
          ),
          const SizedBox(height: 14),
          _pinField(
            controller: _newCtrl,
            label: _adminText('admin_change_pin_new'),
            obscure: _obscureNew,
            onToggleEye: () =>
                setState(() => _obscureNew = !_obscureNew),
            errorText: _errorIndex == 1 && _errorKey != null
                ? _adminText(_errorKey!)
                : null,
          ),
          const SizedBox(height: 14),
          _pinField(
            controller: _confirmCtrl,
            label: _adminText('admin_change_pin_confirm'),
            obscure: _obscureConfirm,
            onToggleEye: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            errorText: _errorIndex == 2 && _errorKey != null
                ? _adminText(_errorKey!)
                : null,
          ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.warmDeep,
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(_adminText('admin_pin_cancel')),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warmDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 26,
              vertical: 12,
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(_adminText('admin_save')),
        ),
      ],
    );
  }

  Widget _pinField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleEye,
    required String? errorText,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      obscuringCharacter: '•',
      keyboardType: TextInputType.number,
      maxLength: 6,
      autofocus: autofocus,
      onSubmitted: (_) => _save(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        letterSpacing: 2,
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          color: AppColors.muted,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.warmDeep,
        ),
        counterText: '',
        filled: true,
        fillColor: AppColors.cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 20,
        ),
        suffixIcon: IconButton(
          onPressed: onToggleEye,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: AppColors.warmMid,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.stoneBorder.withValues(alpha: 0.9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.warmDeep,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.roseDeep),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.roseDeep,
            width: 1.4,
          ),
        ),
        errorText: errorText,
      ),
    );
  }
}

