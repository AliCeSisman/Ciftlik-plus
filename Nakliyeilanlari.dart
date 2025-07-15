import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NakliyeScreen extends StatefulWidget {
  const NakliyeScreen({super.key});

  @override
  _NakliyeScreenState createState() => _NakliyeScreenState();
}

class _NakliyeScreenState extends State<NakliyeScreen> {
  String? userCity;
  String? userDistrict;
  String nereden = "";
  String nereye = "";

  List<String> vehicleTypes = ["Kamyon", "Tır", "Kamyonet", "Dorse"];
  String? selectedVehicle;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userCity = userData.get('city') ?? "Bilinmiyor";
        userDistrict = userData.get('district') ?? "Bilinmiyor";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nakliye Hizmetleri")),
      body: Column(
        children: [
          // nerden nereye arama çubuğu
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Nereden",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        nereden = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Nereye",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        nereye = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              hint: Text("Araç Tipi Seç"),
              value: selectedVehicle,
              onChanged: (value) {
                setState(() {
                  selectedVehicle = value;
                });
              },
              items: vehicleTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('nakliye').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text("Bu bölgede nakliyeci bulunamadı."));
                }

                var nakliyeciler = snapshot.data!.docs;

                // nereden nereye filtrele
                if (nereden.isNotEmpty) {
                  nakliyeciler = nakliyeciler.where((doc) {
                    return doc['serviceArea']
                        .toString()
                        .toLowerCase()
                        .contains(nereden.toLowerCase());
                  }).toList();
                }

                if (nereye.isNotEmpty) {
                  nakliyeciler = nakliyeciler.where((doc) {
                    return doc['serviceArea']
                        .toString()
                        .toLowerCase()
                        .contains(nereye.toLowerCase());
                  }).toList();
                }

                // araç tipi filtrele
                if (selectedVehicle != null) {
                  nakliyeciler = nakliyeciler
                      .where((doc) =>
                          doc['vehicleType'].toUpperCase() ==
                          selectedVehicle!.toUpperCase())
                      .toList();
                }

                return ListView.builder(
                  itemCount: nakliyeciler.length,
                  itemBuilder: (context, index) {
                    var doc = nakliyeciler[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(doc['name'].toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Araç Tipi: ${doc['vehicleType'].toUpperCase()}\nKapasite: ${doc['capacity']} ton\nBölge: ${doc['serviceArea'].toUpperCase()}"),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NakliyeDetailScreen(doc: doc),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NakliyeDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const NakliyeDetailScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doc['name'].toUpperCase())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Araç Tipi: ${doc['vehicleType'].toUpperCase()}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Kapasite: ${doc['capacity']} ton",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Hizmet Bölgesi: ${doc['serviceArea'].toUpperCase()}",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Fiyatlandırma: ${doc['pricing']}",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text("İletişim Bilgileri:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text("Telefon: ${doc['phone']}", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
