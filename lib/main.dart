import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(SecurePassGenApp());
}

class SecurePassGenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecurePassGen',
      theme: ThemeData.dark(),
      home: PasswordGeneratorPage(),
    );
  }
}

class PasswordGeneratorPage extends StatefulWidget {
  @override
  _PasswordGeneratorPageState createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  double _passwordLength = 12;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  String _generatedPassword = '';

  // New: strength state
  double _passwordStrength = 0;
  String _passwordStrengthLabel = 'Too Weak';

  String _generatePassword() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

    String chars = '';
    if (_includeUppercase) chars += upper;
    if (_includeLowercase) chars += lower;
    if (_includeNumbers) chars += numbers;
    if (_includeSymbols) chars += symbols;

    if (chars.isEmpty) return 'Select at least one option.';

    return List.generate(
      _passwordLength.toInt(),
      (index) => chars[Random.secure().nextInt(chars.length)],
    ).join('');
  }

  // New: computes strength score and label
  void _updateStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.15;

    setState(() {
      _passwordStrength = strength.clamp(0, 1);
      if (_passwordStrength < 0.3) {
        _passwordStrengthLabel = 'Too Weak';
      } else if (_passwordStrength < 0.6) {
        _passwordStrengthLabel = 'Weak';
      } else if (_passwordStrength < 0.85) {
        _passwordStrengthLabel = 'Strong';
      } else {
        _passwordStrengthLabel = 'Very Strong';
      }
    });
  }

  void _onGenerate() {
    final pwd = _generatePassword();
    setState(() {
      _generatedPassword = pwd;
    });
    _updateStrength(pwd); // New: update meter
  }

  void _copyToClipboard() {
    if (_generatedPassword.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedPassword));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Copied to clipboard!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SecurePassGen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Password Length: ${_passwordLength.toInt()}'),
            Slider(
              value: _passwordLength,
              min: 8,
              max: 32,
              divisions: 24,
              label: _passwordLength.toInt().toString(),
              onChanged: (val) {
                setState(() {
                  _passwordLength = val;
                });
              },
            ),
            CheckboxListTile(
              value: _includeUppercase,
              onChanged:
                  (val) => setState(() => _includeUppercase = val ?? false),
              title: Text('Include Uppercase Letters'),
            ),
            CheckboxListTile(
              value: _includeLowercase,
              onChanged:
                  (val) => setState(() => _includeLowercase = val ?? false),
              title: Text('Include Lowercase Letters'),
            ),
            CheckboxListTile(
              value: _includeNumbers,
              onChanged:
                  (val) => setState(() => _includeNumbers = val ?? false),
              title: Text('Include Numbers'),
            ),
            CheckboxListTile(
              value: _includeSymbols,
              onChanged:
                  (val) => setState(() => _includeSymbols = val ?? false),
              title: Text('Include Symbols'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onGenerate,
              child: Text('🔐 Generate Password'),
            ),
            SizedBox(height: 20),
            SelectableText(
              _generatedPassword,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_generatedPassword.isNotEmpty) ...[
              IconButton(
                icon: Icon(Icons.copy),
                onPressed: _copyToClipboard,
                tooltip: 'Copy to Clipboard',
              ),
              SizedBox(height: 12),
              // New: strength meter bar
              LinearProgressIndicator(
                value: _passwordStrength,
                minHeight: 10,
                backgroundColor: Colors.red[100],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _passwordStrength < 0.3
                      ? Colors.red
                      : _passwordStrength < 0.6
                      ? Colors.orange
                      : _passwordStrength < 0.85
                      ? Colors.blue
                      : Colors.green,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Strength: $_passwordStrengthLabel',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
