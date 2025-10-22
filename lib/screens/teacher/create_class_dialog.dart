import 'package:flutter/material.dart';

class CreateClassDialog extends StatefulWidget {
  const CreateClassDialog({super.key});

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  void _createClass() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_classNameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Створити новий клас'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _classNameController,
              decoration: const InputDecoration(
                labelText: 'Назва класу',
                hintText: 'напр.: Математика 10-А',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Будь ласка, введіть назву класу';
                }
                if (value.trim().length < 3) {
                  return 'Назва класу має бути не менше 3 символів';
                }
                return null;
              },
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text(
              'Унікальний код доступу буде створено для учнів, щоб приєднатися до класу.',
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
          onPressed: _createClass,
          child: const Text('Створити'),
        ),
      ],
    );
  }
}