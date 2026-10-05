/*
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../ad_manager.dart';

/// Bottom banner slot (HTML `.ad-banner`). Renders the AdMob banner when one
/// loads; collapses to nothing on unsupported platforms or load failure so
/// content is never obstructed by an empty box.
class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key});

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!AdManager.adsSupported) return;
    final manager = context.read<AdManager>();
    _banner = manager.createBanner(
      onLoaded: (_) {
        if (mounted) setState(() => _loaded = true);
      },
      onFailed: (_, _) {
        if (mounted) {
          setState(() {
            _loaded = false;
            _banner = null;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_loaded || banner == null) return const SizedBox.shrink();
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      height: banner.size.height.toDouble(),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: SizedBox(
            width: banner.size.width.toDouble(),
            height: banner.size.height.toDouble(),
            child: AdWidget(ad: banner),
          ),
        ),
      ),
    );
  }
}
*/
