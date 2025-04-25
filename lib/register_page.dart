import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void register(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', usernameController.text);
    await prefs.setString('password', passwordController.text);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء الحساب')));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إنشاء حساب')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'اسم المستخدم')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'كلمة المرور'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () => register(context), child: Text('تسجيل')),
          ],
        ),
      ),
    );
  }
}