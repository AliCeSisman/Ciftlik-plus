import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:danamobil/kanal_mesajlasma.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JoinedChannelsScreen extends StatelessWidget {
  const JoinedChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Katıldığım Kanallar")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('channels')
            .where('members', arrayContains: currentUserId)
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Henüz hiçbir kanala katılmadın.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            );
          }

          final channels = snapshot.data!.docs;

          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final data = channels[index].data() as Map<String, dynamic>;
              final channelId = channels[index].id;
              final name = data['name'] ?? 'Kanal';
              final desc = data['description'] ?? '';
              final members = data['members'] ?? [];

              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title:
                      Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('Üye Sayısı: ${members.length}'),
                      if (desc.isNotEmpty)
                        Text(desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChannelChatScreen(channelId: channelId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
