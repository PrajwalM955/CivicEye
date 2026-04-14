import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_issue_screen.dart';
import 'login_screen.dart';
import 'my_reports_screen.dart';
import 'map_reports_screen.dart';
import 'admin_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    const bg = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: bg,

      /// 🔥 UPDATED FAB (ICON + TEXT)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
          );
        },
        backgroundColor: const Color(0xFF7B61FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Report Issue",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 6,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => logout(context),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                "Welcome to CivicEye 👋",
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 20),

              /// COUNTER CARDS
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("reports")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  int total = docs.length;
                  int resolved = docs
                      .where((doc) => doc['status'] == "resolved")
                      .length;
                  int unresolved = total - resolved;

                  return Row(
                    children: [
                      Expanded(child: _statCard("Total", total, Colors.blue)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard("Resolved", resolved, Colors.green),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard("Pending", unresolved, Colors.orange),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              /// ACTION SECTION TITLE
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              /// ACTION CARDS
              Expanded(
                child: ListView(
                  children: [
                    _actionCard(
                      icon: Icons.list,
                      title: "My Civic Contributions",
                      subtitle: "View your reported issues",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyReportsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    _actionCard(
                      icon: Icons.map,
                      title: "Issues Map",
                      subtitle: "Explore issues around you",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapReportsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    /// ADMIN CARD
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .doc(uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();

                        var data =
                            snapshot.data!.data() as Map<String, dynamic>?;

                        if (data == null) return const SizedBox();

                        if ((data['role'] ?? "citizen") != "admin") {
                          return const SizedBox();
                        }

                        return _actionCard(
                          icon: Icons.admin_panel_settings,
                          title: "Admin Dashboard",
                          subtitle: "Manage reports and users",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminDashboardScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
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

  /// ACTION CARD
  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
