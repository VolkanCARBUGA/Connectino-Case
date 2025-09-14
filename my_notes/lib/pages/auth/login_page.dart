
import 'package:flutter/material.dart';
import 'package:my_notes/providers/auth_provider.dart';
import 'package:my_notes/widgets/button_widget.dart';
import 'package:my_notes/widgets/input_widget.dart';
import 'package:my_notes/widgets/info_container.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Input alanlarına listener ekle - kullanıcı yazmaya başladığında hata mesajını temizle
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _checkAuth();
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
  void _checkAuth() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/notes');
        }
      });
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body:  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
         SizedBox(height: size.height * 0.02),
         ButtonWidget(
           text: authProvider.isLoading ? 'Giriş Yapılıyor...' : 'Login', 
           onPressed: authProvider.isLoading ? null : () async {
             await authProvider.signIn(_emailController.text, _passwordController.text);
             
             // Giriş başarılı ise not sayfasına git
             if (authProvider.user != null && mounted) {
               Navigator.pushReplacementNamed(context, '/notes');
             }
           }, 
           color: Colors.blue, 
           textColor: Colors.white, 
           width: size.width * 0.8, 
           height: size.height * 0.07,
         ),
         SizedBox(height: size.height * 0.02),
         TextButton(onPressed: () {
          Navigator.pushNamed(context, '/signup');
         }, child: Text('Bir hesap oluşturmak ister misiniz?')),
        ],
      ),
    );
  }
}