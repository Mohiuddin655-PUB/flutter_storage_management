import 'dart:io';
import 'dart:typed_data';

class UploadingFile {
  final dynamic data;
  final String filename;
  final String? extension;
  final String? tag;
  final UploadDataType? type;

  const UploadingFile({
    required this.data,
    required this.filename,
    this.extension,
    this.tag,
    this.type,
  });

  @override
  String toString() {
    return "$UploadingFile(data: $data, filename: $filename, extension: $extension, tag: $tag, type: $type)";
  }
}

enum UploadDataType {
  blob,
  bytes,
  file,
  string;

  bool get isBlob => this == blob;

  bool get isBytes => this == bytes;

  bool get isFile => this == file;

  bool get isString => this == string;

  factory UploadDataType.from(dynamic data) {
    if (data is String) {
      return UploadDataType.string;
    } else if (data is Uint8List || data is List<int>) {
      return UploadDataType.bytes;
    } else if (data is File) {
      return UploadDataType.file;
    } else {
      return UploadDataType.blob;
    }
  }
}
