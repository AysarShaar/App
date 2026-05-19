import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/local_storage_service.dart';
import 'views/license_view.dart';
import 'views/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize standard Firebase setup configuration
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization skipped or previously loaded: $e");
  }

  // Initialize offline caching service
  final localStorage = await LocalStorageService.init();

  runApp(NationalQuizApp(storage: localStorage));
}

class NationalQuizApp extends StatefulWidget {
  final LocalStorageService storage;
  const NationalQuizApp({Key? key, required this.storage}) : super(key: key);

  @override
  _NationalQuizAppState createState() => _NationalQuizAppState();
}

class _NationalQuizAppState extends State<NationalQuizApp> {
  bool _isActivated = false;

  @override
  void initState() {
    super.initState();
    _checkActivationState();
  }

  void _checkActivationState() {
    final licenseKey = widget.storage.getLicenseKey();
    final deviceId = widget.storage.getActivatedDeviceId();
    final isTrial = widget.storage.isTrial();

    // If premium license matches or is trial, skip registration wall
    if ((licenseKey != null && deviceId != null) || isTrial) {
      _isActivated = true;
    }
  }

  void _handleActivationSuccess() {
    setState(() {
      _isActivated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الأرشيف الوطني للأسئلة الموحدة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF626F47),
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
      ),
      home: _isActivated
          ? MainNavigationShell(storage: widget.storage)
          : LicenseView(
              storage: widget.storage,
              onActivated: _handleActivationSuccess,
            ),
    );
  }
}
