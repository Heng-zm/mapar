import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/geo_point.dart';
import '../../../core/utils/formatters.dart';
import '../../settings/controllers/settings_controller.dart';
import '../models/place_result.dart';
import '../services/mapbox_geocoding_service.dart';

class PlaceSearchSheet extends StatefulWidget {
  const PlaceSearchSheet({super.key, required this.proximity, required this.onSelected});

  final GeoPoint? proximity;
  final ValueChanged<PlaceResult> onSelected;

  @override
  State<PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<PlaceSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<PlaceResult> _results = [];
  List<PlaceResult> _recent = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecent());
  }

  Future<void> _loadRecent() async {
    final recent = await context.read<MapboxGeocodingService>().recentSearches();
    if (mounted) setState(() => _recent = recent);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await context.read<MapboxGeocodingService>().search(query, proximity: widget.proximity);
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(PlaceResult place) async {
    await context.read<MapboxGeocodingService>().saveRecentSearch(place);
    widget.onSelected(place);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final shown = _controller.text.trim().isEmpty ? _recent : _results;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search places, addresses, cafés...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: shown.isEmpty && !_loading
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _controller.text.trim().isEmpty ? 'No recent searches yet.' : 'No places found.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = shown[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Icon(_controller.text.trim().isEmpty ? Icons.history : Icons.place_outlined),
                          ),
                          title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(place.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: place.distanceMeters == null
                              ? null
                              : Text(Formatters.distance(place.distanceMeters!, settings.distanceUnit)),
                          onTap: () => _select(place),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
