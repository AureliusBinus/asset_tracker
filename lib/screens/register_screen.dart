import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:asset_tracker/widgets/my_button.dart';
import 'package:asset_tracker/widgets/my_textfield.dart';
import 'package:asset_tracker/widgets/square_tile.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onTap,
  });

  final void Function() onTap;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void dialogPasswordNotMatch() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Password Not Match'),
          content: Text('Please check your credentials'),
        );
      },
    );
  }

  void showErrorMessage(BuildContext ctx, String error) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong.'),
          content: Text('Reason: $error'),
          actions: [
            ElevatedButton(
              onPressed: Navigator.of(ctx).pop,
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
  }

  void signUp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      if (!mounted) return;
      Navigator.of(context).pop();

      if (emailController.text.isEmpty || usernameController.text.isEmpty) {
        return showErrorMessage(context, 'Email & Username cannot be empty.');
      }

      if (passwordController.text == confirmPasswordController.text) {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        await FirebaseFirestore.instance
            .collection('assets')
            .doc(userCredential.user!.uid)
            .set({
          'username': usernameController.text,
          'email': emailController.text,
        });
      } else {
        dialogPasswordNotMatch();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showErrorMessage(context, e.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Center(
                child: Icon(
                  Icons.lock,
                  size: 60,
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                'Let\'s create an account!',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 25),
              MyTextfield(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
              ),
              const SizedBox(height: 10),
              MyTextfield(
                controller: usernameController,
                hintText: 'Username',
                obscureText: false,
              ),
              const SizedBox(height: 10),
              MyTextfield(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              MyTextfield(
                controller: confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: true,
              ),
              const SizedBox(height: 25),
              MyButton(
                buttonText: 'Sign Up',
                onTap: signUp,
              ),
              const SizedBox(height: 50),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('Or continue with'),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SquareTile(imagePath: 'assets/images/google.png'),
                  SizedBox(width: 25),
                  SquareTile(imagePath: 'assets/images/apple.png'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: widget.onTap,
                    child: const Text(
                      'Login now',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
