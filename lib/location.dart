import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPicker extends StatefulWidget {
  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  String _currentAddress = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPosition;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 14), // Zoom level 14
      );

      await _getAddressFromLatLng(newPosition);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  Future<void> _searchCity(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        LatLng newPosition = LatLng(location.latitude, location.longitude);

        setState(() {
          _currentPosition = newPosition;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 12), // Zoom in properly
        );

        await _getAddressFromLatLng(newPosition);
      } else {
        print("No locations found");
      }
    } catch (e) {
      print('Error searching city: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('City not found! Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? LatLng(0, 0),
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (_mapController == null) {
                _mapController = controller;
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (LatLng position) async {
              setState(() {
                _currentPosition = position;
              });
              await _getAddressFromLatLng(position);
            },
          ),

          // Search bar at the top
       Positioned(
  top: 40,
  left: 10,
  right: 10,
  child: TextField(
    controller: _searchController,
    decoration: InputDecoration(
      hintText: "Search for a city...",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Rounded borders
        borderSide: BorderSide.none, // No border
      ),
      filled: true,
      fillColor: Colors.white, // Keep background white for readability
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Adjust padding
      suffixIcon: IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          if (_searchController.text.isNotEmpty) {
            _searchCity(_searchController.text);
          }
        },
      ),
    ),
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        _searchCity(value);
      }
    },
  ),
),


          // Address display card
          Positioned(
            top: 110,
            left: 10,
            right: 10,
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _currentAddress.isEmpty
                      ? 'Select a location'
                      : _currentAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Confirm location button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                if (_currentPosition != null) {
                  Navigator.pop(context, {
                    'address': _currentAddress,
                    'lat': _currentPosition!.latitude,
                    'lng': _currentPosition!.longitude,
                  });
                }
              },
              child: const Icon(Icons.location_on),
            ),
          ),
        ],
      ),
    );
  }
}
