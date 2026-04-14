import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'map_reports_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> openImage(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> deleteReport(String reportId, String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    }

    await FirebaseFirestore.instance
        .collection("reports")
        .doc(reportId)
        .delete();
  }

  Future<void> deleteResolvedReports() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("reports")
        .where("status", isEqualTo: "resolved")
        .get();

    for (var doc in snapshot.docs) {
      String imageUrl = doc['image_url'] ?? "";

      if (imageUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      }

      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Admin Dashboard",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            /// STATS
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("reports")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                int total = docs.length;
                int resolved = docs
                    .where((doc) => (doc['status'] ?? "") == "resolved")
                    .length;
                int unresolved = total - resolved;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: _statCard("Total", total, Colors.blue)),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard("Resolved", resolved, Colors.green)),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard("Pending", unresolved, Colors.orange)),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            /// REPORT LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("reports")
                    .orderBy("severity_priority", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reports = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report =
                          reports[index].data() as Map<String, dynamic>;

                      String description =
                          report['description'] ?? "No description";
                      String severity = report['severity'] ?? "low";
                      String status = report['status'] ?? "pending";
                      String imageUrl = report['image_url'] ?? "";

                      return Dismissible(
                        key: Key(reports[index].id),
                        direction: DismissDirection.endToStart,

                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Report"),
                              content: const Text(
                                  "Are you sure you want to delete this report?"),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel")),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Delete")),
                              ],
                            ),
                          );
                        },

                        onDismissed: (direction) {
                          deleteReport(reports[index].id, imageUrl);
                        },

                        child: _reportCard(
                          description,
                          severity,
                          status,
                          imageUrl,
                          reports[index].id,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            /// BOTTOM ACTIONS
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Bulk Delete"),
                            content: const Text(
                                "Delete all resolved reports permanently?"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel")),
                              TextButton(
                                onPressed: () {
                                  deleteResolvedReports();
                                  Navigator.pop(context);
                                },
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            "Delete Resolved",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B61FF), Color(0xFF5A4CFF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.map, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MapReportsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// STAT CARD
  Widget _statCard(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  /// REPORT CARD
  Widget _reportCard(
      String desc, String severity, String status, String imageUrl, String docId) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(desc,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),

          const SizedBox(height: 10),

          /// BADGES
          Row(
            children: [
              _badge(severity, _severityColor(severity), _severityIcon(severity)),
              const SizedBox(width: 8),
              _badge(status, _statusColor(status), _statusIcon(status)),
            ],
          ),

          const SizedBox(height: 12),

          if (imageUrl.isNotEmpty)
            TextButton(
              onPressed: () => openImage(imageUrl),
              child: const Text("View Image"),
            ),

          DropdownButton<String>(
            value: status,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: "pending", child: Text("Pending")),
              DropdownMenuItem(value: "in progress", child: Text("In Progress")),
              DropdownMenuItem(value: "resolved", child: Text("Resolved")),
            ],
            onChanged: (value) {
              FirebaseFirestore.instance
                  .collection("reports")
                  .doc(docId)
                  .update({"status": value});
            },
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "resolved":
        return Colors.green;
      case "in progress":
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case "resolved":
        return Icons.check_circle;
      case "in progress":
        return Icons.build_circle;
      default:
        return Icons.pending;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case "high":
        return Icons.priority_high;
      case "medium":
        return Icons.warning;
      default:
        return Icons.low_priority;
    }
  }
}