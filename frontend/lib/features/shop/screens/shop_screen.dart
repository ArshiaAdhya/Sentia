import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../garden_state.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Future<void> _purchaseFlower(BuildContext context, GardenState state,
      String id, String displayName, int cost) async {
    if (state.seeds < cost) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Need More Seeds! 🐧🌱',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          content: Text(
            'You need $cost seeds to buy a $displayName, but you only have ${state.seeds} seeds.\n\nTip: Write in your diary to earn +20 seeds instantly!',
            style:
                GoogleFonts.outfit(color: AppColors.textMedium, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Okay',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Process purchase!
    final bool success = await state.buyFlower(id, cost);
    if (success) {
      if (!context.mounted) return;
      // Show elegant success animation dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F7F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.primaryDark, size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'Purchased $displayName! 🎉',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'You spent $cost seeds. Now, let\'s place it in your beautiful garden!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 14, color: AppColors.textMedium),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close success dialog
                      Navigator.of(context)
                          .pop(true); // Return to Garden tab signaling purchase
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      'Plant Now',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFE2EBE2), // Soft sage outline background color
      body: SafeArea(
        child: AnimatedBuilder(
          animation: GardenState(),
          builder: (context, child) {
            final state = GardenState();
            return Column(
              children: [
                // Top Custom Header (Floating Pill Style)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button & Seeds Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: AppStyles.glassPillDeco,
                              child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: AppColors.textDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: AppStyles.glassPillDeco,
                            child: Row(
                              children: [
                                const Text('🌱',
                                    style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  '${state.seeds}',
                                  style: AppStyles.badgeText,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Title
                      Text(
                        'Sentia AI',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),

                      // Streak & Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: AppStyles.glassPillDeco,
                        child: Row(
                          children: [
                            Text(
                              '${state.streak}',
                              style: AppStyles.badgeText,
                            ),
                            const SizedBox(width: 6),
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Shop Card (Glassmorphic Outer Box)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                        left: 16, right: 16, bottom: 16, top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.glassWhite,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Section Title
                          Text(
                            'Garden Shop',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Garden Floating Island Asset illustration
                          Container(
                            height: 120,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: Image.asset(
                              'assets/images/garden_island.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryLight.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image_outlined,
                                      size: 40, color: AppColors.primaryDark),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Flower catalog list
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildShopCard(
                                  context: context,
                                  state: state,
                                  id: 'rose',
                                  name: 'Roses',
                                  description: 'Beautiful red roses',
                                  cost: 20,
                                  imagePath: 'assets/images/rose.png',
                                ),
                                const SizedBox(height: 12),
                                _buildShopCard(
                                  context: context,
                                  state: state,
                                  id: 'lavender',
                                  name: 'Lavender',
                                  description: 'Calming purple blossoms',
                                  cost: 15,
                                  imagePath: 'assets/images/jasmine.png',
                                ),
                                const SizedBox(height: 12),
                                _buildShopCard(
                                  context: context,
                                  state: state,
                                  id: 'sunflower',
                                  name: 'Sunflower',
                                  description: 'Tall sunny flowers',
                                  cost: 10,
                                  imagePath: 'assets/images/sunflower.png',
                                ),
                                const SizedBox(height: 12),
                                _buildShopCard(
                                  context: context,
                                  state: state,
                                  id: 'tulip',
                                  name: 'Tulip',
                                  description: 'Elegant spring bloom',
                                  cost: 25,
                                  imagePath: 'assets/images/tulip.png',
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildShopCard({
    required BuildContext context,
    required GardenState state,
    required String id,
    required String name,
    required String description,
    required int cost,
    required String imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5ED), // Cream card inside shop
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Flower Thumbnail
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_florist,
                color: AppColors.primaryDark,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Flower description text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.explore_outlined,
                        color: AppColors.primaryDark, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Seeds required: $cost',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Buy Button
          ElevatedButton(
            onPressed: () => _purchaseFlower(context, state, id, name, cost),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMedium,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Buy',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
