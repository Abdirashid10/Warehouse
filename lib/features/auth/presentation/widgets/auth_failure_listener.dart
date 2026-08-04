import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/auth/auth_debug_config.dart';
import 'package:logisticsmobile/core/auth/auth_debug_log.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';

/// Surfaces auth failures visibly — never silently return to login.
class AuthFailureListener extends StatefulWidget {
  const AuthFailureListener({super.key, required this.child});

  final Widget child;

  @override
  State<AuthFailureListener> createState() => _AuthFailureListenerState();
}

class _AuthFailureListenerState extends State<AuthFailureListener> {
  AuthStatus? _lastStatus;
  bool _dialogShowing = false;

  void _presentFailure(BuildContext context, AuthState state) {
    final message = state.failureDetail ?? state.errorMessage;
    if (message == null || message.isEmpty) return;
    if (!AuthDebugConfig.showFailureDialogs) return;

    // Show either a SnackBar or a dialog — never both at once. This prevents
    // repeated unauthenticated transitions from stacking dialogs and freezing
    // the UI (ANR / "isn't responding").
    if (_dialogShowing) {
      _showSnackBar(context, message);
      return;
    }

    _dialogShowing = true;
    _showDialog(context, message);
  }

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 8),
        ),
      );
  }

  void _showDialog(BuildContext context, String message) {
    final isSessionExpired = message.toLowerCase().contains('session expired') ||
        message.toLowerCase().contains('401');
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          isSessionExpired ? Icons.lock_clock_outlined : Icons.error_outline,
          color: Theme.of(ctx).colorScheme.error,
          size: 32,
        ),
        title: Text(isSessionExpired ? 'Session expired' : 'Authentication failed'),
        content: SingleChildScrollView(
          child: Text(
            isSessionExpired
                ? 'Your secure session has ended. Sign in again to continue working in Logistics WMS.'
                : message,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _dialogShowing = false;
              context.read<AuthBloc>().add(const AuthFailureAcknowledged());
            },
            child: const Text('Sign in again'),
          ),
        ],
      ),
    ).whenComplete(() {
      _dialogShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        final becameUnauth =
            previous.status != AuthStatus.unauthenticated &&
            current.status == AuthStatus.unauthenticated;
        final hasFailure = current.showFailureAlert &&
            (current.failureDetail != null || current.errorMessage != null);
        final droppedFromAuth =
            _lastStatus == AuthStatus.authenticated &&
            current.status == AuthStatus.unauthenticated;
        return becameUnauth || hasFailure || droppedFromAuth;
      },
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          final detail = state.failureDetail ?? state.errorMessage;
          if (detail != null) {
            AuthDebugLog.blocTransition(
              from: _lastStatus?.name ?? '?',
              to: 'unauthenticated',
              detail: detail,
            );
            _presentFailure(context, state);
          } else {
            AuthDebugLog.blocTransition(
              from: _lastStatus?.name ?? '?',
              to: 'unauthenticated',
              detail: 'NO MESSAGE — silent redirect (bug)',
            );
            _presentFailure(
              context,
              state.copyWith(
                failureDetail:
                    'Returned to login with no error message.\n'
                    'Check console [Auth] logs for router redirect / session check / 401.',
                showFailureAlert: true,
              ),
            );
          }
        }
        _lastStatus = state.status;
      },
      child: widget.child,
    );
  }
}
