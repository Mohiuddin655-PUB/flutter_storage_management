import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'events.dart';
import 'response.dart';
import 'upload_string_format.dart';
import 'uploading_file.dart';

typedef FirebaseStorageConnectivityChecker = Future<bool> Function();

class FirebaseStorageService {
  final FirebaseStorageConnectivityChecker _checker;

  final _tempUrls = <String>[];

  Future<bool> get isConnected async => await _checker();

  Future<bool> get isDisconnected async => !(await isConnected);

  FirebaseStorageService._(this._checker);

  static FirebaseStorageService? _i;

  static FirebaseStorageService get i {
    final x = _i;
    if (x != null) {
      return x;
    } else {
      throw UnimplementedError("FirebaseStorageService not implemented yet!");
    }
  }

  static FirebaseStorageService get I => i;

  static FirebaseStorageService get instance => i;

  static FirebaseStorageService init({
    required FirebaseStorageConnectivityChecker connectivityChecker,
  }) {
    _i ??= FirebaseStorageService._(connectivityChecker);
    return _i!;
  }

  bool isComplete(int initial, int progress) => initial == progress;

  Future<StorageResponse<bool>> delete({required String url}) {
    return isConnected.then((connected) {
      if (connected) {
        final reference = FirebaseStorage.instance.refFromURL(url);
        return reference.delete().then((_) {
          return const StorageResponse(data: true);
        }).onError((_, __) {
          return StorageResponse(error: "$_");
        });
      } else {
        return const StorageResponse(networkError: true);
      }
    });
  }

  Future<StorageResponse<bool>> deletes({
    required List<String> urls,
    bool lazy = false,
  }) {
    return isConnected.then((connected) async {
      if (connected) {
        _tempUrls.clear();
        for (var url in urls) {
          final reference = FirebaseStorage.instance.refFromURL(url);
          if (lazy) {
            reference.delete().then((value) => _tempUrls.add("null"));
          } else {
            await reference.delete().then((value) => _tempUrls.add("null"));
          }
        }
        return StorageResponse(data: isComplete(urls.length, _tempUrls.length));
      } else {
        return const StorageResponse(networkError: true);
      }
    });
  }

  Future<StorageResponse<Uint8List>> download({
    required String url,
    int byteQuality = 10485760,
  }) {
    return isConnected.then((connected) {
      if (connected) {
        final reference = FirebaseStorage.instance.refFromURL(url);
        return reference.getData(byteQuality).onError((_, __) {
          return null;
        }).then((value) {
          return StorageResponse(data: value);
        });
      } else {
        return const StorageResponse(networkError: true);
      }
    });
  }

  double _uploadProgress(TaskSnapshot snapshot) {
    final transferred = snapshot.bytesTransferred;
    final total = snapshot.totalBytes;
    final progress = 100.0 * (transferred / total);
    return progress;
  }

  Reference _uploadReference(String path, String filename) {
    return FirebaseStorage.instance.ref(path).child(filename);
  }

  UploadTask _uploadTask({
    required String path,
    required dynamic data,
    required Reference reference,
    SettableMetadata? metadata,
    UploadStringFormat format = UploadStringFormat.raw,
    UploadDataType? type,
  }) {
    final mType = type ?? UploadDataType.from(data);
    if (mType.isBlob) {
      return reference.putBlob(data, metadata);
    } else if (mType.isString) {
      return reference.putString(
        data,
        format: format.value,
        metadata: metadata,
      );
    } else {
      if (kIsWeb) {
        return reference.putData(data, metadata);
      } else {
        return reference.putFile(data, metadata);
      }
    }
  }

  void upload({
    required String path,
    required UploadingFile data,
    UploadStringFormat format = UploadStringFormat.raw,
    void Function(UploadEvent<bool> event)? onCanceled,
    void Function(UploadEvent<String> event)? onDone,
    void Function(UploadEvent<String> event)? onError,
    void Function(UploadEvent<bool> event)? onLoading,
    void Function(UploadEvent<bool> event)? onNetworkError,
    void Function(UploadEvent<bool> event)? onPaused,
    void Function(UploadEvent<double> event)? onProgress,
  }) {
    final id = data.tag;
    onLoading?.call(UploadEvent(id: id, value: true));
    isConnected.then((connected) {
      if (connected) {
        final reference = _uploadReference(path, data.filename);
        _uploadTask(
          path: path,
          data: data.data,
          type: data.type,
          format: format,
          reference: reference,
          metadata: SettableMetadata(contentType: data.extension),
        ).snapshotEvents.listen((event) {
          switch (event.state) {
            case TaskState.canceled:
              onLoading?.call(UploadEvent(id: id, value: false));
              onCanceled?.call(UploadEvent(id: id, value: true));
              break;
            case TaskState.error:
              onLoading?.call(UploadEvent(id: id, value: false));
              onError?.call(UploadEvent(
                id: id,
                value: "Something went wrong!",
              ));
              break;
            case TaskState.paused:
              onLoading?.call(UploadEvent(id: id, value: false));
              onPaused?.call(UploadEvent(id: id, value: true));
              break;
            case TaskState.running:
              onProgress?.call(UploadEvent(
                id: data.tag,
                value: _uploadProgress(event),
              ));
              break;
            case TaskState.success:
              reference.getDownloadURL().then((url) {
                onLoading?.call(UploadEvent(id: id, value: false));
                onDone?.call(UploadEvent(id: id, value: url));
              }).catchError((_) {
                onLoading?.call(UploadEvent(id: id, value: false));
                onError?.call(UploadEvent(id: id, value: "$_"));
              });
              break;
          }
        }).onError((_) {
          onLoading?.call(UploadEvent(id: id, value: false));
          onError?.call(UploadEvent(id: id, value: "$_"));
        });
      } else {
        onLoading?.call(UploadEvent(id: id, value: false));
        onNetworkError?.call(UploadEvent(id: id, value: true));
      }
    });
  }

  void uploads({
    required String path,
    required List<UploadingFile> data,
    UploadStringFormat format = UploadStringFormat.raw,
    void Function(UploadEvent<bool> event)? onItemCanceled,
    void Function(UploadEvent<String> event)? onItemDone,
    void Function(UploadEvent<String> event)? onItemError,
    void Function(UploadEvent<bool> event)? onItemLoading,
    void Function(UploadEvent<bool> event)? onItemNetworkError,
    void Function(UploadEvent<bool> event)? onItemPaused,
    void Function(UploadEvent<double> event)? onItemProgress,
    void Function(StorageResponse<List<String>> response)? onResponse,
  }) {
    isConnected.then((connected) {
      if (connected) {
        _tempUrls.clear();
        onResponse?.call(const StorageResponse(loading: true));
        for (var item in data) {
          upload(
            path: path,
            data: item,
            format: format,
            onCanceled: (event) {
              _tempUrls.add("");
              if (onItemCanceled != null) onItemCanceled(event);
              if (onResponse != null) {
                if (isComplete(data.length, _tempUrls.length)) {
                  onResponse(StorageResponse(data: _tempUrls, loading: false));
                }
              }
            },
            onError: (event) {
              _tempUrls.add("");
              if (onItemError != null) onItemError(event);
              if (onResponse != null) {
                if (isComplete(data.length, _tempUrls.length)) {
                  onResponse(StorageResponse(data: _tempUrls, loading: false));
                }
              }
            },
            onNetworkError: (event) {
              _tempUrls.add("");
              if (onItemNetworkError != null) onItemNetworkError(event);
              if (onResponse != null) {
                if (isComplete(data.length, _tempUrls.length)) {
                  onResponse(StorageResponse(data: _tempUrls, loading: false));
                }
              }
            },
            onPaused: (event) {
              _tempUrls.add("");
              if (onItemPaused != null) onItemPaused(event);
              if (onResponse != null) {
                if (isComplete(data.length, _tempUrls.length)) {
                  onResponse(StorageResponse(data: _tempUrls, loading: false));
                }
              }
            },
            onProgress: onItemProgress,
            onDone: (event) {
              _tempUrls.add(event.value);
              if (onItemDone != null) onItemDone(event);
              if (onResponse != null) {
                if (isComplete(data.length, _tempUrls.length)) {
                  onResponse(StorageResponse(data: _tempUrls, loading: false));
                }
              }
            },
          );
        }
      } else {
        if (onResponse != null) {
          onResponse(const StorageResponse(loading: false));
        }
      }
    });
  }

  Future<StorageResponse<String>> uploadRequest({
    required String path,
    required UploadingFile data,
    UploadStringFormat format = UploadStringFormat.raw,
  }) {
    return isConnected.then((connected) {
      if (connected) {
        final reference = _uploadReference(path, data.filename);
        return _uploadTask(
          path: path,
          format: format,
          data: data.data,
          type: data.type,
          reference: reference,
          metadata: SettableMetadata(contentType: data.extension),
        ).then((_) {
          return reference.getDownloadURL().then((value) {
            return StorageResponse(data: value);
          });
        }).catchError((_) {
          return StorageResponse<String>(error: "$_");
        });
      } else {
        return const StorageResponse(networkError: true);
      }
    });
  }
}
