import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'signup_screen.dart'; // We will create this next

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("KIGALI DIRECTORY", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF4A261))),
            const SizedBox(height: 40),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
            const SizedBox(height: 32),
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                return provider.isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF4A261), minimumSize: const Size(double.infinity, 50)),
                            onPressed: () async {
                              final error = await provider.login(emailController.text, passwordController.text);
                              if (error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            },
                            child: const Text("LOGIN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                            child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.white70)),
                          ),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}