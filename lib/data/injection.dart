import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'app_api.dart';

GetIt getIt = GetIt.instance;

Future setupInjection() async {
  await _registerNetworkComponents();
}

Future<void> _registerNetworkComponents() async {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://webhook.boffice.vn/RTC_signaling',
      connectTimeout: 10000,
    ),
  );
  _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
      maxWidth: 1000));

  _dio.interceptors
      .add(InterceptorsWrapper(onRequest: (options, handler) async {
    //Authentication
    return handler.next(options);
  }));

  getIt.registerSingleton(
      AppApi(_dio, baseUrl: 'https://webhook.boffice.vn/RTC_signaling'));
}
