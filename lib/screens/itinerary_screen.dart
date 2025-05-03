import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  String? selectedDestination;
  int numberOfDays = 1;
  List<String> preferences = [];
  List<List<Map<String, String>>> itinerary = [];

  final List<String> preferenceOptions = [
    'Food',
    'Nature',
    'History',
    'Art',
    'Adventure',
    'Nightlife',
    'Shopping',
    'Sports',
    'Relaxation',
  ];

  // Replace with your actual Google Places API key
  final _googlePlaces = GoogleMapsPlaces(
    apiKey: 'AIzaSyDfQhsjL8tkYd5XAM4JQbE8o3RYSc3wCT0',
  );

  final Map<String, List<Map<String, String>>> mockAttractions = {
    'Food': [
      {'name': 'Breakfast at Cafe', 'time': '9:00 AM'},
      {'name': 'Lunch at Diner', 'time': '12:00 PM'},
      {'name': 'Dinner at Italian Restaurant', 'time': '6:00 PM'},
    ],
    'Nature': [
      {'name': 'Hiking in National Park', 'time': '10:00 AM'},
      {'name': 'Visit to Botanical Garden', 'time': '2:00 PM'},
      {'name': 'Nature Walk at Lakeside', 'time': '4:00 PM'},
    ],
    'History': [
      {'name': 'Visit to Ancient Ruins', 'time': '10:00 AM'},
      {'name': 'Museum Tour', 'time': '1:00 PM'},
      {'name': 'Historic City Walking Tour', 'time': '3:00 PM'},
    ],
    'Art': [
      {'name': 'Gallery Visit', 'time': '10:00 AM'},
      {'name': 'Street Art Tour', 'time': '12:00 PM'},
      {'name': 'Art Workshop', 'time': '2:00 PM'},
    ],
    'Adventure': [
      {'name': 'Kayaking Tour', 'time': '11:00 AM'},
      {'name': 'Ziplining Adventure', 'time': '3:00 PM'},
      {'name': 'Rock Climbing', 'time': '5:00 PM'},
    ],
    'Nightlife': [
      {'name': 'Nightclub Dance', 'time': '10:00 PM'},
      {'name': 'Rooftop Bar Hangout', 'time': '8:00 PM'},
      {'name': 'Live Music Concert', 'time': '7:00 PM'},
    ],
    'Shopping': [
      {'name': 'Visit to Local Market', 'time': '10:00 AM'},
      {'name': 'Mall Shopping', 'time': '2:00 PM'},
      {'name': 'Luxury Store Visit', 'time': '4:00 PM'},
    ],
    'Sports': [
      {'name': 'Tennis Match', 'time': '9:00 AM'},
      {'name': 'Football Match', 'time': '12:00 PM'},
      {'name': 'Beach Volleyball', 'time': '3:00 PM'},
    ],
    'Relaxation': [
      {'name': 'Spa Appointment', 'time': '10:00 AM'},
      {'name': 'Yoga Session', 'time': '1:00 PM'},
      {'name': 'Beach Relaxation', 'time': '4:00 PM'},
    ],
  };

  // Function to get actual places based on activity and destination
  Future<List<String>> getPlacesForActivity(
    String activity,
    String destination,
  ) async {
    final result = await _googlePlaces.searchByText(
      activity + ' in $destination',
    );
    return result.results.map((place) => place.name).toList();
  }

  // Function to generate the itinerary
  void generateItinerary() async {
    List<List<Map<String, String>>> generated = [];
    for (int day = 0; day < numberOfDays; day++) {
      List<Map<String, String>> dayPlan = [];
      for (var pref in preferences) {
        final activities = mockAttractions[pref] ?? [];
        if (activities.isNotEmpty) {
          final activity = activities[day % activities.length];
          // Get the place for the activity
          final places = await getPlacesForActivity(
            activity['name']!,
            selectedDestination!,
          );
          if (places.isNotEmpty) {
            // Add the activity and a place to the itinerary
            dayPlan.add({
              'time': activity['time']!,
              'activity': activity['name']!,
              'place': places[0], // Show the first place from the results
            });
          }
        }
      }
      generated.add(dayPlan);
    }
    setState(() {
      itinerary = generated;
    });
  }

  void promptForDays() async {
    final controller = TextEditingController(text: numberOfDays.toString());
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("How many days?"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  final input = int.tryParse(controller.text);
                  if (input != null && input > 0) {
                    setState(() {
                      numberOfDays = input;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Custom Itinerary")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vacation brain? Let us plan your day(s)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: const InputDecoration(
                labelText: "Enter Destination",
                border: OutlineInputBorder(),
              ),
              onChanged:
                  (value) => setState(() {
                    selectedDestination = value;
                  }),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children:
                  preferenceOptions
                      .map(
                        (option) => FilterChip(
                          label: Text(option),
                          selected: preferences.contains(option),
                          onSelected:
                              (selected) => setState(() {
                                if (selected) {
                                  preferences.add(option);
                                } else {
                                  preferences.remove(option);
                                }
                              }),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: promptForDays,
                  child: Text("Days: $numberOfDays"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: generateItinerary,
                  child: const Text("Generate Itinerary"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: itinerary.length,
                itemBuilder: (context, index) {
                  final dayPlan = itinerary[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Day ${index + 1}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...dayPlan.map(
                            (activity) => Text(
                              "\uD83D\uDD52 ${activity['time']} – ${activity['activity']} at ${activity['place']}",
                            ),
                          ),
                        ],
                      ),
                    ),
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
