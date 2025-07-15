import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:danamobil/chanelUyeler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChannelOptionsScreen extends StatelessWidget {
  final String channelId;
  const ChannelOptionsScreen({super.key, required this.channelId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final channelRef =
        FirebaseFirestore.instance.collection('channels').doc(channelId);

    return Scaffold(
      appBar: AppBar(title: Text("Kanal Ayarları")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: channelRef.snapshots(), // ⬅️ Burayı değiştirdik
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List admins = data['admins'] ?? [];
          final bool isAdmin = admins.contains(currentUserId);

          final nameController =
              TextEditingController(text: data['name'] ?? '');
          final descController =
              TextEditingController(text: data['description'] ?? '');

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if (isAdmin) ...[
                  Text("Kanal Bilgisi",
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Kanal Adı"),
                  ),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(labelText: "Açıklama"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text("Güncelle"),
                    onPressed: () async {
                      await channelRef.update({
                        'name': nameController.text.trim(),
                        'description': descController.text.trim(),
                      });
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Güncellendi')));
                    },
                  ),
                ],
                SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: Icon(Icons.group),
                  label: Text("Üyeleri Gör"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChannelMembersScreen(channelId: channelId),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Divider(),
                ElevatedButton.icon(
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text("Kanaldan Çık"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () async {
                    if (isAdmin && admins.length == 1) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("Son Yönetici!"),
                          content: Text(
                              "Bu kanalda senden başka yönetici yok. Çıkmak için önce başkasını yönetici yapmalısın."),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("Tamam"))
                          ],
                        ),
                      );
                      return;
                    }

                    await channelRef.update({
                      'members': FieldValue.arrayRemove([currentUserId]),
                      'admins': FieldValue.arrayRemove([currentUserId]),
                    });

                    Navigator.of(context).popUntil((route) => route.isFirst);

                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Kanaldan çıkıldı')));
                  },
                ),
                SizedBox(height: 10),
                if (isAdmin)
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete_forever, color: Colors.white),
                    label: Text("Kanalı Sil"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("Kanalı Sil"),
                          content: Text(
                              "Bu kanal ve tüm mesajlar kalıcı olarak silinecek. Devam edilsin mi?"),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(context)
                                    .popUntil((route) => route.isFirst),
                                child: Text("Vazgeç")),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Sil")),
                          ],
                        ),
                      );
                      if (confirm != true) return;

                      await channelRef.delete();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Kanal silindi')));
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
