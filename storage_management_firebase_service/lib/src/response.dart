class StorageResponse<T extends Object> {
  final bool loading;
  final bool successful;
  final bool networkError;
  final String? error;
  final T? data;

  const StorageResponse({
    this.loading = false,
    this.networkError = false,
    this.error,
    this.data,
  }) : successful = data != null;

  List<String> get urls {
    final x = data;
    if (x is List<String>) {
      return x.where((_) => _.isNotEmpty).toList();
    } else {
      return [];
    }
  }

  @override
  String toString() {
    return "$StorageResponse(loading: $loading, successful: $successful, networkError: $networkError, error: $error, data: $data)";
  }
}
