import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('first_time') ?? true;
  runApp(MyApp(isFirstTime: isFirstTime));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: isFirstTime ? SplashScreen() : LoginPage(),
      routes: {
        '/login': (_) => LoginPage(),
        '/register': (_) => RegisterPage(),
        '/home': (_) => HomePage(),
        '/add_note': (_) => AddNotePage(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('first_time', false);
      Navigator.pushReplacementNamed(context, '/login');
    });
    return Scaffold(
      body: Center(child: Text('Welcome to Notes App', style: TextStyle(fontSize: 24))),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool loading = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => loading = true);

    final Uri url = Uri.parse('https://reqres.in/api/login');

    try {
      final response = await http.post(url, body: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final error = jsonDecode(response.body)['error'];
        _showError(error ?? 'Login failed');
      }
    } catch (e) {
      _showError('Network error');
    }
    setState(() => loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (v) => email = v!,
                validator: (v) => v!.contains('@') ? null : 'Invalid email',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (v) => password = v!,
                validator: (v) => v!.length >= 6 ? null : 'Min 6 chars',
              ),
              const SizedBox(height: 20),
              loading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: login, child: Text('Login')),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text('Create account'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '', email = '', password = '';
  bool loading = false;

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => loading = true);

    final Uri url = Uri.parse('https://reqres.in/api/register');

    try {
      final response = await http.post(url, body: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registered! Please login.')));
      } else {
        final error = jsonDecode(response.body)['error'];
        _showError(error ?? 'Registration failed');
      }
    } catch (e) {
      _showError('Network error');
    }

    setState(() => loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                onSaved: (v) => name = v!,
                validator: (v) => v!.isNotEmpty ? null : 'Required',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (v) => email = v!,
                validator: (v) => v!.contains('@') ? null : 'Invalid email',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (v) => password = v!,
                validator: (v) => v!.length >= 6 ? null : 'Min 6 chars',
              ),
              const SizedBox(height: 20),
              loading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: register, child: Text('Register')),
            ],
          ),
        ),
      ),
    );
  }
}

// Local Notes Storage
List<Map<String, String>> notes = [];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notes')),
      body: notes.isEmpty
          ? Center(child: Text('No notes found'))
          : ListView.builder(
        itemCount: notes.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(notes[i]['title'] ?? ''),
          subtitle: Text(notes[i]['description'] ?? ''),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_note'),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _formKey = GlobalKey<FormState>();
  String title = '', description = '';

  void saveNote() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    notes.add({'title': title, 'description': description});
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                onSaved: (v) => title = v!,
                validator: (v) => v!.isNotEmpty ? null : 'Required',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 5,
                onSaved: (v) => description = v!,
                validator: (v) => v!.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: saveNote, child: Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
