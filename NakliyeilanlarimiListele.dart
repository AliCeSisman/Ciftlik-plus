import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NakliyeListingsScreen extends StatelessWidget {
  const NakliyeListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Nakliye İlanlarım")),
      body: _buildNakliyeListings(userId),
    );
  }

  Widget _buildNakliyeListings(String userId) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('nakliye')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text("Henüz eklediğiniz bir nakliye ilanı yok."));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            return _buildNakliyeItem(context, doc);
          },
        );
      },
    );
  }

  Widget _buildNakliyeItem(BuildContext context, QueryDocumentSnapshot doc) {
    String vehicleType = doc["vehicleType"] ?? "Araç Bilgisi Yok";
    String serviceArea = doc["serviceArea"] ?? "Bölge Bilgisi Yok";
    String capacity = doc["capacity"] ?? "Bilinmiyor";
    String price = doc["pricing"] ?? "Fiyat Belirtilmemiş";

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Icon(Icons.local_shipping, size: 40, color: Colors.blue),
        title: Text("Araç: $vehicleType",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
            Text("Bölge: $serviceArea\nKapasite: $capacity ton\nFiyat: $price"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditNakliyeScreen(doc: doc),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, doc.id),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Nakliye İlanını Sil"),
          content: Text("Bu ilanı silmek istediğinize emin misiniz?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("İptal")),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('nakliye')
                      .doc(docId)
                      .delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("İlan başarıyla silindi.")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("İlan silinirken hata oluştu!")),
                  );
                }
              },
              child: Text("Sil", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class EditNakliyeScreen extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const EditNakliyeScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    TextEditingController priceController =
        TextEditingController(text: doc['pricing'] ?? "");
    TextEditingController serviceAreaController =
        TextEditingController(text: doc['serviceArea'] ?? "");

    return Scaffold(
      appBar: AppBar(title: Text("Nakliye İlanını Düzenle")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: serviceAreaController,
                decoration: InputDecoration(labelText: "Hizmet Bölgesi")),
            TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: "Fiyat"),
                keyboardType: TextInputType.number),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: Text("Güncelle")),
          ],
        ),
      ),
    );
  }
}
