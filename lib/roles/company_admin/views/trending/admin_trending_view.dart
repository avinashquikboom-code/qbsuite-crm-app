import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';

class AdminTrendingView extends ConsumerStatefulWidget {
  final bool isStandaloneScreen;
  final String? customerId;

  const AdminTrendingView({
    super.key,
    this.isStandaloneScreen = false,
    this.customerId,
  });

  @override
  ConsumerState<AdminTrendingView> createState() => _AdminTrendingViewState();
}

class _AdminTrendingViewState extends ConsumerState<AdminTrendingView> {
  int _selectedFilterIndex =
      0; // 0: All, 1: Viral Reels, 2: Story Ads, 3: High-ROI Ads, 4: Offers

  final List<String> _filterTabs = const [
    'All Trending',
    'Viral Reels',
    'Story Ads',
    'High-ROI Ads',
    'Offers',
  ];

  final List<Map<String, dynamic>> _stories = const [
    {
      'title': 'Viral Hook',
      'icon': '⚡',
      'color1': Color(0xFF833AB4),
      'color2': Color(0xFFFD1D1D),
      'color3': Color(0xFFFCB045),
      'views': '2.4M',
      'category': 'Reel Hook',
      'customerId': 'T001',
    },
    {
      'title': 'Gym Promo',
      'icon': '🏋️',
      'color1': Color(0xFF0284C7),
      'color2': Color(0xFF0D9488),
      'color3': Color(0xFF10B981),
      'views': '1.8M',
      'category': 'Ad Story',
      'customerId': 'T001',
    },
    {
      'title': 'Diet Tips',
      'icon': '🥗',
      'color1': Color(0xFF10B981),
      'color2': Color(0xFF059669),
      'color3': Color(0xFF047857),
      'views': '940K',
      'category': 'Reel',
      'customerId': 'T001',
    },
    {
      'title': 'Crossfit Promo',
      'icon': '🏋️',
      'color1': Color(0xFF0284C7),
      'color2': Color(0xFF0D9488),
      'color3': Color(0xFF10B981),
      'views': '1.2M',
      'category': 'Ad Story',
      'customerId': 'T002',
    },
    {
      'title': 'Chef Special',
      'icon': '🍲',
      'color1': Color(0xFFF97316),
      'color2': Color(0xFFEF4444),
      'color3': Color(0xFFDC2626),
      'views': '850K',
      'category': 'Offer Story',
      'customerId': 'T002',
    },
  ];

  final List<Map<String, dynamic>> _trendingAds = const [
    {
      'id': 'ad_1',
      'customerId': 'T001',
      'title': '90-Day Fat Loss Transformation',
      'type': 'Viral Reels',
      'badge': '🔥 TRENDING #1',
      'handle': '@carefitnessgym',
      'hook':
          'Stop doing regular cardio in 2026! Try this 15-min metabolic circuit instead ⚡',
      'audio': 'Phonk Gym Motivation • Trending Beat',
      'views': '2.8M',
      'likes': '248K',
      'shares': '54K',
      'ctr': '4.9%',
      'roas': '4.2x',
      'gradient': [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
      'accentColor': Color(0xFF6366F1),
      'icon': Remix.video_fill,
      'isReel': true,
    },
    {
      'id': 'ad_2',
      'customerId': 'T001',
      'title': 'Monsoon Membership Flash Sale (50% Off)',
      'type': 'Story Ads',
      'badge': '⚡ HIGH CONVERTING',
      'handle': '@quickboom_fitness',
      'hook':
          'First 20 Signups get 3 FREE personal training sessions! Tap to claim your slot 🎟️',
      'audio': 'Upbeat Promo Audio • Trending Sound',
      'views': '1.4M',
      'likes': '98K',
      'shares': '32K',
      'ctr': '5.4%',
      'roas': '5.1x',
      'gradient': [Color(0xFF831843), Color(0xFF9D174D), Color(0xFFBE185D)],
      'accentColor': Color(0xFFF43F5E),
      'icon': Remix.flashlight_fill,
      'isReel': false,
    },
    {
      'id': 'ad_3',
      'customerId': 'T001',
      'title': 'Cinematic Gym Equipment Walkthrough',
      'type': 'Viral Reels',
      'badge': '🎬 VIRAL REEL',
      'handle': '@carefitness_pro',
      'hook':
          'POV: You step into the most aesthetic premium workout space in the city 🚀',
      'audio': 'Cinematic Drone Beat • Studio Original',
      'views': '3.2M',
      'likes': '312K',
      'shares': '84K',
      'ctr': '3.8%',
      'roas': '3.5x',
      'gradient': [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
      'accentColor': Color(0xFF10B981),
      'icon': Remix.movie_fill,
      'isReel': true,
    },
    {
      'id': 'ad_4',
      'customerId': 'T001',
      'title': 'Client UGC Transformation Story',
      'type': 'Story Ads',
      'badge': '⭐ SOCIAL PROOF',
      'handle': '@quickboom_ugc',
      'hook':
          '"I lost 14 kgs in 4 months without starving myself" — Real member story 💬',
      'audio': 'Acoustic Inspiration • Warm Voiceover',
      'views': '920K',
      'likes': '84K',
      'shares': '19K',
      'ctr': '4.2%',
      'roas': '3.8x',
      'gradient': [Color(0xFF7C2D12), Color(0xFF9A3412), Color(0xFFC2410C)],
      'accentColor': Color(0xFFEA580C),
      'icon': Remix.chat_smile_3_fill,
      'isReel': false,
    },
    {
      'id': 'ad_5',
      'customerId': 'T001',
      'title': 'High-Intensity Calisthenics Routine',
      'type': 'High-ROI Ads',
      'badge': '📈 TOP ROAS',
      'handle': '@fitness_trend_in',
      'hook':
          'Master your first muscle-up in 3 simple progressive drills! Save this reel 📌',
      'audio': 'Hardstyle Energy Track • 210K Reels',
      'views': '1.9M',
      'likes': '164K',
      'shares': '46K',
      'ctr': '4.6%',
      'roas': '4.7x',
      'gradient': [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
      'accentColor': Color(0xFF38BDF8),
      'icon': Remix.fire_fill,
      'isReel': true,
    },
    {
      'id': 'ad_6',
      'customerId': 'T001',
      'title': 'Buy 1 Year Get 3 Months Free Offer',
      'type': 'Offers',
      'badge': '🏷️ LIMITED OFFER',
      'handle': '@carefitness_deals',
      'hook':
          'Annual gym pass deal of the season — valid only till Sunday midnight! ⏰',
      'audio': 'Countdown Hype Beat • Viral Promo',
      'views': '850K',
      'likes': '72K',
      'shares': '28K',
      'ctr': '6.1%',
      'roas': '5.8x',
      'gradient': [Color(0xFF4C1D95), Color(0xFF5B21B6), Color(0xFF6D28D9)],
      'accentColor': Color(0xFFA855F7),
      'icon': Remix.price_tag_3_fill,
      'isReel': false,
    },
    // ── CUSTOMER B (T002) Isolated Trending Ads ─────────────────────────────
    {
      'id': 'ad_t2_1',
      'customerId': 'T002',
      'title': 'Crossfit 60-Day Transformation Challenge',
      'type': 'Viral Reels',
      'badge': '🔥 TRENDING #1',
      'handle': '@abcfitness_pune',
      'hook': 'Burn 600 calories in 30 mins with this workout routine! 💪',
      'audio': 'High Energy Electronic • Trending Beat',
      'views': '1.8M',
      'likes': '142K',
      'shares': '38K',
      'ctr': '5.1%',
      'roas': '4.6x',
      'gradient': [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
      'accentColor': Color(0xFF6366F1),
      'icon': Remix.video_fill,
      'isReel': true,
    },
    {
      'id': 'ad_t2_2',
      'customerId': 'T002',
      'title': 'Weekend 40% Off Fine Dining Feast',
      'type': 'Offers',
      'badge': '🏷️ LIMITED OFFER',
      'handle': '@xyz_lounge_mumbai',
      'hook':
          'Treat yourself this weekend with 40% off table reservations! 🍽️',
      'audio': 'Jazz Lounge Groove • Original Audio',
      'views': '750K',
      'likes': '64K',
      'shares': '21K',
      'ctr': '6.4%',
      'roas': '5.9x',
      'gradient': [Color(0xFF831843), Color(0xFF9D174D), Color(0xFFBE185D)],
      'accentColor': Color(0xFFF43F5E),
      'icon': Remix.price_tag_3_fill,
      'isReel': false,
    },
  ];

  List<Map<String, dynamic>> _getFilteredAds() {
    final targetCustomer = (widget.customerId ?? 'T001').toUpperCase();
    final isCustomerB =
        targetCustomer == 'T002' || targetCustomer == 'CUSTOMER_B';
    final targetId = isCustomerB ? 'T002' : 'T001';

    final scopedAds = _trendingAds
        .where((ad) => (ad['customerId'] ?? 'T001') == targetId)
        .toList();
    if (_selectedFilterIndex == 0) return scopedAds;
    final tab = _filterTabs[_selectedFilterIndex];
    return scopedAds.where((ad) => ad['type'] == tab).toList();
  }

  List<Map<String, dynamic>> _getFilteredStories() {
    final targetCustomer = (widget.customerId ?? 'T001').toUpperCase();
    final isCustomerB =
        targetCustomer == 'T002' || targetCustomer == 'CUSTOMER_B';
    final targetId = isCustomerB ? 'T002' : 'T001';

    return _stories
        .where((s) => (s['customerId'] ?? 'T001') == targetId)
        .toList();
  }

  void _openReelDetail(BuildContext context, Map<String, dynamic> ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildReelPreviewModal(ctx, ad),
    );
  }

  void _openStoryViewer(BuildContext context, Map<String, dynamic> story) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                story['color1'] as Color,
                story['color2'] as Color,
                story['color3'] as Color,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        story['icon'] as String,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        story['title'] as String,
                        style: AppTypography.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Remix.close_line, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Remix.play_fill, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${story['views']} Instagram Story Views',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Top trending format for fitness & wellness business ads',
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Requested Story template: ${story['title']}',
                        ),
                        backgroundColor: AppColors.primaryDark,
                      ),
                    );
                  },
                  child: Text(
                    'Use This Story Template',
                    style: AppTypography.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReelPreviewModal(BuildContext context, Map<String, dynamic> ad) {
    final List<Color> gradient = ad['gradient'] as List<Color>;
    final Color accentColor = ad['accentColor'] as Color;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFFD1D1D),
                            Color(0xFFFCB045),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Remix.instagram_line,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ad['handle'] as String,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Remix.close_line, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 9:16 Mockup Frame
                  Container(
                    width: double.infinity,
                    height: 320,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Center Play Button
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Remix.play_fill,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),

                        // Top Badges
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ad['badge'] as String,
                              style: AppTypography.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Bottom Reel Info Overlay
                        Positioned(
                          bottom: 14,
                          left: 14,
                          right: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad['hook'] as String,
                                style: AppTypography.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Remix.music_2_line,
                                    color: Colors.white70,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      ad['audio'] as String,
                                      style: AppTypography.inter(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Analytics Row (Views, Likes, CTR, ROAS)
                  Row(
                    children: [
                      _buildMetricBox(
                        'Views',
                        ad['views'] as String,
                        Remix.eye_line,
                        const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricBox(
                        'Likes',
                        ad['likes'] as String,
                        Remix.heart_fill,
                        const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricBox(
                        'CTR',
                        ad['ctr'] as String,
                        Remix.cursor_line,
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricBox(
                        'ROAS',
                        ad['roas'] as String,
                        Remix.funds_line,
                        const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Remix.sparkling_fill, size: 18),
                      label: Text(
                        'Request Similar Reel For My Brand',
                        style: AppTypography.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Requested Reel Shoot based on: ${ad['title']}',
                            ),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAds = _getFilteredAds();

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Instagram-Style Stories Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'TRENDING STORIES & HOOKS',
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tap to preview',
                style: AppTypography.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 92,
            child: Builder(
              builder: (context) {
                final filteredStories = _getFilteredStories();
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredStories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final story = filteredStories[index];
                    return InkWell(
                      onTap: () => _openStoryViewer(context, story),
                      borderRadius: BorderRadius.circular(35),
                      child: Column(
                        children: [
                          // Story Circle with Instagram Gradient Ring
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  story['color1'] as Color,
                                  story['color2'] as Color,
                                  story['color3'] as Color,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      (story['color1'] as Color).withValues(
                                        alpha: 0.2,
                                      ),
                                      (story['color2'] as Color).withValues(
                                        alpha: 0.2,
                                      ),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    story['icon'] as String,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            story['title'] as String,
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 2. Filter Tabs & Time Filter
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filterTabs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tab = _filterTabs[index];
                      final isSelected = _selectedFilterIndex == index;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: AppColors.primaryDark.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              tab,
                              style: AppTypography.inter(
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'VIRAL REELS & AD CREATIVES',
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${filteredAds.length} Templates',
                style: AppTypography.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Reels & Ads Cards Grid
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredAds.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final ad = filteredAds[index];
              return _buildTrendingAdCard(context, ad);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (widget.isStandaloneScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Trending Ads & Reels',
            style: AppTypography.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: false,
          leading: const BackButton(color: AppColors.textPrimary),
        ),
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom Header for Bottom Nav Tab
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF833AB4),
                                Color(0xFFFD1D1D),
                                Color(0xFFFCB045),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Remix.fire_fill,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Trending',
                                style: AppTypography.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'ADS, REELS & STORIES',
                                style: AppTypography.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  letterSpacing: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          'Viral Library',
                          style: AppTypography.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingAdCard(BuildContext context, Map<String, dynamic> ad) {
    final List<Color> gradient = ad['gradient'] as List<Color>;
    final Color accentColor = ad['accentColor'] as Color;

    return InkWell(
      onTap: () => _openReelDetail(context, ad),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual Card Preview
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  // Play icon in center
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Remix.play_fill,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // Top Badges (Instagram badge + Views badge)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Remix.instagram_line,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    ad['handle'] as String,
                                    style: AppTypography.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ad['badge'] as String,
                            style: AppTypography.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Audio Bar on Card
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Remix.music_2_fill,
                            color: Colors.white,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ad['audio'] as String,
                              style: AppTypography.inter(
                                fontSize: 10.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body (Hook, Metrics, Request button)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad['title'] as String,
                    style: AppTypography.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad['hook'] as String,
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Remix.eye_line,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            ad['views'] as String,
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Remix.heart_line,
                            size: 12,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            ad['likes'] as String,
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${ad['ctr']} • ${ad['roas']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
