import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _neighborhoodController = TextEditingController();

  File? _pickedImage;
  String? _profileImageUrl;
  bool _isLoading = false;

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _cityController.text = data['city'] ?? '';
      _districtController.text = data['district'] ?? '';
      _neighborhoodController.text = data['neighborhood'] ?? '';
      _profileImageUrl = data['profile_picture'];
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_pickedImage == null || currentUser == null) return _profileImageUrl;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures/${currentUser!.uid}.jpg');
    await ref.putFile(_pickedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final imageUrl = await _uploadProfileImage();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .update({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'neighborhood': _neighborhoodController.text.trim(),
      'profile_picture': imageUrl,
    });

    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Profil bilgileri güncellendi')));
    Navigator.pop(context);
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      bool requiredField = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: requiredField
            ? (value) =>
                value == null || value.trim().isEmpty ? 'Bu alan zorunlu' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profil Bilgileri")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : (_profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null) as ImageProvider?,
                  child: _pickedImage == null && _profileImageUrl == null
                      ? Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _nameController,
                  label: "Ad Soyad",
                  requiredField: true),
              _buildTextField(
                  controller: _phoneController,
                  label: "Telefon",
                  requiredField: true),
              _buildTextField(
                  controller: _cityController,
                  label: "Şehir",
                  requiredField: true),
              _buildTextField(
                  controller: _districtController,
                  label: "İlçe",
                  requiredField: true),
              _buildTextField(
                  controller: _neighborhoodController,
                  label: "Mahalle",
                  requiredField: true),
              const SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: Icon(Icons.save),
                        label: Text("Kaydet"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
