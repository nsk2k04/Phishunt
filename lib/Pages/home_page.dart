import 'package:flutter/material.dart';
import 'email_page.dart'; // Import the Email page
import 'sms_page.dart'; // Import the SmsPage

class PhishingDetectionDashboard extends StatefulWidget {
  const PhishingDetectionDashboard({super.key});
  @override
  _PhishingDetectionDashboardState createState() =>
      _PhishingDetectionDashboardState();
}

class _PhishingDetectionDashboardState
    extends State<PhishingDetectionDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RemaindersPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Phishing Detection Dashboard"),
        backgroundColor: Colors.yellow.shade700,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "User Details",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(color: Colors.black54),
                  const SizedBox(height: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserDetailRow(
                          Icons.person, "Username", "JohnDoe123"),
                      _buildUserDetailRow(
                          Icons.email, "Email ID", "johndoe@example.com"),
                      _buildUserDetailRow(
                          Icons.phone, "Phone No", "+91 98765 43210"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildDashboardButton(Icons.sms, "Check SMS", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SmsPage()),
                    );
                  }),
                  _buildDashboardButton(Icons.email_outlined, "Check Email",
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmailPage()),
                    );
                  }),
                  _buildDashboardButton(Icons.report_problem, "Report Threat",
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReportThreatPage()),
                    );
                  }),
                  _buildDashboardButton(Icons.support_agent, "Contact Support",
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ContactSupportPage()),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick Stats",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(Icons.email, "Emails Scanned", "24"),
                      _buildStatItem(Icons.sms, "SMS Scanned", "15"),
                      _buildStatItem(Icons.warning, "Threats Found", "3"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.yellow.shade700,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black54,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        elevation: 10,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Reminders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildUserDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.yellow.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardButton(
      IconData icon, String label, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow.shade700,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.yellow.shade700, size: 30),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Placeholder pages remain unchanged
class CheckPhishingPage extends StatelessWidget {
  const CheckPhishingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Check Phishing")),
      body: const Center(child: Text("Check Phishing Feature Coming Soon!")),
    );
  }
}

class ReportThreatPage extends StatelessWidget {
  const ReportThreatPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Threat")),
      body: const Center(child: Text("Report Threat Feature Coming Soon!")),
    );
  }
}

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contact Support")),
      body: const Center(child: Text("Contact Support Feature Coming Soon!")),
    );
  }
}

class RemaindersPage extends StatelessWidget {
  const RemaindersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Check Urls")),
      body: const Center(child: Text("Reminders Feature Coming Soon!")),
    );
  }
}
