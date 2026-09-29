import '../domain/domain.dart';

String normalizeRepository(String input) {
  var value = input.trim().replaceFirst(
    RegExp(r'^git@github\.com:'),
    'https://github.com/',
  );
  if (!value.contains('://')) value = 'https://github.com/$value';
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'github.com' ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const TugException(
      'Repository must be a GitHub repository without embedded credentials.',
    );
  }
  final path = uri.path
      .replaceFirst(RegExp(r'\.git$'), '')
      .replaceFirst(RegExp(r'/$'), '');
  if (!RegExp(r'^/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(path)) {
    throw const TugException('Invalid GitHub repository path.');
  }
  return 'https://github.com$path';
}
