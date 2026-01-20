import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/expense.dart';
import 'storage_service.dart';

/// Google Drive backup service for expense tracker data.
///
/// Privacy & Compliance Notes:
/// - Uses ONLY the `drive.appdata` scope, which grants access to a special
///   hidden folder on Google Drive that only this app can read/write.
/// - This folder is NOT visible to users in their Drive UI, ensuring privacy.
/// - No access to user's general Drive files or folders.
/// - Compliant with Google Play Store policies and OAuth best practices.
/// - Data is encrypted before upload to ensure additional privacy.
///
/// Scope used: https://www.googleapis.com/auth/drive.appdata
/// This restricted scope is used because:
/// 1. App only needs to store its own backup data
/// 2. Users' personal Drive files remain completely inaccessible
/// 3. Minimizes permission footprint per Google's principle of least privilege
/// 4. Required for Play Store approval with sensitive scopes
///
/// ANDROID SETUP REQUIRED:
/// Before Google Sign-In works, you must configure OAuth 2.0 in Google Cloud Console:
/// 
/// Step 1: Create Google Cloud Project
///   - Go to https://console.cloud.google.com
///   - Create a new project or select existing one
///   - Note the project name
/// 
/// Step 2: Enable Google Drive API
///   - In the Cloud Console, go to "APIs & Services" → "Library"
///   - Search for "Google Drive API"
///   - Click "Enable"
/// 
/// Step 3: Create Android OAuth 2.0 Client
///   - Go to "APIs & Services" → "Credentials"
///   - Click "Create Credentials" → "OAuth 2.0 Client ID"
///   - Select "Android" as application type
///   - Package name: com.example.expense_tracker (must match android/app/build.gradle.kts)
///   - Get SHA-1 fingerprint of your signing certificate:
///     
///     For DEBUG builds (testing):
///     Run in terminal: keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
///     
///     For RELEASE builds (production):
///     Run: keytool -list -v -keystore path\to\your\release.keystore -alias your_alias
///     
///   - Copy the SHA-1 fingerprint and paste it in the OAuth client config
///   - Click "Create"
/// 
/// Step 4: (Optional) Create Web OAuth Client for serverClientId
///   - This may be needed in some cases for Google Sign-In to work
///   - Create another OAuth client, but select "Web application"
///   - Copy the Client ID
///   - Add it to GoogleSignIn config below as: serverClientId: 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com'
/// 
/// Step 5: Test
///   - Rebuild the app completely: flutter clean && flutter pub get && flutter run
///   - Try signing in - it should now work
/// 
/// Troubleshooting:
///   - Error "DEVELOPER_ERROR" = Wrong SHA-1 or package name mismatch
///   - Sign-in cancelled immediately = No OAuth client configured
///   - Check debug console for error messages
class DriveBackupService {
  static const String _backupFileName = 'expense_tracker_backup.enc';
  
  // CRITICAL: Only request drive.appdata scope for privacy and compliance
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.appdata'],
    // Uncomment and add your Web OAuth Client ID if sign-in fails:
    // serverClientId: 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com',
  );

  // Encryption key derived from a constant + user email
  // For production, consider using Flutter Secure Storage or device keystore
  static const String _baseKey = 'ExpenseTrackerSecureKey2026!@#';

  /// Signs in the user with Google and returns true if successful.
  /// Handles user cancellation gracefully.
  /// 
  /// SETUP REQUIRED (if sign-in fails):
  /// 1. Go to Google Cloud Console (console.cloud.google.com)
  /// 2. Create/Select a project
  /// 3. Enable Google Drive API
  /// 4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
  /// 5. Select "Android" application type
  /// 6. Enter package name: com.example.expense_tracker (from build.gradle.kts)
  /// 7. Get SHA-1 fingerprint:
  ///    - Debug: Run `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android`
  ///    - Release: Use your release keystore
  /// 8. Add the SHA-1 fingerprint to the OAuth client
  /// 9. (Optional) Create a "Web" OAuth client ID and add to _googleSignIn config as serverClientId
  /// 
  /// Common Errors:
  /// - ApiException: 10 (DEVELOPER_ERROR) = SHA-1/package name mismatch or OAuth not configured
  /// - Ensure you're using the DEBUG keystore SHA-1 for debug builds
  /// - Wait 5-10 minutes after creating OAuth client for Google to propagate changes
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      // Log detailed error for debugging
      print('Google Sign-In Error: $e');
      
      // Check for specific error codes
      if (e.toString().contains('ApiException: 10')) {
        print('');
        print('⚠️  DEVELOPER_ERROR (Code 10) - OAuth 2.0 Configuration Issue');
        print('');
        print('This error means Google Sign-In is not properly configured.');
        print('');
        print('SOLUTION:');
        print('1. Get your DEBUG SHA-1 fingerprint by running in terminal:');
        print('   keytool -list -v -keystore "%USERPROFILE%\\.android\\debug.keystore" -alias androiddebugkey -storepass android -keypass android');
        print('');
        print('2. Copy the SHA-1 value (e.g., AA:BB:CC:...)');
        print('');
        print('3. Go to: https://console.cloud.google.com/apis/credentials');
        print('');
        print('4. Create OAuth 2.0 Client ID for Android:');
        print('   - Application type: Android');
        print('   - Package name: com.example.expense_tracker');
        print('   - SHA-1: [paste your SHA-1 from step 2]');
        print('');
        print('5. Also enable Google Drive API at:');
        print('   https://console.cloud.google.com/apis/library/drive.googleapis.com');
        print('');
        print('6. Wait 5 minutes, then rebuild: flutter clean && flutter run');
        print('');
      }
      
      return false;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Returns the currently signed-in user's email, or null if not signed in.
  String? getCurrentUserEmail() {
    return _googleSignIn.currentUser?.email;
  }

  /// Checks if user is currently signed in.
  bool isSignedIn() {
    return _googleSignIn.currentUser != null;
  }

  /// Creates a backup of all app data and uploads to Google Drive AppDataFolder.
  ///
  /// Returns a status message on success or throws an exception on failure.
  /// Handles offline scenarios by checking authentication state.
  Future<String> createBackup(StorageService storage) async {
    // Ensure user is signed in
    final currentUser = _googleSignIn.currentUser;
    if (currentUser == null) {
      throw Exception('Not signed in. Please sign in first.');
    }

    // Get authentication headers
    final authHeaders = await currentUser.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    // Export all data from storage
    final backupData = _exportAllData(storage);
    final jsonData = json.encode(backupData);

    // Encrypt the data
    final encryptedData = _encryptData(jsonData, currentUser.email);

    try {
      // Check if backup file already exists in AppDataFolder
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='$_backupFileName'",
        $fields: 'files(id, name)',
      );

      String? fileId;
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        fileId = fileList.files!.first.id;
      }

      // Upload or update file
      final media = drive.Media(Stream.value(encryptedData), encryptedData.length);

      if (fileId != null) {
        // Update existing backup - do NOT set `parents` on update requests.
        final updateFile = drive.File();
        updateFile.name = _backupFileName;
        await driveApi.files.update(
          updateFile,
          fileId,
          uploadMedia: media,
        );
      } else {
        // Create new backup and set parent to AppDataFolder
        final createFile = drive.File();
        createFile.name = _backupFileName;
        createFile.parents = ['appDataFolder'];
        await driveApi.files.create(
          createFile,
          uploadMedia: media,
        );
      }

      return 'Backup created successfully';
    } catch (e) {
      print('Drive Backup Error: $e');
      if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Backup failed: ${e.toString()}');
    } finally {
      authenticateClient.close();
    }
  }

  /// Restores app data from the latest Google Drive backup.
  ///
  /// Returns a status message on success or throws an exception on failure.
  /// Safely replaces existing local data after successful decryption.
  Future<String> restoreBackup(StorageService storage) async {
    // Ensure user is signed in
    final currentUser = _googleSignIn.currentUser;
    if (currentUser == null) {
      throw Exception('Not signed in. Please sign in first.');
    }

    // Get authentication headers
    final authHeaders = await currentUser.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    try {
      // Find backup file in AppDataFolder
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name='$_backupFileName'",
        $fields: 'files(id, name)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception('No backup found on Google Drive');
      }

      final fileId = fileList.files!.first.id!;

      // Download encrypted backup
      final drive.Media media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (var data in media.stream) {
        dataStore.addAll(data);
      }

      final encryptedData = Uint8List.fromList(dataStore);

      // Decrypt the data
      final decryptedJson = _decryptData(encryptedData, currentUser.email);
      final backupData = json.decode(decryptedJson) as Map<String, dynamic>;

      // Import data to storage
      await _importAllData(storage, backupData);

      return 'Backup restored successfully';
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      if (e.toString().contains('No backup found')) {
        rethrow;
      }
      throw Exception('Restore failed: ${e.toString()}');
    } finally {
      authenticateClient.close();
    }
  }

  /// Exports all app data into a single map for backup.
  Map<String, dynamic> _exportAllData(StorageService storage) {
    // Get raw SharedPreferences data
    final expenses = storage.loadExpenses();
    final categories = storage.loadCategories();
    
    // Export budgets - we need all budgets, not just current month
    // Access the raw budget data from SharedPreferences
    final budgetsRaw = storage.prefs.getString('budgets_v1') ?? '{}';

    return {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'categories': categories,
      'budgets_raw': budgetsRaw,
    };
  }

  /// Imports backup data into storage.
  Future<void> _importAllData(StorageService storage, Map<String, dynamic> backupData) async {
    final version = backupData['version'] as int;
    if (version != 1) {
      throw Exception('Unsupported backup version: $version');
    }

    // Import expenses
    final expensesData = backupData['expenses'] as List<dynamic>;
    final expenses = expensesData.map((e) {
      return Expense.fromMap(e as Map<String, dynamic>);
    }).toList();
    await storage.saveExpenses(expenses);

    // Import categories
    final categoriesData = backupData['categories'] as Map<String, dynamic>;
    final categories = categoriesData.map((k, v) {
      return MapEntry(k, (v as List<dynamic>).map((e) => e as String).toList());
    });
    await storage.saveCategories(categories);

    // Import budgets (raw)
    final budgetsRaw = backupData['budgets_raw'] as String;
    await storage.prefs.setString('budgets_v1', budgetsRaw);
  }

  /// Encrypts data using AES encryption with a key derived from base key + user email.
  Uint8List _encryptData(String data, String userEmail) {
    // Derive a 32-byte key from base key + user email
    final keyString = _baseKey + userEmail;
    final keyBytes = encrypt_lib.Key.fromUtf8(keyString.padRight(32).substring(0, 32));
    final iv = encrypt_lib.IV.fromLength(16);

    final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(keyBytes));
    final encrypted = encrypter.encrypt(data, iv: iv);

    // Prepend IV to encrypted data for decryption
    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  /// Decrypts data using AES encryption with a key derived from base key + user email.
  String _decryptData(Uint8List encryptedData, String userEmail) {
    // Extract IV and encrypted bytes
    final iv = encrypt_lib.IV(encryptedData.sublist(0, 16));
    final encryptedBytes = encryptedData.sublist(16);

    // Derive key
    final keyString = _baseKey + userEmail;
    final keyBytes = encrypt_lib.Key.fromUtf8(keyString.padRight(32).substring(0, 32));

    final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(keyBytes));
    final encrypted = encrypt_lib.Encrypted(encryptedBytes);

    return encrypter.decrypt(encrypted, iv: iv);
  }
}

/// HTTP client with Google authentication headers for API calls.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
  }
}
