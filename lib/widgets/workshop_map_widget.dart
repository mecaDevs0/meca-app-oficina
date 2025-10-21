import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class WorkshopMapWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? workshopName;
  final String? workshopAddress;
  final bool isEditable;
  final Function(double latitude, double longitude)? onLocationChanged;

  const WorkshopMapWidget({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.workshopName,
    this.workshopAddress,
    this.isEditable = false,
    this.onLocationChanged,
  }) : super(key: key);

  @override
  State<WorkshopMapWidget> createState() => _WorkshopMapWidgetState();
}

class _WorkshopMapWidgetState extends State<WorkshopMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
        _updateMarkers();
      } else {
        // Tentar obter localização atual
        await _getCurrentLocation();
      }
    } catch (e) {
      print('Erro ao inicializar localização: $e');
      // Usar localização padrão (São Paulo)
      _selectedLocation = const LatLng(-23.5505, -46.6333);
      _updateMarkers();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Permissão de localização negada');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Permissão de localização permanentemente negada');
        return;
      }

      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _selectedLocation = LatLng(position.latitude, position.longitude);
      _updateMarkers();
    } catch (e) {
      print('Erro ao obter localização atual: $e');
      _showLocationError('Erro ao obter localização atual');
    }
  }

  void _updateMarkers() {
    if (_selectedLocation != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('workshop_location'),
            position: _selectedLocation!,
            infoWindow: InfoWindow(
              title: widget.workshopName ?? 'Localização da Oficina',
              snippet: widget.workshopAddress ?? 'Toque para ver detalhes',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        };
      });
    }
  }

  void _onMapTap(LatLng location) {
    if (widget.isEditable) {
      setState(() {
        _selectedLocation = location;
        _updateMarkers();
      });
      
      widget.onLocationChanged?.call(location.latitude, location.longitude);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _centerOnLocation() async {
    if (_mapController != null && _selectedLocation != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(_selectedLocation!),
      );
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
          ),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? const LatLng(-23.5505, -46.6333),
                zoom: 15.0,
              ),
              markers: _markers,
              onTap: _onMapTap,
              mapType: MapType.normal,
              myLocationEnabled: widget.isEditable,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
            ),
            
            // Controles customizados
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  // Botão de centralizar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _centerOnLocation,
                      icon: const Icon(
                        Icons.my_location,
                        color: Color(0xFF00C977),
                      ),
                    ),
                  ),
                  
                  if (widget.isEditable) ...[
                    const SizedBox(height: 8),
                    // Botão de localização atual
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(
                          Icons.gps_fixed,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Indicador de modo de edição
            if (widget.isEditable)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_location,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Toque para selecionar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Informações da oficina
            if (widget.workshopName != null && !widget.isEditable)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF333333),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C977).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF00C977),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.workshopName!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (widget.workshopAddress != null)
                                  Text(
                                    widget.workshopAddress!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF8B8B8B),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}








