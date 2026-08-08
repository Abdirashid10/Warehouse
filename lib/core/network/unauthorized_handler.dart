/// Global callback when the API returns 401 on an authenticated request.
class UnauthorizedHandler {
  void Function()? onSessionExpired;

  void notifySessionExpired() => onSessionExpired?.call();
}
