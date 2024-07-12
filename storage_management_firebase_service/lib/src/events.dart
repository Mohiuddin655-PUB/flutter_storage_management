abstract class StorageEvent {
  final Object? id;

  const StorageEvent({
    this.id,
  });

  @override
  String toString() {
    return "$StorageEvent(id: $id)";
  }
}

class DownloadEvent extends StorageEvent {
  const DownloadEvent({
    required super.id,
  });

  @override
  String toString() {
    return "$DownloadEvent(id: $id)";
  }
}

class UploadEvent<T extends Object> extends StorageEvent {
  final T value;

  const UploadEvent({
    required super.id,
    required this.value,
  });

  @override
  String toString() {
    return "$UploadEvent(id: $id, value: $value)";
  }
}
