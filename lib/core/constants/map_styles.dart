enum MapStyleKey { streets, satellite, outdoors, dark, light }

class MapStyleOption {
  const MapStyleOption({required this.key, required this.label, required this.uri});

  final MapStyleKey key;
  final String label;
  final String uri;
}

class MapStyles {
  const MapStyles._();

  static const streets = MapStyleOption(
    key: MapStyleKey.streets,
    label: 'Streets',
    uri: 'mapbox://styles/mapbox/streets-v12',
  );

  static const satellite = MapStyleOption(
    key: MapStyleKey.satellite,
    label: 'Satellite',
    uri: 'mapbox://styles/mapbox/satellite-streets-v12',
  );

  static const outdoors = MapStyleOption(
    key: MapStyleKey.outdoors,
    label: 'Outdoors',
    uri: 'mapbox://styles/mapbox/outdoors-v12',
  );

  static const dark = MapStyleOption(
    key: MapStyleKey.dark,
    label: 'Dark',
    uri: 'mapbox://styles/mapbox/dark-v11',
  );

  static const light = MapStyleOption(
    key: MapStyleKey.light,
    label: 'Light',
    uri: 'mapbox://styles/mapbox/light-v11',
  );

  static const values = [streets, satellite, outdoors, dark, light];

  static MapStyleOption byKey(String key) {
    return values.firstWhere(
      (style) => style.key.name == key,
      orElse: () => streets,
    );
  }
}
