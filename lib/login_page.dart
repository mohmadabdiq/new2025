import 'package:flutter/material.dart';
import 'main.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login(BuildContext context) {
    // هنا يمكنك تحديد اسم المستخدم وكلمة المرور الثابتة
    final validUsername = 'mohmadabdiq';
    final validPassword = 'mohMAD123';

    if (usernameController.text == validUsername &&
        passwordController.text == validPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بيانات الدخول غير صحيحة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تسجيل الدخول')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'اسم المستخدم')),
            TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => login(context), child: Text('دخول')),
          ],
        ),
      ),
    );
  }
}
