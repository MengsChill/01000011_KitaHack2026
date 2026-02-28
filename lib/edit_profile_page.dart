import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:developer';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _statusController = TextEditingController();
  File? _imageFile;
  String? _currentPhotoUrl;
  bool _isLoading = false;

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? user!.displayName ?? '';
        _statusController.text = data['status'] ?? 'Basic Plan';
        if (mounted) {
          setState(() {
            _currentPhotoUrl = data['photoUrl'] ?? user!.photoURL;
          });
        }
      } else {
        _nameController.text = user!.displayName ?? '';
        _statusController.text = 'Basic Plan';
        if (mounted) {
          setState(() {
            _currentPhotoUrl = user!.photoURL;
          });
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || user == null) return;

    setState(() => _isLoading = true);

    try {
      await user?.reload();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null)
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User session expired',
        );

      String? photoUrl = _currentPhotoUrl;

      if (_imageFile != null) {
        if (!await _imageFile!.exists()) {
          throw FirebaseException(
            plugin: 'storage',
            code: 'file-not-found',
            message: 'Local image file not found',
          );
        }

        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('${currentUser.uid}.jpg');

          log('Starting image upload to: ${ref.fullPath}');

          await ref.putFile(_imageFile!);

          log('Image upload finished. Fetching download URL...');

          photoUrl = await ref.getDownloadURL();

          log('Got download URL: $photoUrl');
        } on FirebaseException catch (e) {
          log('Storage Error: ${e.code} - ${e.message}');
          if (e.code == 'object-not-found') {
            throw FirebaseException(
              plugin: 'storage',
              code: 'upload-failed',
              message:
                  'Image upload verification failed (Object not found). Check Storage Rules.',
            );
          }
          rethrow;
        }
      }

      log('Updating Firestore for user: ${currentUser.uid}');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
            'name': _nameController.text.trim(),
            'status': _statusController.text.trim(),
            'photoUrl': photoUrl,
            'email': currentUser.email,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await currentUser.updateDisplayName(_nameController.text.trim());
      if (photoUrl != null) {
        await currentUser.updatePhotoURL(photoUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile Updated Successfully!'),
            backgroundColor: Color(0xFFF570B2),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      log('Firebase Error updating profile: ${e.code} - ${e.message}');
      if (mounted) {
        String errorMessage = 'Failed to update profile';
        if (e.code == 'permission-denied') {
          errorMessage = 'Permission Denied: Check Rules.';
        } else if (e.code == 'object-not-found') {
          errorMessage = 'Storage Error: Object not found.';
        } else if (e.code == 'upload-failed') {
          errorMessage = 'Image Upload Failed: ${e.message}';
        } else {
          errorMessage = 'Error (${e.code}): ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      log('Generic Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_currentPhotoUrl != null
                                      ? NetworkImage(_currentPhotoUrl!)
                                            as ImageProvider
                                      : null),
                            child:
                                (_imageFile == null && _currentPhotoUrl == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: const Color(0xFFF570B2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: const Color(0xFFF570B2),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Name cannot be empty" : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _statusController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Status / Plan",
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.star_outline,
                          color: const Color(0xFFF570B2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF570B2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
