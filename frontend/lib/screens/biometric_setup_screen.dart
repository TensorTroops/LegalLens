import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_service.dart';

/// Professional Biometric Setup Screen for LegalLens
/// 
/// Guides users through fingerprint enrollment process with:
/// - Clear security messaging
/// - Professional UI design
/// - Error handling
/// - Skip options
class BiometricSetupScreen extends StatefulWidget {
  final bool isFromSettings;
  
  const BiometricSetupScreen({
    super.key,
    this.isFromSettings = false,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _isEnrolling = false;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: const Text(
              'Biometric Security',
              style: TextStyle(
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Security Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getBiometricIcon(authProvider.biometricCapability),
                    size: 60,
                    color: const Color(0xFF4285F4),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'Secure Your Legal Documents',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  _getBiometricDescription(authProvider.biometricCapability),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Security Features
                _buildSecurityFeatures(),
                
                const SizedBox(height: 48),
                
                // Action Buttons
                if (authProvider.biometricCapability != BiometricCapability.none) ...[
                  // Enable Biometric Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isEnrolling ? null : _enableBiometric,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isEnrolling
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Setting up...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.fingerprint,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Enable ${_getBiometricName(authProvider.biometricCapability)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  if (!widget.isFromSettings) ...[
                    const SizedBox(height: 16),
                    
                    // Skip Button
                    TextButton(
                      onPressed: _skipSetup,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  // Device not supported
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.orange[700],
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Biometric authentication is not available on this device.',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your documents will still be secured with your password and GCUL blockchain technology.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _skipSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityFeatures() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: const Color(0xFF4285F4),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Security Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildFeatureItem(
            Icons.lock_outline,
            'Hardware Security',
            'Biometric data never leaves your device',
          ),
          _buildFeatureItem(
            Icons.verified_outlined,
            'GCUL Blockchain',
            'Enhanced protection for document access',
          ),
          _buildFeatureItem(
            Icons.speed_outlined,
            'Quick Access',
            'Instant login to your legal documents',
          ),
          _buildFeatureItem(
            Icons.privacy_tip_outlined,
            'Privacy First',
            'No biometric data stored or transmitted',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF4285F4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _enableBiometric() async {
    setState(() {
      _isEnrolling = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.enableBiometric();
    
    setState(() {
      _isEnrolling = false;
    });
    
    if (!mounted) return;
    
    switch (result) {
      case BiometricEnrollmentResult.success:
        _showSuccessDialog();
        break;
      
      case BiometricEnrollmentResult.deviceNotSupported:
        _showErrorDialog(
          'Device Not Supported',
          'Biometric authentication is not supported on this device.',
        );
        break;
      
      case BiometricEnrollmentResult.userCancelled:
        // User cancelled - no action needed
        break;
      
      case BiometricEnrollmentResult.error:
        _showErrorDialog(
          'Setup Failed',
          'Failed to enable biometric authentication. Please ensure your device has biometric authentication set up and try again.',
        );
        break;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Biometric Security Enabled!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You can now use fingerprint authentication to quickly and securely access your legal documents.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                if (widget.isFromSettings) {
                  Navigator.pop(context); // Go back to settings
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _skipSetup() {
    if (widget.isFromSettings) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
  
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getBiometricIcon(BiometricCapability capability) {
    switch (capability) {
      case BiometricCapability.available:
        return Icons.fingerprint;
      case BiometricCapability.none:
        return Icons.lock;
    }
  }
  
  String _getBiometricName(BiometricCapability capability) {
    switch (capability) {
      case BiometricCapability.available:
        return 'Fingerprint';
      case BiometricCapability.none:
        return 'None Available';
    }
  }
  
  String _getBiometricDescription(BiometricCapability capability) {
    switch (capability) {
      case BiometricCapability.available:
        return 'Use your fingerprint to quickly and securely access your legal documents with hardware-level security.';
      case BiometricCapability.none:
        return 'Biometric authentication is not available on this device. You can still use password authentication.';
    }
  }
}