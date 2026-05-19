import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Retrieve current physical Device ID (equivalent to Capacitor Device.getId())
  Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Unique hardware fingerprint
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios_device_unknown';
    }
    return 'unknown_device_platform';
  }

  // Check License Key (Implements background validation without blocking the user)
  Future<Map<String, dynamic>?> checkLicense(String licenseKey, String currentDeviceId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('licenses').doc(licenseKey).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      // Ensure the license maps directly to the active physical device
      if (data['deviceId'] != currentDeviceId) {
        return null;
      }

      return data;
    } catch (e) {
      print("Firebase Service: License check failed: $e");
      rethrow;
    }
  }

  // Activate License for Device
  Future<bool> activateDeviceWithLicense(String licenseKey, String phoneNum, String currentDeviceId) async {
    try {
      final DocumentReference docRef = _firestore.collection('licenses').doc(licenseKey);
      final DocumentSnapshot docSnap = await docRef.get();

      if (!docSnap.exists) {
        throw Exception('كود التفعيل غير موجود');
      }

      final data = docSnap.data() as Map<String, dynamic>?;
      if (data != null && data['deviceId'] != null && data['deviceId'] != currentDeviceId) {
        throw Exception('كود التفعيل مستخدم بالفعل على جهاز آخر');
      }

      // Claim the activation key to current device
      await docRef.set({
        'deviceId': currentDeviceId,
        'phoneNumber': phoneNum,
        'activatedAt': FieldValue.serverTimestamp(),
        'isPremium': true,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print("Firebase Service: Error activating device: $e");
      rethrow;
    }
  }

  // Sync Offline Favorites and Notes to Firebase Firestore
  Future<void> syncUserDataToCloud(String userId, List<String> favorites, Map<String, String> notes) async {
    try {
      if (userId.isEmpty) return;
      await _firestore.collection('users').doc(userId).set({
        'favorites': favorites,
        'notes': notes,
        'lastSynced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Firebase Service: Failed to sync user data: $e");
    }
  }

  // Pull Cloud Favorites and Notes
  Stream<DocumentSnapshot> mockUserDataStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
}
