import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ==============================
// DEVELOPER DETAILS DIALOG
// ==============================

void showDeveloperDialog(BuildContext context) {
  final size = MediaQuery.of(context).size;

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.width / 18,
            vertical: size.height / 40,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size.width / 18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: size.height / 80),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.width / 25),
                  gradient: const LinearGradient(
                    colors: [Color(0xff667eea), Color(0xff764ba2)],
                  ),
                ),
                child: Center(
                  child: Text(
                    "Developer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width / 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height / 40),

              // PROFILE AVATAR
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber,
                    width: size.width / 120,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: size.width / 10,
                  backgroundColor: Colors.black87,
                  child: Icon(
                    Icons.person,
                    size: size.width / 10,
                    color: Colors.white,
                  ),
                ),
              ),

              SizedBox(height: size.height / 60),

              // NAME
              Text(
                "Daksh",
                style: TextStyle(
                  fontSize: size.width / 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: size.height / 200),

              // ROLE
              Text(
                "Flutter Developer",
                style: TextStyle(
                  fontSize: size.width / 26,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: size.height / 30),

              // SOCIAL ICONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialIcon(
                    size: size,
                    icon: Icons.code,
                    color: Colors.black,
                    url: 'https://github.com/heydaksh',
                  ),
                  _buildSocialIcon(
                    size: size,
                    icon: Icons.work,
                    color: Colors.blue,
                    url: 'https://www.linkedin.com/in/daksh-suthar/',
                  ),
                  _buildSocialIcon(
                    size: size,
                    icon: Icons.web,
                    color: Colors.redAccent,
                    url: 'https://daksh-portfolio-2025.web.app/',
                  ),
                ],
              ),

              SizedBox(height: size.height / 30),

              // CLOSE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: size.height / 70),
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(size.width / 30),
                    ),
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      fontSize: size.width / 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildSocialIcon({
  required Size size,
  required IconData icon,
  required Color color,
  required String url,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(size.width / 10),
    onTap: () async {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('🌐 Opened URL: $url');
      } else {
        debugPrint('❌ Could not launch $url');
      }
    },
    child: Container(
      padding: EdgeInsets.all(size.width / 35),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: size.width / 250,
        ),
      ),
      child: Icon(icon, color: color, size: size.width / 16),
    ),
  );
}
