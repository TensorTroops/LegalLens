import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import '../providers/auth_provider.dart' as auth_provider;
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../services/pdf_download_service_mobile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  String _getInitialLetter(User? user) {
    // Check display name first
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.substring(0, 1).toUpperCase();
    }
    
    // Check email if display name is not available
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }
    
    // Default fallback
    return 'U';
  }

  String _getDisplayName(User? user) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return 'User';
  }

  String _getEmail(User? user) {
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    return 'No email available';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<auth_provider.AuthProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            _buildUserProfileSection(user),
            
            const SizedBox(height: 24),
            
            // Security Section
            _buildSecuritySection(authProvider),
            
            const SizedBox(height: 24),
            
            // App Preferences Section
            _buildAppPreferencesSection(),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildAboutSection(),
            
            const SizedBox(height: 32),
            
            // Sign Out Button
            _buildSignOutButton(authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection(User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF4285F4),
                child: Text(
                  _getInitialLetter(user),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(user),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getEmail(user),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(auth_provider.AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          
          // Biometric Authentication Toggle
          _buildSettingTile(
            icon: Icons.fingerprint,
            title: 'Biometric Authentication',
            subtitle: authProvider.isBiometricEnabled 
              ? 'Fingerprint login enabled' 
              : 'Tap to enable fingerprint login',
            trailing: Switch(
              value: authProvider.isBiometricEnabled,
              onChanged: _isLoading ? null : (value) => _toggleBiometric(authProvider, value),
              activeThumbColor: const Color(0xFF4285F4),
            ),
          ),
          
          const Divider(height: 1),
          
          // Biometric for GCUL Operations
          if (authProvider.isBiometricEnabled) ...[
            _buildSettingTile(
              icon: Icons.security,
              title: 'Secure Document Operations',
              subtitle: 'Require fingerprint for sensitive document operations',
              trailing: Switch(
                value: authProvider.biometricForGCUL,
                onChanged: (value) => authProvider.setBiometricForGCUL(value),
                activeThumbColor: const Color(0xFF4285F4),
              ),
            ),
            const Divider(height: 1),
          ],
          
          // Test Notifications
          _buildSettingTile(
            icon: Icons.notifications_active,
            title: 'Test Notifications',
            subtitle: 'Test if notifications are working properly',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
            onTap: () => _testNotifications(),
          ),
          
          const Divider(height: 1),
          
          // Test PDF Download Notification
          _buildSettingTile(
            icon: Icons.picture_as_pdf,
            title: 'Test PDF Download',
            subtitle: 'Test PDF download and notification with file opening',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
            onTap: () => _testPDFDownload(),
          ),
          
          const Divider(height: 1),
          
          // Change Password
          _buildSettingTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your account password',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
            onTap: () => _showChangePasswordDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),
          
          const Divider(height: 1),
          
          _buildSettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Theme',
            subtitle: 'Choose your preferred theme',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
            onTap: () {
              // TODO: Navigate to theme settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSettingTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
            trailing: null,
          ),
          
          const Divider(height: 1),
          
          _buildSettingTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Learn how we protect your data',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          
          const Divider(height: 1),
          
          _buildSettingTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
            onTap: () {
              // TODO: Show terms of service
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4285F4),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(auth_provider.AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _signOut(authProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade500,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }

  Future<void> _toggleBiometric(auth_provider.AuthProvider authProvider, bool value) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      if (value) {
        // Enable biometric
        final result = await authProvider.enableBiometric();
        
        if (result == BiometricEnrollmentResult.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric authentication enabled successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          String errorMessage = 'Failed to enable biometric authentication';
          
          switch (result) {
            case BiometricEnrollmentResult.deviceNotSupported:
              errorMessage = 'Biometric authentication is not available on this device';
              break;
            case BiometricEnrollmentResult.userCancelled:
              errorMessage = 'Setup was cancelled. Please try again to enable biometric authentication.';
              break;
            case BiometricEnrollmentResult.error:
              errorMessage = 'An error occurred while setting up biometric authentication';
              break;
            default:
              break;
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        // Disable biometric
        await authProvider.disableBiometric();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication disabled'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut(auth_provider.AuthProvider authProvider) async {
    setState(() => _isLoading = true);

    try {
      await authProvider.signOut();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testPDFDownload() async {
    try {
      // Create a simple test PDF content
      final testContent = '''Test PDF Content
      
This is a test PDF file to verify that the notification system works correctly.

- File saved successfully ✅
- Notification shown ✅  
- Tap to open functionality ✅

Generated at: ${DateTime.now()}
''';
      
      final bytes = testContent.codeUnits;
      final filename = 'test_legallens_notification.txt'; // Using .txt for simplicity
      
      // Use our PDF download service to create and notify
      final filePath = await PDFDownloadService.downloadPDFToLocal(
        pdfBytes: Uint8List.fromList(bytes),
        filename: filename,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test file created at: $filePath\nNotification should appear!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create test file: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _testNotifications() async {
    try {
      await NotificationService.testNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent! Check your notification panel.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    // TODO: Implement change password functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('This feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}