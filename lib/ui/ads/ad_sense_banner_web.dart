import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'ad_sense_config.dart';

class AdSenseBanner extends StatefulWidget {
  final double height;

  const AdSenseBanner({super.key, this.height = 90});

  @override
  State<AdSenseBanner> createState() => _AdSenseBannerState();
}

class _AdSenseBannerState extends State<AdSenseBanner> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'adsense-game-top-banner-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (_) => _buildAdElement(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AdSenseConfig.isConfigured) {
      return _AdSensePreview(height: widget.height);
    }
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }

  web.HTMLElement _buildAdElement() {
    final container = web.document.createElement('div') as web.HTMLDivElement
      ..style.width = '100%'
      ..style.height = '${widget.height}px'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.overflow = 'hidden';

    final ad = web.document.createElement('ins') as web.HTMLElement
      ..className = 'adsbygoogle'
      ..style.display = 'block'
      ..style.width = '100%'
      ..style.height = '${widget.height}px'
      ..setAttribute('data-ad-client', AdSenseConfig.publisherId)
      ..setAttribute('data-ad-slot', AdSenseConfig.gameTopBannerSlot)
      ..setAttribute('data-ad-format', AdSenseConfig.gameTopBannerFormat)
      ..setAttribute('data-full-width-responsive', 'true');

    final loader = web.document.createElement('script') as web.HTMLScriptElement
      ..text = '(adsbygoogle = window.adsbygoogle || []).push({});';

    container
      ..appendChild(ad)
      ..appendChild(loader);
    return container;
  }
}

class _AdSensePreview extends StatelessWidget {
  final double height;

  const _AdSensePreview({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xffefe7da),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Text(
        'AdSense banner preview',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
