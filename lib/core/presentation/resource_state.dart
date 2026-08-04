import 'package:equatable/equatable.dart';

enum ResourceStatus { initial, loading, success, empty, failure }

class ResourceState<T> extends Equatable {
  const ResourceState({
    this.status = ResourceStatus.initial,
    this.data,
    this.message,
  });

  const ResourceState.initial() : this();

  const ResourceState.loading({T? data})
      : this(status: ResourceStatus.loading, data: data);

  const ResourceState.success(T data)
      : this(status: ResourceStatus.success, data: data);

  const ResourceState.empty({String? message})
      : this(status: ResourceStatus.empty, message: message);

  const ResourceState.failure(String message, {T? data})
      : this(status: ResourceStatus.failure, message: message, data: data);

  final ResourceStatus status;
  final T? data;
  final String? message;

  bool get isLoading => status == ResourceStatus.loading;
  bool get isSuccess => status == ResourceStatus.success;
  bool get isEmpty => status == ResourceStatus.empty;
  bool get isFailure => status == ResourceStatus.failure;

  ResourceState<T> copyWith({
    ResourceStatus? status,
    T? data,
    String? message,
  }) {
    return ResourceState(
      status: status ?? this.status,
      data: data ?? this.data,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, data, message];
}
