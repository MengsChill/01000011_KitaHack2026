import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class PairingPage extends StatefulWidget {
  const PairingPage({super.key});

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> {
  final _codeController = TextEditingController();
  String _userRole = 'blind_user';
  String _generatedCode = '';
  bool _isLoading = true;
  bool _isLinking = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'blind_user';
          _generatedCode = doc.data()?['pairing_code'] ?? '';
          _isLoading = false;
        });

        if (_userRole == 'blind_user' && _generatedCode.isEmpty) {
          _generateNewCode();
        }
      }
    }
  }

  Future<void> _generateNewCode() async {
    setState(() => _isLoading = true);

    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    String newCode = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'pairing_code': newCode},
      );

      if (mounted) {
        setState(() {
          _generatedCode = newCode;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _linkToUser() async {
    final inputCode = _codeController.text.trim().toUpperCase();
    if (inputCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code must be 6 characters.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLinking = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('pairing_code', isEqualTo: inputCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid pairing code.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLinking = false);
        return;
      }

      final targetUserId = querySnapshot.docs.first.id;
      final caregiverRef = FirebaseAuth.instance.currentUser;

      if (caregiverRef != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .update({
              'linked_accounts': FieldValue.arrayUnion([caregiverRef.uid]),
            });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(caregiverRef.uid)
            .update({'linked_user': targetUserId});

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully Linked!'),
            backgroundColor: Color(0xFFF570B2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    if (mounted) setState(() => _isLinking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Link Account"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.link, size: 80, color: Color(0xFFF570B2)),
            const SizedBox(height: 20),
            if (_userRole == 'blind_user') ...[
              const Text(
                "Your Pairing Code",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFF570B2)),
                ),
                child: Text(
                  _generatedCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Share this 6-digit code with your caregiver so they can monitor your location.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 30),
              TextButton.icon(
                onPressed: _generateNewCode,
                icon: const Icon(Icons.refresh),
                label: const Text("Generate New Code"),
              ),
            ] else ...[
              const Text(
                "Enter Pairing Code",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Ask the primary user for their 6-digit pairing code and enter it below.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  letterSpacing: 10,
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLinking ? null : _linkToUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: const Color(0xFFF570B2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLinking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "LINK ACCOUNT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
