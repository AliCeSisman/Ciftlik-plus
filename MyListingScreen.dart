import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text("İlanlarım")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Henüz eklediğiniz bir ilan yok."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];

              // **📌 imageUrls Alanını Güvenli Şekilde Kontrol Et**
              List<String> imageUrls = [];
              String title = "Başlık Yok";
              String price = "Fiyat Yok";

              if (doc.data() != null && doc.data() is Map<String, dynamic>) {
                var data = doc.data() as Map<String, dynamic>;

                if (data.containsKey('imageUrls') &&
                    data['imageUrls'] is List) {
                  imageUrls = List<String>.from(data['imageUrls']);
                }
                title = data['title'] ?? "Başlık Yok";
                price =
                    data['price'] != null ? "${data['price']}₺" : "Fiyat Yok";
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrls[0], // İlk resmi kullan
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Icon(Icons.image_not_supported,
                          size: 60, color: Colors.grey),
                  title: Text(title,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Fiyat: $price"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingDetailScreen(doc: doc),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditListingScreen(doc: doc),
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
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("İlanı Sil"),
          content: Text("Bu ilanı silmek istediğinize emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('listings')
                      .doc(docId)
                      .delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("İlan başarıyla silindi.")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("İlan silinirken hata oluştu.")),
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

// **📌 İlan Düzenleme Ekranı**
class EditListingScreen extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const EditListingScreen({super.key, required this.doc});

  @override
  _EditListingScreenState createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late List<String> imageUrls;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.doc['title']);
    descriptionController =
        TextEditingController(text: widget.doc['description']);
    priceController =
        TextEditingController(text: widget.doc['price'].toString());
    imageUrls = List<String>.from(widget.doc['imageUrls'] ?? []);
  }

  void _updateListing() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lütfen tüm alanları doldurun !"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.doc.id)
          .update({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': priceController.text.trim(),
        'imageUrls': imageUrls, // Güncellenmiş resim listesi
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("İlan başarıyla güncellendi!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("İlan güncellenirken hata oluştu!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("İlanı Düzenle")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Başlık"),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Açıklama"),
              maxLines: 3,
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: "Fiyat (₺)"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateListing,
              child: Text("Güncelle"),
            ),
          ],
        ),
      ),
    );
  }
}

// İlan Detaylarını görmek için kullanılan fonksiyon
class ListingDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const ListingDetailScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    List<String> imageUrls =
        doc['imageUrls'] != null ? List<String>.from(doc['imageUrls']) : [];

    return Scaffold(
      appBar: AppBar(title: Text(doc['title'])),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrls.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullScreenImageGallery(imageUrls: imageUrls),
                    ),
                  );
                },
                child: SizedBox(
                  height: 250,
                  child: PageView.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Hero(
                        tag: imageUrls[index],
                        child: Image.network(
                          imageUrls[index],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Center(
                  child: Text("Fotoğraf bulunamadı.",
                      style: TextStyle(fontSize: 16))),
            SizedBox(height: 10),
            Text("Fiyat: ${doc['price']}₺",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Açıklama:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(doc['description'], style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// resimleri tam ekran görmek için kullanılan sınıf
class FullScreenImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  const FullScreenImageGallery({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Hero(
                tag: imageUrls[index],
                child: Image.network(imageUrls[index], fit: BoxFit.contain),
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
