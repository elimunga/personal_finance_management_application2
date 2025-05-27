import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = 'USD';
  String _selectedDateFormat = 'MMM dd, yyyy';
  late Future<SharedPreferences> _prefs;

  final List<String> _currencies = [
    'USD',
    'KES',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
  ];

  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'KES': 'KSh',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  final List<String> _dateFormats = [
    'MMM dd, yyyy',
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy-MM-dd',
  ];

  @override
  void initState() {
    super.initState();
    _prefs = SharedPreferences.getInstance();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefs;
    setState(() {
      _selectedCurrency = prefs.getString('currency') ?? 'USD';
      _selectedDateFormat = prefs.getString('dateFormat') ?? 'MMM dd, yyyy';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await _prefs;
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setString('dateFormat', _selectedDateFormat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Currency Settings
          ListTile(
            title: const Text('Currency'),
            subtitle: Text('${_selectedCurrency} (${_currencySymbols[_selectedCurrency]})'),
            leading: const Icon(Icons.attach_money),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Currency'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _currencies
                        .map(
                          (currency) => ListTile(
                            title: Text('$currency (${_currencySymbols[currency]})'),
                            onTap: () {
                              setState(() => _selectedCurrency = currency);
                              _saveSettings();
                              Navigator.pop(context);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          // Date Format Settings
          ListTile(
            title: const Text('Date Format'),
            subtitle: Text(_selectedDateFormat),
            leading: const Icon(Icons.calendar_today),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Date Format'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _dateFormats
                        .map(
                          (format) => ListTile(
                            title: Text(format),
                            onTap: () {
                              setState(() => _selectedDateFormat = format);
                              _saveSettings();
                              Navigator.pop(context);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          // App Version
          const ListTile(
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
            leading: Icon(Icons.info),
          ),
          const Divider(),
          // About
          ListTile(
            title: const Text('About'),
            subtitle: const Text('PennyWise - Personal Finance Management'),
            leading: const Icon(Icons.description),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'PennyWise',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 64),
                children: const [
                  Text(
                    'PennyWise is a personal finance management app that helps you track your expenses, set budgets, and achieve your savings goals.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
} 