import 'package:flutter/material.dart';

import '../../../core/constants/map_styles.dart';
import '../../settings/controllers/settings_controller.dart';
import 'glass_panel.dart';

class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
    required this.onCompass,
    required this.settings,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;
  final VoidCallback onCompass;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(6),
      borderRadius: 22,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlButton(icon: Icons.add, onTap: onZoomIn, tooltip: 'Zoom in'),
          _ControlButton(icon: Icons.remove, onTap: onZoomOut, tooltip: 'Zoom out'),
          _ControlButton(icon: Icons.explore_outlined, onTap: onCompass, tooltip: 'Compass'),
          _ControlButton(icon: Icons.my_location, onTap: onRecenter, tooltip: 'Re-center'),
          PopupMenuButton<MapStyleOption>(
            tooltip: 'Map style',
            icon: const Icon(Icons.layers_outlined),
            onSelected: settings.setMapStyle,
            itemBuilder: (context) => MapStyles.values
                .map((style) => PopupMenuItem(value: style, child: Text(style.label)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onTap, icon: Icon(icon), tooltip: tooltip);
  }
}
