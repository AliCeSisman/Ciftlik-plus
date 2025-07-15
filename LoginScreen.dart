import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart'
    as img; // Resim sıkıştırma için bu paket kullanılıyor
import 'package:danamobil/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true; // Giriş mi, kayıt mı?
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController neighborhoodController = TextEditingController();
  final TextEditingController customJobController = TextEditingController();

  final List<String> roles = ["Çiftçi", "Tüccar", "Nakliyeci", "Diğer"];
  String? selectedRole;
  bool isCustomJob = false;
  File? _selectedImage;

  // galeriden fotograf seciyoruz az yer kaplaması için çözünürlük düşürüyoruz
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final image = img.decodeImage(File(pickedFile.path).readAsBytesSync());
      final resizedImage =
          img.copyResize(image!, width: 300, height: 300); // 300x300 çözünürlük
      final compressedFile = File('${pickedFile.path}_compressed.jpg')
        ..writeAsBytesSync(
            img.encodeJpg(resizedImage, quality: 75)); // Kalite %75

      setState(() {
        _selectedImage = compressedFile;
      });
    }
  }

  // Kullanıcıya doğrulama e-postası gönder
  Future<void> sendEmailVerification(User? user) async {
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Doğrulama e-postası gönderildi. Lütfen kontrol edin.")),
        );
      } catch (e) {
        print("Doğrulama e-postası gönderilemedi: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("E-posta gönderimi başarısız.")),
        );
      }
    }
  }

  //Kullanıcı kaydetme işlemi
  Future<void> registerUser() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;
      String profileImageUrl = '';

      if (_selectedImage != null) {
        final ref =
            _storage.ref().child('profile_pictures').child('$userId.jpg');
        await ref.putFile(_selectedImage!);
        profileImageUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('users').doc(userId).set({
        'user_id': userId,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': isCustomJob ? customJobController.text.trim() : selectedRole,
        'city': cityController.text.trim(),
        'district': districtController.text.trim(),
        'neighborhood': neighborhoodController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
        'profile_picture': profileImageUrl,
      });

      await sendEmailVerification(userCredential.user);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Kayıt başarılı!")));
    } catch (e) {
      print("Kayıt hatası: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Kayıt başarısız!")));
    }
  }

  Future<void> loginUser() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null && user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Giriş başarılı!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lütfen e-postanızı doğrulayın.")),
        );
      }
    } catch (e) {
      print("Giriş hatası: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Giriş başarısız!")));
    }
  }

  void _selectJob() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Meslek Seç"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...roles.map((role) {
                return ListTile(
                  title: Text(role),
                  onTap: () {
                    setState(() {
                      selectedRole = role;
                      isCustomJob = role == "Diğer";
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                isLogin ? "Giriş Yap" : "Kayıt Ol",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Profil resmi seçimi
              if (!isLogin)
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : null,
                    child: _selectedImage == null
                        ? Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
              if (!isLogin) SizedBox(height: 20),

              _buildTextField(emailController, "E-Posta", Icons.email),
              _buildTextField(passwordController, "Şifre", Icons.lock,
                  isPassword: true),

              if (!isLogin) ...[
                _buildTextField(nameController, "Ad Soyad", Icons.person),
                _buildTextField(phoneController, "Telefon", Icons.phone),
                _buildTextField(cityController, "Şehir", Icons.location_city),
                _buildTextField(districtController, "İlçe", Icons.business),
                _buildTextField(neighborhoodController, "Mahalle", Icons.home),
                ElevatedButton(
                  onPressed: _selectJob,
                  child: Text(selectedRole ?? "Meslek Seç"),
                ),
                if (isCustomJob)
                  _buildTextField(
                      customJobController, "Mesleğinizi Girin", Icons.work),
              ],

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLogin ? loginUser : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isLogin ? "Giriş Yap" : "Kayıt Ol",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  isLogin
                      ? "Hesabın yok mu? Kayıt Ol"
                      : "Zaten hesabın var mı? Giriş Yap",
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData iconData,
      {bool isPassword = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(iconData, color: Colors.blue),
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
