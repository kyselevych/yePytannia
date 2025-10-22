import 'package:flutter/material.dart';

class JoinClassDialog extends StatefulWidget {
  const JoinClassDialog({super.key});

  @override
  State<JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends State<JoinClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accessCodeController = TextEditingController();

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }

  void _joinClass() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_accessCodeController.text.trim().toUpperCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Приєднатися до класу'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _accessCodeController,
              decoration: const InputDecoration(
                labelText: 'Код доступу',
                hintText: 'Введіть 6-символьний код',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Будь ласка, введіть код доступу';
                }
                if (value.trim().length != 6) {
                  return 'Код доступу має бути 6 символів';
                }
                return null;
              },
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              onChanged: (value) {

                final cursorPosition = _accessCodeController.selection.start;
                _accessCodeController.value = _accessCodeController.value.copyWith(
                  text: value.toUpperCase(),
                  selection: TextSelection.collapsed(offset: cursorPosition),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Попросіть у вчителя 6-символьний код доступу для приєднання до класу.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          onPressed: _joinClass,
          child: const Text('Приєднатися'),
        ),
      ],
    );
  }
}