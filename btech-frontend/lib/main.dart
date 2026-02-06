import 'package:flutter/material.dart';
import 'routes/app_router.dart';

import 'package:provider/provider.dart';
import 'core/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => NotificationProvider()..initSocket()),
      ],
      child: const BTechApp(),
    ),
  );
}

class BTechApp extends StatelessWidget {
  const BTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BTECH Plus',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052cc), // Brand Blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
