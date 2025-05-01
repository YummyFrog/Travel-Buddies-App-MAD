import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'itinerary_screen.dart';
import 'match_screen.dart';

const String apiKey = 'AIzaSyDfQhsjL8tkYd5XAM4JQbE8o3RYSc3wCT0';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(37.7749, -122.4194); // Default: SF
  late GooglePlace googlePlace;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(apiKey);
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _initialPosition = LatLng(position.latitude, position.longitude);
    _moveCamera(_initialPosition);
    _fetchNearbyPlaces(_initialPosition);
  }

  Future<void> _moveCamera(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(position, 14));
  }

  void _fetchNearbyPlaces(LatLng location) async {
    final result = await googlePlace.search.getNearBySearch(
      Location(lat: location.latitude, lng: location.longitude),
      1500,
      type: "tourist_attraction",
    );

    if (result != null && result.results != null) {
      setState(() {
        _markers.clear();
        for (var place in result.results!) {
          if (place.geometry?.location != null && place.name != null) {
            final lat = place.geometry!.location!.lat!;
            final lng = place.geometry!.location!.lng!;
            _markers.add(
              Marker(
                markerId: MarkerId(place.placeId ?? place.name!),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(title: place.name),
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _searchDestination() async {
    final query = _destinationController.text.trim();
    if (query.isEmpty) return;

    List<geo.Location> locations = await geo.locationFromAddress(query);
    if (locations.isNotEmpty) {
      final LatLng dest = LatLng(locations[0].latitude, locations[0].longitude);
      _moveCamera(dest);
      _fetchNearbyPlaces(dest);
    }
  }

  Widget _buildAttractionsUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Text(
          "ATTRACTIONS NEAR YOU!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    hintText: "Enter destination",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _determinePosition,
                icon: const Icon(Icons.my_location),
                label: const Text("Use My Location"),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _searchDestination,
          child: const Text("Search"),
        ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
            markers: _markers,
            onMapCreated: (controller) => _mapController.complete(controller),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _pages => [
    _buildAttractionsUI(),
    const ProfileScreen(),
    const MatchScreen(),
    const ChatScreen(),
    const ItineraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Match'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Itinerary'),
        ],
      ),
    );
  }
}
