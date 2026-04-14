import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  File? _image;
  final picker = ImagePicker();
  final TextEditingController descriptionController = TextEditingController();

  Position? currentLocation;
  bool isUploading = false;

  String selectedSeverity = "Medium";
  List<String> severityLevels = ["Low", "Medium", "High"];

  String selectedCategory = "Pothole";
  List<String> categories = [
    "Pothole",
    "Street Light",
    "Garbage",
    "Water Leakage",
    "Drainage",
    "Traffic Signal",
    "Road Damage",
    "Other",
  ];

  String locationText = "";

  /// PICK IMAGE
  Future pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  /// GET LOCATION
  Future getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission permanently denied")),
      );
      return;
    }

    currentLocation = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      locationText =
          "Lat: ${currentLocation!.latitude}, Lng: ${currentLocation!.longitude}";
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Location Captured")));
  }

  /// SUBMIT
  Future submitReport() async {
    FocusScope.of(context).unfocus();

    if (_image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please capture an image")));
      return;
    }

    if (currentLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please capture location")));
      return;
    }

    if (descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter description")));
      return;
    }

    setState(() => isUploading = true);

    try {
      String reportId = const Uuid().v4();
      String userId = FirebaseAuth.instance.currentUser!.uid;

      int severityPriority = selectedSeverity == "High"
          ? 3
          : selectedSeverity == "Low"
          ? 1
          : 2;

      final storageRef = FirebaseStorage.instance.ref().child(
        "report_images/$reportId.jpg",
      );

      await storageRef.putFile(_image!);
      String imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection("reports").doc(reportId).set({
        "report_id": reportId,
        "user_id": userId,
        "image_url": imageUrl,
        "description": descriptionController.text.trim(),
        "category": selectedCategory.toLowerCase(),
        "latitude": currentLocation!.latitude,
        "longitude": currentLocation!.longitude,
        "severity": selectedSeverity.toLowerCase(),
        "severity_priority": severityPriority,
        "status": "pending",
        "created_at": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report Submitted Successfully")),
      );

      setState(() {
        _image = null;
        descriptionController.clear();
        currentLocation = null;
        locationText = "";
        selectedSeverity = "Medium";
        selectedCategory = "Pothole";
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        title: const Text("Report Issue"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            /// IMAGE CARD
            _card(
              child: Column(
                children: [
                  _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _image!,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.camera_alt, size: 40),
                          ),
                        ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Capture Image"),
                    style: _buttonStyle(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// LOCATION CARD
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Location",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: getLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text("Get Current Location"),
                    style: _buttonStyle(),
                  ),

                  if (locationText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        locationText,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// DETAILS CARD
            _card(
              child: Column(
                children: [
                  DropdownButtonFormField(
                    value: selectedCategory,
                    decoration: _inputDecoration("Category"),
                    items: categories
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: _inputDecoration("Description"),
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField(
                    value: selectedSeverity,
                    decoration: _inputDecoration("Severity"),
                    items: severityLevels
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedSeverity = v!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// SUBMIT BUTTON
            isUploading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B61FF),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Submit Report"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// REUSABLE CARD
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7B61FF),
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
