import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';

class LicenseView extends StatefulWidget {
  final LocalStorageService storage;
  final VoidCallback onActivated;

  const LicenseView({
    Key? key,
    required this.storage,
    required this.onActivated,
  }) : super(key: key);

  @override
  _LicenseViewState createState() => _LicenseViewState();
}

class _LicenseViewState extends State<LicenseView> {
  final _keyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _errorMessage;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _handleActivation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentDeviceId = await _firebaseService.getDeviceId();
      final licenseKey = _keyController.text.trim();
      final phoneNum = _phoneController.text.trim();

      // Check key on firebase
      final status = await _firebaseService.checkLicense(licenseKey, currentDeviceId);
      
      if (status != null) {
        // Key already matches active device
        await _saveActivation(licenseKey, currentDeviceId, status['isPremium'] == true);
        return;
      }

      // Try activation (if first time or linking device)
      final success = await _firebaseService.activateDeviceWithLicense(
        licenseKey,
        phoneNum,
        currentDeviceId,
      );

      if (success) {
        await _saveActivation(licenseKey, currentDeviceId, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveActivation(String licenseKey, String deviceId, bool isPremium) async {
    await widget.storage.setLicenseKey(licenseKey);
    await widget.storage.setActivatedDeviceId(deviceId);
    await widget.storage.setPremium(isPremium);
    await widget.storage.setTrial(false);
    
    widget.onActivated();
  }

  void _startTrial() async {
    await widget.storage.setTrial(true);
    await widget.storage.setPremium(false);
    widget.onActivated();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.storage.isDarkMode();
    final primaryColor = const Color(0xFF626F47);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F6EE),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.vpn_key_rounded,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'تفعيل التطبيق',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.black,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل كود التفعيل المخصص لك للاستفادة بكامل ميزات الأرشيف ودورات الاختبارات الوطنية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 32),
                
                Card(
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: isDark ? Colors.black.withOpacity(0.4) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _keyController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'كود التفعيل الوطني',
                              hintText: 'مثال: NAT-XXXX-XXXX',
                              prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'الرجاء إدخال كود التفعيل' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'رقم الهاتف الخاص بك',
                              hintText: '09xxxxxxxx',
                              prefixIcon: Icon(Icons.phone_android_rounded, color: primaryColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) => val == null || val.trim().length < 10 ? 'الرجاء إدخال رقم هاتف صحيح' : null,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _handleActivation,
                            child: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('تفعيل الآن 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.black, fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _startTrial,
                  child: Text(
                    'تخطي وتجربة النسخة المجانية المحدودة ⏱️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo', 
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
