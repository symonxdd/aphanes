/// Outbound links to the project's own public pages. One place for them,
/// so a repository move needs a single edit rather than a hunt through
/// call sites.
///
/// These open in an external browser and are the only outbound links the
/// app offers to itself; nothing here is contacted in the background.
abstract final class ProjectLinks {
  static const String repository = 'https://github.com/symonxdd/aphanes';

  /// The issue list rather than the new-issue form: landing on existing
  /// requests first is what keeps a duplicate from being filed, and
  /// filing a new one from there is a single tap away anyway.
  static const String issues = '$repository/issues';
}
