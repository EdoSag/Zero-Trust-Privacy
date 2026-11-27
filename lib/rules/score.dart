import '../phone/phone_snapshot.dart';
import 'finding.dart';
import 'rules.dart';

/// One line of the score: a kind of finding and what it costs right now.
class ScoreLine {
  const ScoreLine({
    required this.rule,
    required this.open,
    required this.accepted,
  });

  final Rule rule;

  /// Findings that count.
  final int open;

  /// Findings the user said they are fine with. They cost nothing.
  final int accepted;

  /// Points taken off for this kind, never more than its cap.
  int get deducted {
    final cost = open * rule.points;
    return cost > rule.cap ? rule.cap : cost;
  }
}

/// The phone, what was found on it, and the score that follows.
class PrivacyReport {
  PrivacyReport({required this.phone, required Set<String> accepted})
    : findings = findFindings(phone),
      _accepted = accepted;

  final PhoneSnapshot phone;
  final List<Finding> findings;
  final Set<String> _accepted;

  bool isAccepted(Finding finding) => _accepted.contains(finding.id);

  /// Findings that still count, heaviest first.
  late final List<Finding> open = [
    for (final finding in findings)
      if (!isAccepted(finding)) finding,
  ];

  late final List<Finding> accepted = [
    for (final finding in findings)
      if (isAccepted(finding)) finding,
  ];

  /// A line for every kind with at least one finding, open or accepted.
  late final List<ScoreLine> lines = [
    for (final rule in Rule.values)
      if (findings.any((f) => f.rule == rule))
        ScoreLine(
          rule: rule,
          open: open.where((f) => f.rule == rule).length,
          accepted: accepted.where((f) => f.rule == rule).length,
        ),
  ];

  /// 100 with nothing to point out; never below 0.
  late final int score =
      (100 - lines.fold<int>(0, (sum, l) => sum + l.deducted)).clamp(0, 100);

  /// What to fix first: the open findings that cost the most, one per app
  /// at most so that a single app does not fill the list.
  List<Finding> fixNext([int count = 4]) {
    final sorted = [...open]
      ..sort((a, b) {
        final points = b.rule.points.compareTo(a.rule.points);
        return points != 0 ? points : a.rule.index.compareTo(b.rule.index);
      });
    final seen = <String>{};
    return [
      for (final finding in sorted)
        if (finding.package == null || seen.add(finding.package!)) finding,
    ].take(count).toList();
  }

  List<Finding> forApp(String package) => [
    for (final finding in findings)
      if (finding.package == package) finding,
  ];

  List<Finding> openAbout({required bool apps}) => [
    for (final finding in open)
      if (finding.rule.aboutApp == apps) finding,
  ];
}
