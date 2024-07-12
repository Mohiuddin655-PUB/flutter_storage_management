import 'package:firebase_storage/firebase_storage.dart';

enum UploadStringFormat {
  base64(PutStringFormat.base64),
  base64Url(PutStringFormat.base64Url),
  dataUrl(PutStringFormat.dataUrl),
  raw(PutStringFormat.raw);

  final PutStringFormat value;

  const UploadStringFormat(this.value);
}
