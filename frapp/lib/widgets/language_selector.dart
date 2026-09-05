import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../services/language_service.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final LanguageService _languageService = GetIt.I<LanguageService>();
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _languageService.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Language'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _languageService.supportedLanguages.length,
          itemBuilder: (context, index) {
            final code = _languageService.supportedLanguages.keys.elementAt(index);
            final name = _languageService.supportedLanguages.values.elementAt(index);
            
            return ListTile(
              title: Text(name),
              leading: Radio<String>(
                value: code,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
              trailing: code == _selectedLanguage
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            _languageService.setLanguage(_selectedLanguage);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Language changed to ${_languageService.getLanguageName(_selectedLanguage)}'),
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}