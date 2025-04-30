import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String errorMessage = '';

  void registerUser() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pop(context); // Go back to login
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Registration failed.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.amber[200]),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'REGISTER ACCOUNT',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: registerUser,
                    child: const Text('Sign up'),
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
