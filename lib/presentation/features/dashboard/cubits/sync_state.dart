sealed class SyncState {
  const SyncState();
}

final class SyncInitial extends SyncState {
  const SyncInitial();
}

final class SyncLoading extends SyncState {
  const SyncLoading();
}

final class SyncSuccess extends SyncState {
  const SyncSuccess();
}

final class SyncFailure extends SyncState {
  final String error;
  const SyncFailure(this.error);
}
