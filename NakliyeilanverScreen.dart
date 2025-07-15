import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddNakliyeScreen extends StatefulWidget {
  const AddNakliyeScreen({super.key});

  @override
  _AddNakliyeScreenState createState() => _AddNakliyeScreenState();
}

class _AddNakliyeScreenState extends State<AddNakliyeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController serviceAreaController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<String> vehicleTypes = ["Kamyon", "Tır", "Kamyonet", "Dorse"];
  String? selectedVehicle;
  bool isLoading = false;

  Future<void> _uploadNakliyeListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      await FirebaseFirestore.instance.collection('nakliye').add({
        'userId': userId,
        'name': userData.get('name') ?? "Bilinmeyen Kullanıcı",
        'phone': userData.get('phone') ?? "Bilinmeyen Numara",
        'vehicleType': selectedVehicle,
        'capacity': capacityController.text.trim(),
        'serviceArea': serviceAreaController.text.trim(),
        'pricing': priceController.text.trim(),
        'description': descriptionController.text.trim(),
        'city': userData.get('city') ?? "",
        'district': userData.get('district') ?? "",
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nakliye ilanı başarıyla eklendi!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İlan eklenirken hata oluştu!")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nakliye İlanı Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Aşağıdaki bilgileri doldurarak nakliye hizmeti ilanınızı oluşturabilirsiniz.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedVehicle,
                      hint: Text("Araç Tipi Seç"),
                      onChanged: (value) =>
                          setState(() => selectedVehicle = value),
                      items: vehicleTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: "Araç Tipi",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      validator: (value) =>
                          value == null ? "Araç tipi seçin" : null,
                    ),
                    _buildTextField(capacityController, "Kapasite (ton)",
                        TextInputType.number),
                    _buildTextField(serviceAreaController,
                        "Hizmet Bölgesi (örn. Ankara-Konya)"),
                    _buildTextField(priceController,
                        "Fiyatlandırma (örn. 5000₺)", TextInputType.number),
                    _buildTextField(descriptionController, "Açıklama", null, 3),
                    SizedBox(height: 20),
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _uploadNakliyeListing,
                            icon: Icon(Icons.cloud_upload),
                            label: Text("İlanı Yayınla"),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              textStyle: TextStyle(fontSize: 16),
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, [
    TextInputType? keyboardType,
    int maxLines = 1,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "$label zorunludur" : null,
      ),
    );
  }
}
