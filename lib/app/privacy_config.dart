import 'package:flutter/material.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

/// Privacy's accent in the suite (slate). The brand seed (indigo) is shared
/// by every app.
const Color privacyAccent = Color(0xFF64748B);

/// Privacy in the suite. Not in the core's `ZtSuite` list yet, so the other
/// apps don't link to it before it is released.
const ZtSuiteApp privacySuiteApp = ZtSuiteApp(
  appId: 'privacy',
  name: 'Privacy',
  tagline: 'See how private your phone is, and what to fix first',
  icon: Icons.shield_outlined,
  accent: privacyAccent,
  androidPackage: 'dev.sagron.zerotrustprivacy',
);

const ZtAppConfig privacyAppConfig = ZtAppConfig(
  appId: 'privacy',
  displayName: 'Zero-Trust Privacy',
  accent: privacyAccent,
);
