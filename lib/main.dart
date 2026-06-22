import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/config_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/location_service.dart';
import 'features/map/controllers/mapp_map_controller.dart';
import 'features/navigation/controllers/navigation_session_controller.dart';
import 'features/navigation/services/mapbox_directions_service.dart';
import 'features/saved_places/services/saved_places_service.dart';
import 'features/search/services/mapbox_geocoding_service.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'features/trips/services/trip_history_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env').catchError((_) async {
    // .env is optional because production builds can use --dart-define.
  });

  final storage = LocalStorageService();
  await storage.init();

  final config = ConfigService(storage);
  await config.init();

  final token = config.mapboxAccessToken;
  if (token.isNotEmpty) {
    MapboxOptions.setAccessToken(token);
  }

  final settingsController = SettingsController(storage, config);
  await settingsController.load();

  final savedPlacesService = SavedPlacesService(storage);
  await savedPlacesService.load();

  final tripHistoryService = TripHistoryService(storage);
  await tripHistoryService.load();

  final connectivityService = ConnectivityService();
  await connectivityService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: storage),
        Provider.value(value: config),
        ChangeNotifierProvider.value(value: settingsController),
        ChangeNotifierProvider.value(value: connectivityService),
        ChangeNotifierProvider(create: (_) => LocationService()..start()),
        ChangeNotifierProvider(create: (_) => MappMapController()),
        ChangeNotifierProvider(create: (_) => NavigationSessionController()),
        ChangeNotifierProvider.value(value: savedPlacesService),
        ChangeNotifierProvider.value(value: tripHistoryService),
        Provider(create: (context) => MapboxGeocodingService(config, storage)),
        Provider(create: (context) => MapboxDirectionsService(config)),
      ],
      child: const MappARApp(),
    ),
  );
}
