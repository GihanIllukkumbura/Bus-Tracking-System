import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clients/Methods/commen_methods.dart';
import 'package:clients/screens/user_home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  bool _isLogin = true;
  String _enteredEmail = '';
  String _enteredPassword = '';
  String _confirmPassword = '';
  final CommenMethods cMethods = CommenMethods();

  void checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    _form.currentState!.save();

    if (!_isLogin && _enteredPassword != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    try {
      if (_isLogin) {
        await _loginUser();
      } else {
        await _registerUser();
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Authentication failed.')),
      );
    }
  }

  Future<void> _loginUser() async {
    final userCredential = await _firebase.signInWithEmailAndPassword(
      email: _enteredEmail,
      password: _enteredPassword,
    );

    final user = userCredential.user;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = docSnapshot.data();
      if (userData != null && userData['role'] == 'user') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserHome()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You do not have access to this area.'),
              duration: Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _registerUser() async {
    final userCredentials = await _firebase.createUserWithEmailAndPassword(
      email: _enteredEmail,
      password: _enteredPassword,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredentials.user!.uid)
        .set({
      'username': '',
      'email': _enteredEmail,
      'role': 'user', // Set default role to 'user'
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration successful.')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Color.fromARGB(255, 25, 171, 120),
              Color.fromARGB(255, 105, 121, 99),
              Color.fromARGB(255, 171, 111, 20),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 80),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/sltb.png',
                    height: 50, // Adjust the height as needed
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Text(
                      _isLogin ? "Login" : "Signup",
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1300),
                    child: const Text(
                      "Welcome ",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 60),
                        FadeInUp(
                          duration: const Duration(milliseconds: 1400),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(225, 95, 27, .3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                )
                              ],
                            ),
                            child: Form(
                              key: _form,
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey.shade200),
                                      ),
                                    ),
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        hintText: "Email",
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      autocorrect: false,
                                      textCapitalization:
                                          TextCapitalization.none,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty ||
                                            !value.contains('@')) {
                                          return 'Please enter a valid email address.';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        _enteredEmail = value!;
                                      },
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey.shade200),
                                      ),
                                    ),
                                    child: TextFormField(
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        hintText: "Password",
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().length < 6) {
                                          return 'Password must be at least 6 characters long.';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        _enteredPassword = value!;
                                      },
                                    ),
                                  ),
                                  if (!_isLogin)
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: TextFormField(
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          hintText: "Confirm Password",
                                          hintStyle:
                                              TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().length < 6) {
                                            return 'Password not matching.';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          _confirmPassword = value!;
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // FadeInUp(
                        //   duration: const Duration(milliseconds: 1500),
                        //   child: const Text(
                        //     "Forgot Password?",
                        //     style: TextStyle(color: Colors.grey),
                        //   ),
                        // ),
                        FadeInUp(
                          duration: const Duration(milliseconds: 1600),
                          child: MaterialButton(
                            onPressed: _submit,
                            height: 50,
                            color: Colors.orange[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Center(
                              child: Text(
                                _isLogin ? "Login" : "Signup",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Create an account'
                                : 'I already have an account',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}