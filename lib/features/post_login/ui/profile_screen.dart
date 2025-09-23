// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:ekatalog_etm/utils/avatar_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _avatarPath;
  Color _bgColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await AvatarManager.loadAvatarInfo();
    setState(() {
      _avatarPath = info?.filePath;
      _bgColor = info != null ? Color(info.bgColor) : Colors.transparent;
    });
  }

  @override
  Widget build(BuildContext context) {
final auth = Provider.of<AuthService>(context);
final ownerName = auth.owner != null
        ? (auth.owner!['owner_name']?.toString() ?? 'User')
        : 'Guest';
        final phoneNumber = auth.phoneNumber ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), backgroundColor: Colors.red.shade700),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _bgColor, shape: BoxShape.circle),
            child: ClipOval(
              child: _avatarPath == null
                  ? Image.asset('assets/avatar_placeholder.png', width: 160, height: 160, fit: BoxFit.cover)
                  : Image.file(File(_avatarPath!), width: 160, height: 160, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Text(ownerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(phoneNumber, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.pushNamed(context, '/avatar_picker');
              _load(); // reload setelah kembali
            },
            icon: const Icon(Icons.edit),
            label: const Text('Ubah Avatar'),
          ),
          const SizedBox(height: 20),
          ListTile(title: const Text('Nama Lengkap'), subtitle: Text(ownerName), trailing: const Icon(Icons.chevron_right)),
          ListTile(title: const Text('Nomor Handphone'), subtitle: Text(phoneNumber), trailing: const Icon(Icons.chevron_right)),
        ]),
      ),
    );
  }
}
