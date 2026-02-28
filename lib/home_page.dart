import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:weather/weather.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'settings_page.dart';
import 'notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  bool _isConnected = false;
  String _statusText = "DISCONNECTED";
  Color _statusColor = Colors.grey;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _currentAddress = "Locating...";

  WeatherFactory? _weatherFactory;
  Weather? _weather;
  final String _weatherApiKey = dotenv.env['WEATHER_API_KEY'] ?? "";

  String? _dynamicBlynkToken;
  Timer? _blynkTimer;
  double _obstacleDistance = 999.0; // Distance in cm
  DateTime? _lastLogTime;
  Position? _lastLoggedPosition;

  late AnimationController _rippleController;
  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _getCurrentLocation();
    _weatherFactory = WeatherFactory(_weatherApiKey);
    _fetchStoredBlynkToken();
  }

  Future<void> _fetchStoredBlynkToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _dynamicBlynkToken = doc.data()?['blynkToken'];
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position? position = await Geolocator.getLastKnownPosition();

      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );

        _getAddressFromLatLng(position);
        _getWeather(position);
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _currentAddress = "Apple Park, Cupertino, CA";
          _currentPosition = Position(
            latitude: 37.3318,
            longitude: -122.0312,
            timestamp: DateTime.now(),
            accuracy: 100,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _currentAddress =
                "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}"
                    .replaceAll(RegExp(r'^, |, , |, $'), '');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Unknown Location";
        });
      }
    }
  }

  Future<void> _getWeather(Position position) async {
    if (_weatherApiKey == "YOUR_WEATHER_API_KEY_HERE") {
      return;
    }
    if (_weatherFactory == null) return;
    try {
      Weather weather = await _weatherFactory!.currentWeatherByLocation(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _weather = weather;
        });
      }
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleConnection() {
    setState(() {
      _isConnected = !_isConnected;

      if (_isConnected) {
        _statusText = "CONNECTING...";
        _statusColor = Colors.orange;
        _rippleController.repeat(reverse: true);
        _startBlynkPolling();
      } else {
        _statusText = "DISCONNECTED";
        _statusColor = Colors.grey;
        _rippleController.stop();
        _rippleController.reset();
        _stopBlynkPolling();
      }
    });
  }

  void _startBlynkPolling() {
    _stopBlynkPolling(); // Ensure no duplicate timers
    _fetchBlynkData(); // Initial fetch
    _blynkTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchBlynkData();
    });
  }

  void _stopBlynkPolling() {
    _blynkTimer?.cancel();
    _blynkTimer = null;
  }

  Future<void> _fetchBlynkData() async {
    if (!mounted || !_isConnected || _dynamicBlynkToken == null) return;

    try {
      final token = _dynamicBlynkToken!;
      // V0: Connection (0 or 1), V1: Lat, V2: Lon, V3: Obstacle Distance (cm)
      final statusRes = await http.get(Uri.parse("https://blynk.cloud/external/api/get?token=$token&v0"));
      final latRes = await http.get(Uri.parse("https://blynk.cloud/external/api/get?token=$token&v1"));
      final lonRes = await http.get(Uri.parse("https://blynk.cloud/external/api/get?token=$token&v2"));
      final obsRes = await http.get(Uri.parse("https://blynk.cloud/external/api/get?token=$token&v3"));

      if (statusRes.statusCode == 200) {
        setState(() {
          bool isOnline = statusRes.body.trim() == "1";
          _statusText = isOnline ? "SECURELY CONNECTED" : "STICK OFFLINE";
          _statusColor = isOnline ? const Color(0xFF10B981) : Colors.redAccent;
        });
      }

      if (obsRes.statusCode == 200) {
        setState(() {
          _obstacleDistance = double.tryParse(obsRes.body.trim()) ?? 999.0;
        });
      }

      if (latRes.statusCode == 200 && lonRes.statusCode == 200) {
        double? lat = double.tryParse(latRes.body);
        double? lon = double.tryParse(lonRes.body);
        
        if (lat != null && lon != null) {
          final newPos = Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );

          setState(() {
            _currentPosition = newPos;
          });
          _getAddressFromLatLng(_currentPosition!);
          _logPositionToHistory(newPos);
        }
      }
    } catch (e) {
    }
  }

  Future<void> _logPositionToHistory(Position position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Log every 30 seconds if distance moved > 5 meters
    final now = DateTime.now();
    if (_lastLogTime != null && now.difference(_lastLogTime!).inSeconds < 30) {
      return;
    }

    if (_lastLoggedPosition != null) {
      double distance = Geolocator.distanceBetween(
        _lastLoggedPosition!.latitude,
        _lastLoggedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance < 5.0) return; // Haven't moved enough
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tracking_history')
          .add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _lastLogTime = now;
      _lastLoggedPosition = position;
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F172A),
      drawer: _buildDrawer(user),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          _buildAnalyticsPlaceholder(),
          _buildAITabPlaceholder(),
          const SettingsPage(),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: const Color(0xFFF570B2),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              label: "Analytics",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "AI"),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final User? user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFFF570B2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: user != null
                            ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots()
                            : null,
                        builder: (context, snapshot) {
                          String? photoUrl = user?.photoURL;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            photoUrl = data['photoUrl'] ?? photoUrl;
                          }
                          return CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            backgroundImage:
                                photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: SizedBox(
                        height: 70,
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: user != null
                              ? FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .snapshots()
                              : null,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const SizedBox();
                            }
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final List<dynamic> linkedUids =
                                userData['linked_accounts'] ?? [];

                            if (linkedUids.isEmpty) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "No family linked",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    user?.displayName ?? "User",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: linkedUids.length,
                              itemBuilder: (context, index) {
                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(linkedUids[index])
                                      .get(),
                                  builder: (context, caregiverSnapshot) {
                                    if (!caregiverSnapshot.hasData) {
                                      return const SizedBox(width: 60);
                                    }
                                    final cgData =
                                        caregiverSnapshot.data!.data()
                                            as Map<String, dynamic>?;
                                    final cgName =
                                        cgData?['name']?.split(' ')[0] ?? '...';
                                    final cgPhoto = cgData?['photoUrl'];

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 15),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                Colors.white.withValues(alpha: 0.1),
                                            backgroundImage: cgPhoto != null
                                                ? NetworkImage(cgPhoto)
                                                : null,
                                            child: cgPhoto == null
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 14,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            cgName,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildWeatherCard(),
              _buildProximityRadar(),
              const SizedBox(height: 10),

              Center(
                child: GestureDetector(
                  onTap: _toggleConnection,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isConnected)
                        FadeTransition(
                          opacity: Tween<double>(
                            begin: 0.5,
                            end: 0.0,
                          ).animate(_rippleController),
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 1.0,
                              end: 1.5,
                            ).animate(_rippleController),
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),

                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F172A),
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor.withValues(alpha: 0.6),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            const BoxShadow(
                              color: Colors.white10,
                              offset: Offset(-5, -5),
                              blurRadius: 10,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.power_settings_new,
                              size: 50,
                              color: _statusColor,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isConnected ? "ON" : "OFF",
                              style: TextStyle(
                                color: _statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                _statusText,
                style: TextStyle(
                  color: _statusColor,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF570B2).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFF570B2),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Current Location",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentAddress,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: _currentPosition == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF570B2),
                          ),
                        )
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            zoom: 15.0,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: false,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                        ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildWeatherCard() {
    if (_weather == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_queue, color: Colors.white38),
            const SizedBox(width: 15),
            Text(
              "Weather unavailable",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    final temp = _weather!.temperature?.celsius?.toStringAsFixed(1) ?? "--";
    final condition = _weather!.weatherDescription ?? "Unknown";
    final iconCode = _weather!.weatherIcon;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF570B2).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF570B2).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF570B2).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (iconCode != null)
            Image.network(
              "https://openweathermap.org/img/wn/$iconCode@2x.png",
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.wb_sunny, color: Colors.orange, size: 30),
            )
          else
            const Icon(Icons.wb_sunny, color: Colors.orange, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$temp°C",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                Text(
                  condition.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Feels like ${_weather!.tempFeelsLike?.celsius?.toStringAsFixed(1) ?? "--"}°",
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              Text(
                "Humidity ${_weather!.humidity ?? "--"}%",
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProximityRadar() {
    Color radarColor = Colors.greenAccent;
    String warning = "PATH CLEAR";
    double opacity = 0.1;

    if (_obstacleDistance < 50) {
      radarColor = Colors.redAccent;
      warning = "IMMEDIATE OBSTACLE";
      opacity = 0.6;
    } else if (_obstacleDistance < 150) {
      radarColor = Colors.orangeAccent;
      warning = "OBSTACLE AHEAD";
      opacity = 0.3;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: radarColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: radarColor.withValues(alpha: opacity)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.radar, color: radarColor, size: 40),
              if (_isConnected && _obstacleDistance < 150)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: _obstacleDistance < 50 ? 500 : 1000),
                  builder: (context, value, child) {
                    return Container(
                      width: 60 * value,
                      height: 60 * value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: radarColor.withValues(alpha: 1.0 - value)),
                      ),
                    );
                  },
                  onEnd: () {
                    // This creates a loop effect (manual trigger of rebuild if needed)
                  },
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning,
                  style: TextStyle(
                    color: radarColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _isConnected ? "${_obstacleDistance.toStringAsFixed(0)} cm away" : "Sensing offline",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (_isConnected && _obstacleDistance < 150)
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFFF570B2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 80,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 20),
            const Text(
              "Analytics Coming Soon",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAITabPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFFF570B2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 20),
            const Text(
              "AI Assistant",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Get AI explanations and help here",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(User? user) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: user != null
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots()
                  : null,
              builder: (context, snapshot) {
              String name = user?.displayName ?? "PoleUser";
              String? photoUrl = user?.photoURL;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                name = data['name'] ?? name;
                photoUrl = data['photoUrl'] ?? photoUrl;
              }
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFFF570B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 40)
                      : null,
                ),
                accountName: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(user?.email ?? ""),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.family_restroom, color: Color(0xFFF570B2), size: 20),
                SizedBox(width: 10),
                Text(
                  "MY FAMILY CIRCLE",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: user != null
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots()
                  : null,
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: CircularProgressIndicator());
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic> linkedUids =
                    userData['linked_accounts'] ?? [];

                if (linkedUids.isEmpty) {
                  return const Center(
                    child: Text(
                      "No family linked yet",
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: linkedUids.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(linkedUids[index])
                          .get(),
                      builder: (context, caregiverSnapshot) {
                        if (!caregiverSnapshot.hasData) {
                          return const ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text("Loading...",
                                style: TextStyle(color: Colors.white70)),
                          );
                        }
                        final cgData = caregiverSnapshot.data!.data()
                            as Map<String, dynamic>?;
                        final cgName = cgData?['name'] ?? 'Family Member';
                        final cgEmail = cgData?['email'] ?? '';
                        final cgPhoto = cgData?['photoUrl'];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            backgroundImage: cgPhoto != null
                                ? NetworkImage(cgPhoto)
                                : null,
                            child: cgPhoto == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          title: Text(
                            cgName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            cgEmail,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          onTap: () {
                            // Future enhancement: detailed view
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.person_add_alt_1, color: Color(0xFFF570B2)),
            title: const Text("Register Elderly", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Link a new primary user", style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/pairing');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: const Text("Settings", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 3;
              });
            },
          ),
          const Spacer(),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.white)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}
}
