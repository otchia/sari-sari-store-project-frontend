import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFC107),
              Color(0xFFFFB300),
              Color(0xFFFF6F00),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        tooltip: 'Back',
                      ),
                    ),
                  ],
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 32,
                  0,
                  isMobile ? 16 : 32,
                  isMobile ? 16 : 24,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.store,
                        size: isMobile ? 40 : 52,
                        color: const Color(0xFFFF6F00),
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      "Sari-Sari Store",
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Text(
                      "Choose your account type",
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 18,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Cards Section
              Expanded(
                child: Center(
                  child: Container(
                    width: screenWidth > 900 ? 900 : screenWidth * 0.95,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    child: screenWidth > 700
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(child: _buildCustomerCard(context, isMobile: false)),
                              const SizedBox(width: 30),
                              Expanded(child: _buildAdminCard(context, isMobile: false)),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCustomerCard(context, isMobile: isMobile),
                                SizedBox(height: isMobile ? 16 : 20),
                                _buildAdminCard(context, isMobile: isMobile),
                                SizedBox(height: isMobile ? 16 : 20),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, {required bool isMobile}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        elevation: 12,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.orange[50]!],
            ),
          ),
          padding: EdgeInsets.all(isMobile ? 20 : 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 14 : 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFFF6F00)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shopping_bag,
                  size: isMobile ? 36 : 46,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              Text(
                "Customer Portal",
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
              SizedBox(height: isMobile ? 8 : 10),
              Text(
                "Start shopping and track your orders with your personal account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              SizedBox(
                width: double.infinity,
                height: isMobile ? 48 : 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/customer-login');
                  },
                  icon: Icon(Icons.arrow_forward, size: isMobile ? 20 : 22),
                  label: Text(
                    "Continue as Customer",
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.orange.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {required bool isMobile}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        elevation: 12,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.red[50]!],
            ),
          ),
          padding: EdgeInsets.all(isMobile ? 20 : 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 14 : 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.redAccent, Colors.red],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: isMobile ? 36 : 46,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              Text(
                "Admin Portal",
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
              SizedBox(height: isMobile ? 8 : 10),
              Text(
                "Manage your store, products, inventory, and monitor all activities",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              SizedBox(
                width: double.infinity,
                height: isMobile ? 48 : 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin-login');
                  },
                  icon: Icon(Icons.arrow_forward, size: isMobile ? 20 : 22),
                  label: Text(
                    "Continue as Admin",
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.red.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
