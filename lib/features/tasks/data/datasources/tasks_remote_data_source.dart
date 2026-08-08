import 'package:dio/dio.dart';

import 'package:logisticsmobile/core/errors/api_exception.dart';

import 'package:logisticsmobile/core/errors/error_message_mapper.dart';

import 'package:logisticsmobile/core/network/api_constants.dart';

import 'package:logisticsmobile/core/network/json_list_parser.dart';

import 'package:logisticsmobile/features/tasks/data/models/task_model.dart';

import 'package:logisticsmobile/features/tasks/domain/entities/create_task_input.dart';

import 'package:logisticsmobile/features/tasks/domain/entities/task_assignee.dart';



class TasksRemoteDataSource {

  TasksRemoteDataSource(this._dio);



  final Dio _dio;



  Future<List<TaskModel>> fetchTasks({Map<String, dynamic>? query}) async {

    try {

      final response = await _dio.get<dynamic>(

        ApiConstants.tasks,

        queryParameters: query,

      );

      final maps = JsonListParser.extractMaps(response.data, keys: ['tasks']);

      return maps.map(TaskModel.fromJson).toList();

    } on DioException catch (e) {

      if (e.error is ApiException) rethrow;

      throw ApiException(message: ErrorMessageMapper.fromDioException(e));

    }

  }



  Future<TaskModel> fetchTask(String id) async {

    try {

      final response = await _dio.get<dynamic>('${ApiConstants.tasks}/$id');

      final data = response.data;

      Map<String, dynamic>? json;

      if (data is Map<String, dynamic>) {

        json = data['task'] is Map<String, dynamic>

            ? data['task'] as Map<String, dynamic>

            : data;

      }

      if (json == null) {

        throw const ApiException(message: 'Task not found');

      }

      return TaskModel.fromJson(json);

    } on DioException catch (e) {

      if (e.error is ApiException) rethrow;

      throw ApiException(message: ErrorMessageMapper.fromDioException(e));

    }

  }



  Future<TaskFormMeta> fetchFormMeta() async {

    try {

      final response = await _dio.get<dynamic>(ApiConstants.tasksMetaOptions);

      final data = response.data;

      if (data is! Map) {

        return const TaskFormMeta();

      }

      final map = Map<String, dynamic>.from(data);

      final warehousesRaw = map['warehouses'];

      final productsRaw = map['products'];

      final warehouses = <TaskFormWarehouse>[];

      final products = <TaskFormProduct>[];



      if (warehousesRaw is List) {

        for (final item in warehousesRaw) {

          if (item is! Map) continue;

          final w = Map<String, dynamic>.from(item);

          final id = (w['id'] ?? w['_id'] ?? '').toString();

          final name = (w['name'] ?? '').toString();

          if (id.isEmpty || name.isEmpty) continue;

          warehouses.add(

            TaskFormWarehouse(

              id: id,

              name: name,

              location: w['location']?.toString(),

            ),

          );

        }

      }



      if (productsRaw is List) {

        for (final item in productsRaw) {

          if (item is! Map) continue;

          final p = Map<String, dynamic>.from(item);

          final id = (p['id'] ?? p['_id'] ?? '').toString();

          final name = (p['name'] ?? '').toString();

          if (id.isEmpty || name.isEmpty) continue;

          products.add(

            TaskFormProduct(

              id: id,

              name: name,

              sku: p['sku']?.toString(),

            ),

          );

        }

      }



      return TaskFormMeta(warehouses: warehouses, products: products);

    } on DioException catch (e) {

      if (e.error is ApiException) rethrow;

      throw ApiException(message: ErrorMessageMapper.fromDioException(e));

    }

  }



  Future<List<TaskAssignee>> fetchAssignees(String warehouseId) async {

    try {

      final response = await _dio.get<dynamic>(

        ApiConstants.tasksMetaAssignees,

        queryParameters: {'warehouse_id': warehouseId},

      );

      final data = response.data;

      if (data is! Map) return const [];

      final staffRaw = data['staff'];

      if (staffRaw is! List) return const [];



      return staffRaw

          .whereType<Map>()

          .map((item) {

            final map = Map<String, dynamic>.from(item);

            return TaskAssignee(

              id: (map['id'] ?? map['_id'] ?? '').toString(),

              username: (map['username'] ?? '').toString(),

              fullName: (map['full_name'] ?? map['fullName'])?.toString(),

              email: map['email']?.toString(),

            );

          })

          .where((s) => s.id.isNotEmpty)

          .toList();

    } on DioException catch (e) {

      if (e.error is ApiException) rethrow;

      throw ApiException(message: ErrorMessageMapper.fromDioException(e));

    }

  }



  Future<TaskModel> createTask(CreateTaskInput input) async {

    try {

      final response = await _dio.post<dynamic>(

        ApiConstants.tasks,

        data: input.toJson(),

      );

      return _extractTaskModel(response.data);

    } on DioException catch (e) {

      if (e.error is ApiException) rethrow;

      throw ApiException(message: ErrorMessageMapper.fromDioException(e));

    }

  }



  Future<TaskModel> reassignTask({

    required String id,

    required ReassignTaskInput input,

  }) async {

    try {

      final response = await _dio.patch<dynamic>(

        '${ApiConstants.tasks}/$id',

        data: input.toJson(),

      );

      return _extractTaskModel(response.data);

    } on DioException catch (e) {

      if (e.error is ApiException) rethrow;

      throw ApiException(message: ErrorMessageMapper.fromDioException(e));

    }

  }



  Future<TaskModel> updateStatus({

    required String id,

    required String status,

    String? note,

  }) async {

    try {

      final response = await _dio.patch<dynamic>(

        '${ApiConstants.tasks}/$id/status',

        data: {

          'status': status,

          if (note != null && note.isNotEmpty) 'note': note,

        },

      );

      return _extractTaskModel(response.data);

    } on DioException catch (e) {

      if (e.error is ApiException) rethrow;

      throw ApiException(message: ErrorMessageMapper.fromDioException(e));

    }

  }



  TaskModel _extractTaskModel(dynamic data) {

    if (data is Map<String, dynamic>) {

      final task = data['task'];

      if (task is Map<String, dynamic>) return TaskModel.fromJson(task);

      return TaskModel.fromJson(data);

    }

    if (data is Map) {

      final map = Map<String, dynamic>.from(data);

      final task = map['task'];

      if (task is Map) return TaskModel.fromJson(Map<String, dynamic>.from(task));

      return TaskModel.fromJson(map);

    }

    throw const ApiException(message: 'Invalid task response');

  }

}


