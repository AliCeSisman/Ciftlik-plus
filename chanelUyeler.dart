import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChannelMembersScreen extends StatelessWidget {
  final String channelId;
  const ChannelMembersScreen({super.key, required this.channelId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final channelRef =
        FirebaseFirestore.instance.collection('channels').doc(channelId);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: channelRef.get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text("Kanal");
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            return Text(data['name'] ?? 'Kanal');
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: channelRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List members = data['members'] ?? [];
          final List admins = data['admins'] ?? [];
          final isAdmin = admins.contains(currentUserId);

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final memberId = members[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return SizedBox();
                  }

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Kullanıcı';
                  final profileUrl = userData['profile_picture'];
                  final isSelf = memberId == currentUserId;

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profileUrl != null
                            ? NetworkImage(profileUrl)
                            : null,
                        child: profileUrl == null ? Icon(Icons.person) : null,
                      ),
                      title: Text(userName,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text(admins.contains(memberId) ? "Yönetici" : "Üye"),
                      trailing: isAdmin && !isSelf
                          ? PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'kick') {
                                  await channelRef.update({
                                    'members':
                                        FieldValue.arrayRemove([memberId]),
                                    'admins':
                                        FieldValue.arrayRemove([memberId]),
                                  });
                                } else if (value == 'make_admin') {
                                  await channelRef.update({
                                    'admins': FieldValue.arrayUnion([memberId]),
                                  });
                                } else if (value == 'remove_admin') {
                                  await channelRef.update({
                                    'admins':
                                        FieldValue.arrayRemove([memberId]),
                                  });
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                    value: 'kick',
                                    child: Text('Kanaldan Çıkar')),
                                if (!admins.contains(memberId))
                                  PopupMenuItem(
                                      value: 'make_admin',
                                      child: Text('Yönetici Yap')),
                                if (admins.contains(memberId))
                                  PopupMenuItem(
                                      value: 'remove_admin',
                                      child: Text('Yöneticiliği Al')),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
