import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import 'document_scanner_screen.dart';
import 'dictionary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.white,
              child: Row(
                children: [
                  // App name only  
                  const Text(
                    'LegalLens',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const Spacer(),
                  // Profile icon (blue circle)
                  GestureDetector(
                    onTap: () {
                      _showProfileMenu(context);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4285F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Settings icon
                  IconButton(
                    icon: const Icon(
                      Icons.tune,
                      color: Color(0xFF757575),
                      size: 24,
                    ),
                    onPressed: () {
                      // Settings functionality
                    },
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Ask your legal question...',
                                hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFF9E9E9E),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DocumentScannerScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Quick Actions section
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quick action cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.mic_outlined,
                            title: 'Documents',
                            subtitle: 'Upload & Scan',
                            color: const Color(0xFF4285F4),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DocumentScannerScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.balance_outlined,
                            title: 'Legal Chat',
                            subtitle: 'Know Your Law',
                            color: const Color(0xFF4285F4),
                            onTap: () {
                              Navigator.pushNamed(context, '/legal-chat');
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.book_outlined,
                            title: 'Dictionary',
                            subtitle: 'Legal Terms',
                            color: const Color(0xFF4285F4),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DictionaryScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.folder_copy_outlined,
                            title: 'My Files',
                            subtitle: 'Manage Docs',
                            color: const Color(0xFF4285F4),
                            onTap: () {
                              // My files functionality
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Recent Activity section
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Recent activity items
                    _buildRecentActivityItem(
                      icon: Icons.description,
                      title: "Who's saved to sting he you wait 16sp",
                      subtitle: 'Legustular You flors',
                      time: '16oke M72AA\n9/283 M7PAA',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildRecentActivityItem(
                      icon: Icons.description,
                      title: "Woe's tardor sparing theed to por fisp",
                      subtitle: 'Secondary Srest Actions',
                      time: '16oke MedAA\n22184 M7PAA',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Show more button
                    TextButton(
                      onPressed: () {
                        // Show more functionality
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Show more...',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF4285F4),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4285F4),
          unselectedItemColor: const Color(0xFF9E9E9E),
          currentIndex: 0, // Home is selected
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              label: 'Files',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          onTap: (index) {
            // Handle bottom navigation
            switch (index) {
              case 0:
                // Already on Home
                break;
              case 1:
                // Files
                break;
              case 2:
                // Chat - Navigate to Legal Chat
                Navigator.pushNamed(context, '/legal-chat');
                break;
              case 3:
                // Learn
                break;
              case 4:
                // Profile
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4285F4),
              shape: BoxShape.circle,
            ),
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
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9E9E9E),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App Info'),
              onTap: () {
                Navigator.pop(context);
                _showAppInfo(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Provider.of<AuthProvider>(context, listen: false).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Environment: ${AppConfig.currentEnvironment}'),
            const SizedBox(height: 8),
            Text('API URL: ${AppConfig.currentApiUrl}'),
            const SizedBox(height: 8),
            const Text('Version: 1.0.0'),
          ],
        ),
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