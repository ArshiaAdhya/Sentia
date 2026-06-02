import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../home/screens/home_screen.dart';
import '../garden/screens/garden_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../shop/screens/shop_screen.dart';
import '../garden_state.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 1; // Default to Home (index 1)

  @override
  void initState() {
    super.initState();
    Future.microtask(() => GardenState().init());
  }

  // Navigate to Shop (can be triggered from home button or shortcut)
  void _navigateToShop() async {
    final shouldPlant = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
    // If the user bought a flower and tapped 'Plant Now', switch to the Garden tab
    if (shouldPlant == true) {
      setState(() {
        _currentIndex = 0; // Index 0 represents Garden canvas
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pages list
    final List<Widget> pages = [
      GardenScreen(onGoToShop: _navigateToShop),
      const HomeScreen(),
      ProfileScreen(onGoToShop: _navigateToShop),
    ];

    return Scaffold(
      extendBody:
          true, // Crucial so that page content renders behind the floating bottom bar
      body: Stack(
        children: [
          // Active page container
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),

          // Custom Floating Glassmorphic Bottom Navigation Bar
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                    color: Colors.white.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Garden / Shop Icon Tab
                        _buildNavItem(
                          index: 0,
                          icon: Icons.local_florist_outlined,
                          activeIcon: Icons.local_florist,
                          label: 'Garden',
                        ),

                        // Home / Garden Canvas Icon Tab (Centered highlight house button)
                        _buildCenteredHomeItem(),

                        // Profile Icon Tab
                        _buildNavItem(
                          index: 2,
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Standard bottom bar nav item (Garden / Profile)
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive
        ? AppColors.primaryDark
        : AppColors.textMedium.withOpacity(0.7);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: color,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Highlights center home item as a beautiful filled dark green circle with white house inside
  Widget _buildCenteredHomeItem() {
    final isActive = _currentIndex == 1;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 1;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryDark : Colors.transparent,
              shape: BoxShape.circle,
              border: isActive
                  ? null
                  : Border.all(
                      color: AppColors.primaryDark.withOpacity(0.4),
                      width: 1.5),
            ),
            child: Icon(
              Icons.home_outlined,
              color: isActive ? Colors.white : AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Home',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
