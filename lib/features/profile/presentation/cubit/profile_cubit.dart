import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';
import 'package:logisticsmobile/features/profile/domain/usecases/get_profile_usecase.dart';

class ProfileCubit extends Cubit<ResourceState<UserProfile>> {
  ProfileCubit(this._getProfile) : super(const ResourceState.initial());

  final GetProfileUseCase _getProfile;

  Future<void> load() async {
    emit(const ResourceState.loading());
    try {
      final profile = await _getProfile();
      emit(ResourceState.success(profile));
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load profile'));
    }
  }
}
