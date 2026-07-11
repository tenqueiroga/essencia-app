import 'package:share_plus/share_plus.dart';

/// Mobile: uses native share sheet via share_plus.
Future<bool> platformShare(String text, String title) async {
  await Share.share(text, subject: title);
  return true;
}

bool get platformCanShare => true;
