import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class HastalikBildirFormScreen extends StatefulWidget {
  const HastalikBildirFormScreen({Key? key}) : super(key: key);

  @override
  State<HastalikBildirFormScreen> createState() =>
      _HastalikBildirFormScreenState();
}

class _HastalikBildirFormScreenState extends State<HastalikBildirFormScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  LatLng? selectedLocation;
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hastalık Bildir")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ŞEHİR / İLÇE GİRİŞ
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: "Şehir",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _districtController,
                      decoration: const InputDecoration(
                        labelText: "İlçe",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _goToCityDistrict,
                    child: const Text("Git"),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // HARİTA
              SizedBox(
                height: 300,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(38.0, 35.0),
                    initialZoom: 6.0,
                    onTap: (_, latlng) {
                      setState(() => selectedLocation = latlng);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              if (selectedLocation == null)
                const Text("Lütfen haritada bir konuma dokunun."),

              if (selectedLocation != null)
                Column(
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Başlık",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Açıklama",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    isSubmitting
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.send),
                            label: const Text("Bildirimi Gönder"),
                            onPressed: _submitReport,
                          ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _goToCityDistrict() async {
    final city = _cityController.text.trim();
    final district = _districtController.text.trim();

    if (city.isEmpty && district.isEmpty) return;

    final query =
        [district, city, "Türkiye"].where((e) => e.isNotEmpty).join(", ");

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);

        _mapController.move(target, 13.0);
        setState(() => selectedLocation = target);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Konum bulunamadı: $query")),
      );
    }
  }

  Future<void> _submitReport() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tüm alanları doldurup bir konum seçin."),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        selectedLocation!.latitude,
        selectedLocation!.longitude,
      );
      final city = placemarks.first.administrativeArea ?? "Bilinmiyor";
      final district = placemarks.first.subAdministrativeArea ?? "Bilinmiyor";

      await FirebaseFirestore.instance.collection('hastalik_bildirimleri').add({
        'baslik': titleController.text.trim(),
        'aciklama': descriptionController.text.trim(),
        'lat': selectedLocation!.latitude,
        'lng': selectedLocation!.longitude,
        'sehir': city,
        'ilce': district,
        'tarih': Timestamp.now(),
        'onayli': false,
        'yorumlar': [],
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Bildiriminiz gönderildi. Admin onayı bekleniyor.")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }
}
