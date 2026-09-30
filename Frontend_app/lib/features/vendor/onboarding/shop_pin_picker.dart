import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ShopPinPicker extends StatefulWidget {
  const ShopPinPicker({super.key, this.initial});
  final LatLng? initial;
  @override
  State<ShopPinPicker> createState() => _ShopPinPickerState();
}

class _ShopPinPickerState extends State<ShopPinPicker> {
  LatLng? _pin;
  @override
  void initState() {
    super.initState();
    _pin = widget.initial;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose your shop location')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Zoom to your street and tap the exact shop entrance to place the pin.',
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: widget.initial ?? const LatLng(22.5, 79),
              initialZoom: widget.initial == null ? 4 : 17,
              onTap: (_, point) => setState(() => _pin = point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.carwash.carwash',
              ),
              if (_pin != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pin!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 46,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(6),
          child: Text(
            '© OpenStreetMap contributors · © CARTO',
            style: TextStyle(fontSize: 11),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _pin == null
                      ? 'Tap the map to select a location'
                      : '${_pin!.latitude.toStringAsFixed(6)}, ${_pin!.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _pin == null
                      ? null
                      : () => Navigator.of(context).pop(_pin),
                  child: const Text('Confirm shop location'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
