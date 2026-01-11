import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';

class AdminCreateGroupScreen extends StatefulWidget {
  const AdminCreateGroupScreen({super.key});

  @override
  State<AdminCreateGroupScreen> createState() => _AdminCreateGroupScreenState();
}

class _AdminCreateGroupScreenState extends State<AdminCreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _groupName = '';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      context.read<AdminService>().createGroup(_groupName);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('createGroup').tr()),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'groupName'.tr(),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group_work),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'pleaseEnter'.tr();
                  }
                  return null;
                },
                onSaved: (value) => _groupName = value!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text('createGroup').tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
