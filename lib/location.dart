import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationPicker extends StatefulWidget {
  final LatLng? initialPosition;
  const LocationPicker({Key? key, this.initialPosition}) : super(key: key);

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  String _currentAddress = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _isLoadingSuggestions = false;
  Timer? _debounce;

  // Get your API key from platform-specific implementations
  static const String _googleApiKey = 'AIzaSyD7yN8OYOWDyirfXc4OkVKJ3G2pF-y7-wo';

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _currentPosition = widget.initialPosition;
      _getAddressFromLatLng(_currentPosition!);
    } else {
      _checkLocationPermission();
    }
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
        CameraUpdate.newLatLngZoom(newPosition, 14),
      );
      await _getAddressFromLatLng(newPosition);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${position.latitude},${position.longitude}'
        '&key=$_googleApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          setState(() {
            _currentAddress = data['results'][0]['formatted_address'];
          });
        }
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }
Future<void> _searchPlaces(String query) async {
  if (query.isEmpty) {
    setState(() {
      _suggestions = [];
      _isLoadingSuggestions = false;
    });
    return;
  }

  setState(() {
    _isLoadingSuggestions = true;
  });

  try {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$query'
      '&key=$_googleApiKey' // Removed '&components=country:in'
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List;
        await _fetchPlaceDetails(predictions);
      } else {
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    }
  } catch (e) {
    print('Error searching places: $e');
    setState(() {
      _suggestions = [];
      _isLoadingSuggestions = false;
    });
  }
}

  Future<void> _fetchPlaceDetails(List predictions) async {
    List<Map<String, dynamic>> newSuggestions = [];

    for (var prediction in predictions.take(5)) {
      try {
        final detailUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=${prediction['place_id']}'
          '&fields=name,formatted_address,geometry'
          '&key=$_googleApiKey',
        );

        final detailResponse = await http.get(detailUrl);
        if (detailResponse.statusCode == 200) {
          final detailData = json.decode(detailResponse.body);
          if (detailData['status'] == 'OK') {
            final result = detailData['result'];
            newSuggestions.add({
              'name': result['name'],
              'address': result['formatted_address'],
              'lat': result['geometry']['location']['lat'],
              'lng': result['geometry']['location']['lng'],
            });
          }
        }
      } catch (e) {
        print('Error fetching place details: $e');
      }
    }

    setState(() {
      _suggestions = newSuggestions;
      _isLoadingSuggestions = false;
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    setState(() {
      _isSearching = value.isNotEmpty;
    });

    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (value.isNotEmpty) {
        _searchPlaces(value);
      } else {
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.white,

      appBar: AppBar(
       
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.black87),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
  target: widget.initialPosition ?? _currentPosition ?? const LatLng(20.5937, 78.9629),
  zoom: 14,
),
markers: _currentPosition != null
    ? {
        Marker(
          markerId: const MarkerId('selected-location'),
          position: _currentPosition!,
        ),
      }
    : {},


            onMapCreated: (GoogleMapController controller) {
  _mapController = controller;
  if (widget.initialPosition != null) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(widget.initialPosition!, 14),
    );
  }
},

            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onTap: (LatLng position) async {
              setState(() {
                _currentPosition = position;
                _isSearching = false;
              });
              await _getAddressFromLatLng(position);
            },
          ),
          Positioned(
            
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
             shape: const RoundedRectangleBorder(
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(5),
    bottomLeft: Radius.circular(5),
  ),
),

              child: Column(
                children: [
                  Row(
                    children: [
                    Container(
  decoration: BoxDecoration(
    color:Colors.white, // Background color
    // shape: BoxShape.square, // or use BorderRadius if you want a rounded square
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: IconButton(
    icon: const Icon(Icons.search, color: Colors.grey),
    onPressed: () {
      if (_searchController.text.isNotEmpty) {
        _searchPlaces(_searchController.text);
      }
    },
  ),
),

                      Expanded(
                        child: TextField(
                          controller: _searchController,
                         decoration: InputDecoration(
  hintText: "Search for a place...",
  filled: true,
  fillColor: Colors.white, // background color
  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
  
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(5),
    borderSide: BorderSide.none,
  ),
  
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(5),
    borderSide: BorderSide.none, // No border when not focused
  ),
  
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(0),
    borderSide: BorderSide(
      color: Colors.white, // Change to your theme color
      width: 1,
    ),
  ),
),

                          onChanged: _onSearchChanged,
                          onTap: () {
                            if (_searchController.text.isNotEmpty) {
                              setState(() {
                                _isSearching = true;
                              });
                            }
                          },
                        ),
                      ),
                   if (_isSearching)
 Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: const BorderRadius.only(
      topRight: Radius.circular(5),
      bottomRight: Radius.circular(5),
    ),
    // Optional boxShadow
    // boxShadow: [
    //   BoxShadow(
    //     color: Colors.black.withOpacity(0.1),
    //     blurRadius: 4,
    //     offset: Offset(0, 2),
    //   ),
    // ],
  ),
  child: IconButton(
    icon: const Icon(Icons.close, color: Colors.grey),
    onPressed: () {
      setState(() {
        _searchController.clear();
        _suggestions = [];
        _isSearching = false;
        _isLoadingSuggestions = false;
      });
    },
  ),
)


                    ],
                  ),
                  if (_isSearching && _isLoadingSuggestions)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
          if (_isSearching && _suggestions.isNotEmpty)
            Positioned(
              top: 70,
              left: 10,
              right: 10,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.blue),
                      title: Text(
                        _suggestions[index]['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_suggestions[index]['address']),
                      onTap: () {
                        _searchController.text = _suggestions[index]['name'];
                        setState(() {
                          _currentPosition = LatLng(
                            _suggestions[index]['lat'],
                            _suggestions[index]['lng'],
                          );
                          _currentAddress = _suggestions[index]['address'];
                          _suggestions = [];
                          _isSearching = false;
                        });
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(_currentPosition!, 15),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPosition != null) {
                  Navigator.pop(context, {
                    'address': _currentAddress,
                    'lat': _currentPosition!.latitude,
                    'lng': _currentPosition!.longitude,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(255, 130, 16, 1),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  
                ),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}