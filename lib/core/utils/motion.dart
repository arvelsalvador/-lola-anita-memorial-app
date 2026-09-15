import 'package:flutter/widgets.dart';

/// True when the OS requests reduced motion (e.g. Android "Remove
/// animations" / iOS "Reduce Motion").
///
/// Looping/decorative controllers (petals, glows, shimmers, pulses)
/// check this before calling `repeat()`/`forward()` so the memorial stays
/// still for visitors who need it to. Reads the platform dispatcher
/// (available in `initState`, unlike `MediaQuery.disableAnimationsOf`).
bool animationsDisabled() => WidgetsBinding
    .instance
    .platformDispatcher
    .accessibilityFeatures
    .disableAnimations;
