import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    const bg = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reports')
              .where('user_id', isEqualTo: currentUserId)
              .snapshots(),

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(child: Text("No contribution data available"));
            }

            final reports = snapshot.data!.docs;

            int totalReports = reports.length;
            int resolved =
                reports.where((doc) => doc['status'] == "resolved").length;
            int inProgress =
                reports.where((doc) => doc['status'] == "in progress").length;
            int pending =
                reports.where((doc) => doc['status'] == "pending").length;

            final level = (totalReports ~/ 3) + 1;
            final progress = totalReports % 3;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  const Text(
                    "My Contributions",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Level $level • Keep improving your city 🚀",
                    style: const TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 20),

                  /// LEVEL CARD
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_events,
                                color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              "Level $level",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        LinearProgressIndicator(
                          value: progress / 3.0,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF7B61FF),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "${(progress / 3 * 100).round()}% to next level",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// STATS TITLE
                  const Text(
                    "Your Stats",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// STATS GRID
                  Row(
                    children: [
                      Expanded(
                        child: _statCard("Total", totalReports, Colors.blue),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard("Resolved", resolved, Colors.green),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _statCard("In Progress", inProgress, Colors.orange),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard("Pending", pending, Colors.red),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// LIST TITLE
                  const Text(
                    "Breakdown",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// LIST
                  Expanded(
                    child: ListView(
                      children: [
                        _tile("Total Reports", totalReports,
                            Icons.bar_chart, Colors.blue),
                        _tile("Resolved", resolved,
                            Icons.check_circle, Colors.green),
                        _tile("In Progress", inProgress,
                            Icons.timelapse, Colors.orange),
                        _tile("Pending", pending,
                            Icons.pending_actions, Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(height: 6),
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

  Widget _tile(String title, int value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}