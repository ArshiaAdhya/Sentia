import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../garden_state.dart';

class GardenScreen extends StatefulWidget {
  final VoidCallback onGoToShop;

  const GardenScreen({
    super.key,
    required this.onGoToShop,
  });

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  // Map flower itemId/displayName to corresponding asset paths
  String _getFlowerAsset(PlantedFlowerLocal flower) {
    final key = (flower.displayName ?? flower.itemId).toLowerCase();
    switch (key) {
      case 'rose':
      case 'roses':
      case '5bd47c16-28bb-4247-88f7-1b82d71cb554':
        return 'assets/images/rose.png';
      case 'jasmine':
      case 'lavender':
      case 'f2aaa580-c4ed-4af8-b865-3b318b2d4b11':
        return 'assets/images/jasmine.png';
      case 'sunflower':
      case 'sunflowers':
      case '032b9b57-0d68-45d3-be58-910785348ca6':
        return 'assets/images/sunflower.png';
      case 'tulip':
      case '81d61616-707c-4856-81e2-f46765b0d76a':
        return 'assets/images/tulip.png';
      default:
        return 'assets/images/rose.png';
    }
  }

  // Handle tap on the garden canvas to plant a queued flower
  Future<void> _handleGardenTap(
    BuildContext context,
    TapUpDetails details,
    GardenState state,
  ) async {
    if (state.selectedFlowerToPlant == null) return;

    final localPosition = details.localPosition;

    // Plant the flower!
    final planted =
        await state.plantQueuedFlower(localPosition.dx, localPosition.dy);
    if (!context.mounted) return;

    // Show a micro-feedback SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          planted
              ? 'Flower planted successfully! 🌸🌱'
              : 'Could not plant right now. Please try again.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: GardenState(),
        builder: (context, child) {
          final state = GardenState();
          final isPlantingMode = state.selectedFlowerToPlant != null;

          return Stack(
            children: [
              // Full-Screen Scenic Zen Garden Background
              Positioned.fill(
                child: GestureDetector(
                  onTapUp: (details) =>
                      _handleGardenTap(context, details, state),
                  child: Image.asset(
                    'assets/images/garden_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.creamBackground,
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            size: 80, color: AppColors.primaryLight),
                      ),
                    ),
                  ),
                ),
              ),

              // Planted Flowers Canvas Stack
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true, // Let gestures pass to background detector
                  child: Stack(
                    children: state.plantedFlowers.map((flower) {
                      return Positioned(
                        left: flower.posX -
                            28, // Offset so center of image lines up with tap point
                        top: flower.posY - 28, // Center image on tap point
                        child: AnimatedFlowerNode(
                          assetPath: _getFlowerAsset(flower),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Top Stats Floating Bar overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Seeds Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: AppStyles.glassPillDeco,
                          child: Row(
                            children: [
                              const Text('🌱', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                '${state.seeds}',
                                style: AppStyles.badgeText,
                              ),
                            ],
                          ),
                        ),

                        // Title
                        Text(
                          'Sentia AI',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),

                        // Streak Badge
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
                ),
              ),

              // Interactive Overlay Banner when in Planting Mode
              if (isPlantingMode)
                Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🌷 ', style: TextStyle(fontSize: 18)),
                        Expanded(
                          child: Text(
                            'Tap anywhere on the grass or path to plant your ${state.selectedFlowerDisplayName!.toUpperCase()}!',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => state.selectFlowerToPlant(null),
                          child: const Icon(Icons.cancel,
                              color: Colors.white70, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom floating Buy Button (when not planting)
              if (!isPlantingMode)
                Positioned(
                  bottom: 120, // Floating above the bottom nav bar
                  left: 60,
                  right: 60,
                  child: ElevatedButton(
                    onPressed: widget.onGoToShop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark.withOpacity(0.85),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🌸 ', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          'Buy Flowers',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Stateful Widget to execute a beautiful pop/scale-up enter animation for a flower
class AnimatedFlowerNode extends StatefulWidget {
  final String assetPath;

  const AnimatedFlowerNode({
    super.key,
    required this.assetPath,
  });

  @override
  State<AnimatedFlowerNode> createState() => _AnimatedFlowerNodeState();
}

class _AnimatedFlowerNodeState extends State<AnimatedFlowerNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Image.asset(
        widget.assetPath,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Text(
          '🌸',
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}
