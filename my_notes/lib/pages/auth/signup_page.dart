import 'package:flutter/material.dart';
import 'package:my_notes/providers/auth_provider.dart';
import 'package:my_notes/widgets/button_widget.dart';
import 'package:my_notes/widgets/input_widget.dart';
import 'package:my_notes/widgets/info_container.dart';
import 'package:provider/provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Input alanlarına listener ekle - kullanıcı yazmaya başladığında hata mesajını temizle
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _nameController.addListener(_clearError);
  }
  
  void _clearError() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.errorMessage != null) {
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          authProvider.clearErrorMessage();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
      ),
      body:  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InputWidget(controller: _nameController, hintText: 'Name'),
          SizedBox(height: size.height * 0.02),
          InputWidget(controller: _emailController, hintText: 'Email'),
          SizedBox(height: size.height * 0.02),
          InputWidget(controller: _passwordController, hintText: 'Password'),
          SizedBox(height: size.height * 0.02),
          // Hata mesajını göster - sadece gerçekten hata varsa
          if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty)
            InfoContainer(
              size: size,
              color: Colors.red[100]!,
              message: authProvider.errorMessage!,
              textColor: Colors.red[800]!,
            ),
          ButtonWidget(
            text: authProvider.isLoading ? 'Kayıt Olunuyor...' : 'Signup', 
            onPressed: authProvider.isLoading ? null : () async {
              await authProvider.signUp(_emailController.text, _passwordController.text);
              
              // Kayıt başarılı ise login sayfasına git
              if (authProvider.user != null && mounted) {
                Navigator.pushNamed(context, '/login');
              }
            }, 
            color: Colors.blue, 
            textColor: Colors.white, 
            width: size.width * 0.8, 
            height: size.height * 0.07,
          ),
        ],
      ),
    );
  }
}
