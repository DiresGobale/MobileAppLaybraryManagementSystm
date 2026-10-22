import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes/app_routes.dart';
import 'utils/backend_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bootstrap the data-source config BEFORE building the Provider tree so
  // `app_routes.providers()` can read the cached mode.
  await BackendConfig.instance.bootstrap();
  runApp(const IULMSApp());
}

class IULMSApp extends StatelessWidget {
  const IULMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppRoutes.providers(),
      child: MaterialApp(
        title: 'Injibara University Library',
        debugShowCheckedModeBanner: false,
        theme: AppRoutes.theme(),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
