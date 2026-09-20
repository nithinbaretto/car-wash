import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/user_location.dart';
import '../../../core/services/app_session.dart';
import '../../../core/services/location_catalog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../customer_shell.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.changing = false});

  static const route = '/location';

  final bool changing;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  late LatLng _center;
  String _label = 'Bengaluru';
  String _detail = 'Search or move the map to set your area';
  bool _fromGps = false;
  bool _locating = false;
  bool _searching = false;
  bool _seeded = false;
  String? _error;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    final city = LocationCatalog.bengaluru;
    _center = LatLng(city.latitude, city.longitude);
    _searchFocus.addListener(() {
      setState(() => _searching = _searchFocus.hasFocus || _search.text.isNotEmpty);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final existing = SessionScope.of(context).location;
    if (existing == null) return;
    _center = LatLng(existing.latitude, existing.longitude);
    _label = existing.label;
    _detail = existing.detail;
    _fromGps = existing.fromGps;
  }

  @override
  void dispose() {
    _settle?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _map.dispose();
    super.dispose();
  }

  void _applyPin(LatLng point, {bool fromGps = false, PlacePin? place}) {
    final described = place == null
        ? LocationCatalog.describe(point.latitude, point.longitude)
        : (label: place.title, detail: place.subtitle);
    setState(() {
      _center = point;
      _label = fromGps && place == null ? 'Current location' : described.label;
      _detail = described.detail;
      _fromGps = fromGps;
      _error = null;
    });
  }

  void _scheduleResolve(LatLng point) {
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      _applyPin(point);
    });
  }

  Future<void> _jumpTo(LatLng point, {bool fromGps = false, PlacePin? place}) async {
    _applyPin(point, fromGps: fromGps, place: place);
    _map.move(point, fromGps ? 16.2 : 15.4);
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
      _searching = false;
    });
    _searchFocus.unfocus();

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw 'Turn on location services, or search for an area.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission is off. Search and drop a pin instead.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      await _jumpTo(
        LatLng(position.latitude, position.longitude),
        fromGps: true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is String
            ? error
            : 'Could not read GPS. Search or move the pin.';
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _pickSuggestion(PlacePin place) {
    _search
      ..text = place.title
      ..selection = TextSelection.collapsed(offset: place.title.length);
    _searchFocus.unfocus();
    setState(() => _searching = false);
    _jumpTo(
      LatLng(place.latitude, place.longitude),
      place: place,
    );
  }

  void _confirm() {
    SessionScope.of(context).setLocation(
      UserLocation(
        latitude: _center.latitude,
        longitude: _center.longitude,
        label: _label,
        detail: _detail,
        fromGps: _fromGps,
      ),
    );
    if (widget.changing) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      CustomerShell.route,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = LocationCatalog.search(_search.text);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final popular = LocationCatalog.areas.take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE7EEF4),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 14.8,
                      minZoom: 4,
                      maxZoom: 19,
                      backgroundColor: const Color(0xFFE7EEF4),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onPositionChanged: (camera, hasGesture) {
                        if (!hasGesture) return;
                        _scheduleResolve(camera.center);
                      },
                      onTap: (_, _) => _searchFocus.unfocus(),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.carwash.carwash',
                      ),
                    ],
                  ),
                ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x660C3D73), Color(0x000C3D73)],
                        stops: [0, 0.28],
                      ),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 36),
                      child: _MapPin(),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Column(
                      children: [
                        _SearchBar(
                          controller: _search,
                          focusNode: _searchFocus,
                          showBack: widget.changing,
                          onBack: () => Navigator.of(context).maybePop(),
                          onChanged: () => setState(() {
                            _searching = true;
                            _error = null;
                          }),
                          onClear: () {
                            _search.clear();
                            setState(() => _searching = false);
                            _searchFocus.unfocus();
                          },
                        ),
                        if (_searching) ...[
                          const SizedBox(height: 10),
                          _SuggestionSheet(
                            query: _search.text,
                            suggestions: suggestions,
                            onPick: _pickSuggestion,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: _ConfirmSheet(
              changing: widget.changing,
              label: _label,
              detail: _detail,
              fromGps: _fromGps,
              locating: _locating,
              error: _error,
              popular: _searching ? const [] : popular,
              onPopular: _pickSuggestion,
              onUseCurrent: _useCurrentLocation,
              onConfirm: _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.showBack,
    required this.onBack,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330C3D73),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          if (showBack)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: AppColors.ink,
            )
          else
            const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(Icons.search_rounded, color: AppColors.primary),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (_) => onChanged(),
              textInputAction: TextInputAction.search,
              style: AppText.ui(size: 15, weight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search area or locality',
                hintStyle: AppText.ui(size: 15, color: AppColors.mutedLight),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.muted,
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SuggestionSheet extends StatelessWidget {
  const _SuggestionSheet({
    required this.query,
    required this.suggestions,
    required this.onPick,
  });

  final String query;
  final List<PlacePin> suggestions;
  final ValueChanged<PlacePin> onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220C3D73),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: suggestions.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No match for “$query”. Try Koramangala or HSR.',
                  style: AppText.ui(size: 14, color: AppColors.muted),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: suggestions.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 64,
                  color: AppColors.border,
                ),
                itemBuilder: (context, index) {
                  final place = suggestions[index];
                  return InkWell(
                    onTap: () => onPick(place),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.title,
                                  style: AppText.ui(
                                    size: 15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  place.subtitle,
                                  style: AppText.ui(
                                    size: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.north_west_rounded,
                            size: 16,
                            color: AppColors.mutedLight,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.changing,
    required this.label,
    required this.detail,
    required this.fromGps,
    required this.locating,
    required this.error,
    required this.popular,
    required this.onPopular,
    required this.onUseCurrent,
    required this.onConfirm,
  });

  final bool changing;
  final String label;
  final String detail;
  final bool fromGps;
  final bool locating;
  final String? error;
  final List<PlacePin> popular;
  final ValueChanged<PlacePin> onPopular;
  final VoidCallback onUseCurrent;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x330C3D73),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                changing ? 'UPDATE AREA' : 'WASHING NEAR',
                style: AppText.ui(
                  size: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      fromGps
                          ? Icons.my_location_rounded
                          : Icons.place_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppText.display(size: 24, height: 1.1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          style: AppText.ui(size: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: AppText.ui(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.heart,
                  ),
                ),
              ],
              if (popular.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: popular.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final place = popular[index];
                      return GestureDetector(
                        onTap: () => onPopular(place),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F8FC),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            place.title,
                            style: AppText.ui(
                              size: 12,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 14),
              GestureDetector(
                onTap: locating ? null : onUseCurrent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8FC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.gps_fixed_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          locating ? 'Finding your spot…' : 'Use current location',
                          style: AppText.ui(
                            size: 14,
                            weight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.mutedLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppPrimaryButton(
                label: changing ? 'Update location' : 'Confirm & continue',
                trailing: const Icon(Icons.arrow_forward_rounded),
                onPressed: onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryDeep,
            borderRadius: BorderRadius.circular(99),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330C3D73),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'Move map to adjust',
            style: AppText.ui(
              size: 11,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 56,
          height: 72,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeep.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Icon(
                Icons.location_on_rounded,
                size: 58,
                color: AppColors.primary,
                shadows: [
                  Shadow(
                    color: Color(0x400C3D73),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
