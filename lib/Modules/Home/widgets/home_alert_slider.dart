import 'package:Gixa/Modules/notification/controller/notification_controller.dart';
import 'package:Gixa/Modules/notification/veiw/alerts_page.dart';
import 'package:Gixa/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Gixa/services/auth_guard.dart';
import 'dart:async';

class HomeAlertSlider extends StatefulWidget {
  HomeAlertSlider({super.key});

  @override
  State<HomeAlertSlider> createState() => _HomeAlertSliderState();
}

class _HomeAlertSliderState extends State<HomeAlertSlider> {
  late final NotificationController controller =
      Get.isRegistered<NotificationController>()
      ? Get.find<NotificationController>()
      : Get.put(NotificationController());

  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: .92);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (controller.notifications.isEmpty && !controller.isLoading.value) {
        controller.fetchNotifications();
      }

      _startAutoPlay();
    });
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      final notifications = controller.notifications.take(5).toList();
      if (notifications.length <= 1 || !_pageController.hasClients) {
        return;
      }

      final nextIndex = (_currentIndex + 1) % notifications.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      _currentIndex = nextIndex;
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sliderGradient = LinearGradient(
      colors: [Color(0xFF3A8DFF), Color(0xFF7B3FE4), Color(0xFFFF5B7C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Obx(() {
      final notifications = controller.notifications.take(5).toList();

      if (notifications.isEmpty) {
        return const SizedBox();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          /// 🔥 HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: kHomeAccentColor,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      "counselling Notifications",

                      style: GoogleFonts.inter(
                        fontSize: 12,

                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                TextButton(
                  onPressed: () {
                    AuthGuard.checkAccess(
                      onAllowed: () {
                        Get.to(() => const AlertsPage());
                      },
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "See All",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: kHomeAccentColor,
                        ),
                      ),
                      if (controller.hasNotifications) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: sliderGradient,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5B7C).withOpacity(.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            controller.notificationBadgeLabel,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// 🔥 SLIDER
          SizedBox(
            height: 145,

            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                _currentIndex = index;
              },

              itemCount: notifications.length,

              itemBuilder: (context, index) {
                final item = notifications[index];

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (item.link.isEmpty) {
                      return;
                    }

                    final uri = Uri.parse(item.link);

                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },

                  child: Container(
                    margin: const EdgeInsets.only(left: 16, right: 6),

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: sliderGradient,

                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5B7C).withOpacity(.30),

                          blurRadius: 18,

                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        /// 🔔 SOURCE
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),

                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.18),

                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: const Icon(
                                Icons.notifications_active,

                                color: Colors.white,

                                size: 18,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                item.source.isNotEmpty ? item.source : 'Admin',

                                maxLines: 1,

                                overflow: TextOverflow.ellipsis,

                                style: GoogleFonts.inter(
                                  color: Colors.white,

                                  fontSize: 12,

                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        /// 🔥 TITLE
                        Text(
                          item.title.isNotEmpty ? item.title : item.bodyText,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: GoogleFonts.inter(
                            color: Colors.white,

                            fontSize: 13,

                            fontWeight: FontWeight.w700,

                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // /// 🔗 OPEN
                        // Row(
                        //   children: [
                        //     Text(
                        //       "Open Notification",

                        //       style: GoogleFonts.inter(
                        //         color: Colors.white,

                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //     ),

                        //     const SizedBox(width: 4),

                        //     const Icon(
                        //       Icons.arrow_forward_rounded,

                        //       color: Colors.white,

                        //       size: 18,
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
