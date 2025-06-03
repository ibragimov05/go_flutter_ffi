import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'native_bridge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _message = 'Tap the button to call Go function';
  String _additionResult = '';
  bool _isLoading = false;
  final TextEditingController _num1Controller = TextEditingController();
  final TextEditingController _num2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _num1Controller.text = '10';
    _num2Controller.text = '5';
  }

  @override
  void dispose() {
    _num1Controller.dispose();
    _num2Controller.dispose();
    NativeBridge.dispose();
    super.dispose();
  }

  Future<void> _callGoFunction() async {
    setState(() {
      _isLoading = true;
      _message = 'Loading...';
    });

    try {
      // Call the Go function
      final result = NativeBridge.getHelloWorld();
      setState(() {
        _message = result;
        _isLoading = false;
      });
    } on Object catch (e) {
      setState(() {
        _message = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _addNumbers() {
    try {
      final num1 = int.tryParse(_num1Controller.text) ?? 0;
      final num2 = int.tryParse(_num2Controller.text) ?? 0;

      final result = NativeBridge.addTwoNumbers(a: num1, b: num2);

      setState(() => _additionResult = '$num1 + $num2 = $result');
    } on Object catch (_) {
      setState(() => _additionResult = 'Error: Invalid input');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Flutter Go FFI Demo'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hello World Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Hello World from Go', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(_message, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _callGoFunction,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Call Go Function'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Addition Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Add Numbers in Go', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _num1Controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Number 1', border: OutlineInputBorder()),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('+', style: TextStyle(fontSize: 24)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _num2Controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Number 2', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _addNumbers, child: const Text('Add in Go')),
                  const SizedBox(height: 16),
                  if (_additionResult.isNotEmpty)
                    Text(_additionResult, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
