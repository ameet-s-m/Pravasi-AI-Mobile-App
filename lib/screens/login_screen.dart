// lib/screens/login_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // To navigate to MainScreen

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.paperplane_fill,
                  size: 80,
                  color: CupertinoColors.systemBlue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to PRAVASI AI',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel),
                ),
                const SizedBox(height: 40),
                const CupertinoTextField(
                  placeholder: 'Email',
                  prefix: Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Icon(CupertinoIcons.mail, color: CupertinoColors.systemGrey),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                const CupertinoTextField(
                  placeholder: 'Password',
                  prefix: Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Icon(CupertinoIcons.lock, color: CupertinoColors.systemGrey),
                  ),
                  obscureText: true,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    child: const Text('Log In'),
                    onPressed: () async {
                      // Save login status for demo - skip login on next launch
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('has_logged_in', true);
                      
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pushReplacement(
                          CupertinoPageRoute(builder: (context) => const MainScreen()),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}