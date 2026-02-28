import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'history_page.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({super.key});

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  String? _linkedUserId;
  bool _isLoading = true;
  GoogleMapController? _mapController;
  Marker? _userMarker;

  @override
  void initState() {
    super.initState();
    _fetchLinkedUser();
  }

  Future<void> _fetchLinkedUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _linkedUserId = doc.data()?['linked_user'];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_linkedUserId == null) {
      return _buildNoLinkedUserScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_linkedUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) {
            return const Center(
              child: Text(
                "User data not found.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          double lat = userData['lat'] ?? 37.3318;
          double lng = userData['lng'] ?? -122.0312;
          LatLng currentPos = LatLng(lat, lng);

          String userName = userData['name'] ?? 'User';
          bool isConnected = userData['is_connected'] ?? true;
          int battery = userData['battery'] ?? 85;

          _userMarker = Marker(
            markerId: const MarkerId('user_location'),
            position: currentPos,
            infoWindow: InfoWindow(
              title: userName,
              snippet: "Last Updated: Just now",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          );

          _mapController?.animateCamera(CameraUpdate.newLatLng(currentPos));

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: currentPos,
                  zoom: 16,
                ),
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                markers: {_userMarker!},
                onMapCreated: (controller) => _mapController = controller,
                style: '''
                  [
                    {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
                    {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
                    {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]}
                  ]
                ''',
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFFF570B2).withValues(
                              alpha: 0.2,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFFF570B2),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isConnected
                                      ? "🟢 Pole Connected"
                                      : "🔴 Pole Disconnected",
                                  style: TextStyle(
                                    color: isConnected
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.battery_full,
                                  color: Colors.greenAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "$battery%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionBar(
                            Icons.call,
                            "Call",
                            Colors.green,
                            () {},
                          ),
                          _buildActionBar(
                            Icons.history,
                            "History",
                            Colors.blueAccent,
                            () {
                              if (_linkedUserId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HistoryPage(
                                      userId: _linkedUserId!,
                                      userName: userName,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          _buildActionBar(
                            Icons.navigation,
                            "Navigate",
                            Colors.pinkAccent,
                            () {},
                          ),
                          _buildActionBar(
                            Icons.settings_input_component,
                            "Hardware",
                            Colors.orangeAccent,
                            () => _showHardwareSetupDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showHardwareSetupDialog(BuildContext context) {
    final TextEditingController _tokenController = TextEditingController();
    bool _isObscure = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              "Hardware Setup",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter the Blynk Auth Token for the primary user's smart stick.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _tokenController,
                  obscureText: _isObscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Blynk Auth Token",
                    labelStyle: const TextStyle(color: Color(0xFFF570B2)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final token = _tokenController.text.trim();
                  if (token.isNotEmpty && _linkedUserId != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_linkedUserId)
                        .update({'blynkToken': token});
                    if (context.mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Blynk Token Saved!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF570B2),
                ),
                child: const Text("SAVE TOKEN"),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildNoLinkedUserScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Caregiver Mode"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link_off, size: 100, color: Color(0xFFF570B2)),
              const SizedBox(height: 30),
              const Text(
                "No Account Linked",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "You haven't paired with a primary user yet. Enter their 6-digit code to start monitoring.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/pairing').then((_) {
                    setState(() {
                      _isLoading = true;
                    });
                    _fetchLinkedUser();
                  });
                },
                icon: const Icon(Icons.add_link),
                label: const Text("PAIR WITH USER"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  backgroundColor: const Color(0xFFF570B2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
