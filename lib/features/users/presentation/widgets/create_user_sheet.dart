import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/users/domain/entities/create_user_input.dart';
import 'package:logisticsmobile/features/users/presentation/cubit/users_cubit.dart';
import 'package:logisticsmobile/widgets/app_button.dart';
import 'package:logisticsmobile/widgets/app_text_field.dart';

Future<void> showCreateUserSheet(
  BuildContext context, {
  required UsersCubit cubit,
}) async {
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var role = UserRoleFilters.staff;
  var saving = false;
  var obscurePassword = true;
  String? apiError;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> submit() async {
            if (!(formKey.currentState?.validate() ?? false)) return;

            setSheetState(() {
              saving = true;
              apiError = null;
            });

            try {
              final created = await cubit.createUser(
                CreateUserInput(
                  username: usernameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passwordCtrl.text,
                  role: role,
                ),
              );
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                  content: Text('${created.displayName} created successfully'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: sheetContext.wms.success,
                ),
              );
            } on ApiException catch (e) {
              setSheetState(() {
                saving = false;
                apiError = ErrorMessageMapper.fromApiException(e);
              });
            } catch (_) {
              setSheetState(() {
                saving = false;
                apiError = 'Failed to create user. Please try again.';
              });
            }
          }

          final colors = WmsUiColors.of(context);
          final width = MediaQuery.sizeOf(context).width;
          final maxFormWidth = width >= WmsDesignTokens.tabletWidth ? 480.0 : width;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New user',
                                    style: WmsDesignTokens.sectionTitle(context),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Provision credentials and role.',
                                    style: WmsDesignTokens.body(context).copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: saving ? null : () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                              style: IconButton.styleFrom(
                                foregroundColor: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          controller: usernameCtrl,
                          label: 'Username',
                          hint: 'jane.doe',
                          textInputAction: TextInputAction.next,
                          enabled: !saving,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Username is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: emailCtrl,
                          label: 'Email',
                          hint: 'jane@company.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          enabled: !saving,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) return 'Email is required';
                            if (!_isValidEmail(trimmed)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: passwordCtrl,
                          label: 'Password',
                          hint: 'Enter password',
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          enabled: !saving,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: saving
                                ? null
                                : () => setSheetState(
                                      () => obscurePassword = !obscurePassword,
                                    ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Role',
                          style: WmsDesignTokens.supportingDense(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          key: ValueKey(role),
                          initialValue: role,
                          decoration: const InputDecoration(
                            hintText: 'Select role',
                          ),
                          isExpanded: true,
                          items: [
                            for (final r in UserRoleFilters.chips)
                              DropdownMenuItem(value: r, child: Text(r)),
                          ],
                          onChanged: saving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setSheetState(() => role = value);
                                },
                        ),
                        if (apiError != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            apiError!,
                            style: WmsDesignTokens.supporting(context).copyWith(
                              color: colors.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Cancel',
                                variant: AppButtonVariant.outline,
                                onPressed: saving
                                    ? null
                                    : () => Navigator.pop(sheetContext),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppButton(
                                label: 'Create User',
                                isLoading: saving,
                                onPressed: saving ? null : submit,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  usernameCtrl.dispose();
  emailCtrl.dispose();
  passwordCtrl.dispose();
}

bool _isValidEmail(String value) {
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
}
