import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/failure_view.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/device_type.dart';
import '../providers/device_providers.dart';

/// Edits the user's own name/type/note and "Bu cihazı tanıyorum".
class DeviceUserInfoDialog extends ConsumerStatefulWidget {
  const DeviceUserInfoDialog({super.key, required this.device});

  final Device device;

  @override
  ConsumerState<DeviceUserInfoDialog> createState() =>
      _DeviceUserInfoDialogState();
}

class _DeviceUserInfoDialogState extends ConsumerState<DeviceUserInfoDialog> {
  static const _maxNameLength = 64;
  static const _maxNoteLength = 1000;

  late final _nameController = TextEditingController(
    text: widget.device.customName ?? '',
  );
  late final _noteController = TextEditingController(
    text: widget.device.note ?? '',
  );
  late DeviceType? _type = widget.device.customType;
  late bool _isKnown = widget.device.isKnown;
  bool _saving = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await ref
          .read(deviceRepositoryProvider)
          .updateUserInfo(
            deviceId: widget.device.id,
            customName: _nameController.text,
            customType: _type,
            note: _noteController.text,
            isKnown: _isKnown,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failure = asAppFailure(error, stackTrace);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    return AlertDialog(
      title: const Text('Cihaz bilgilerini düzenle'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                maxLength: _maxNameLength,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Özel ad',
                  hintText: device.hostname ?? device.currentIp.toString(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DeviceType?>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tür',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      device.inferredType == DeviceType.unknown
                          ? 'Otomatik (Bilinmiyor)'
                          : 'Otomatik (${device.inferredType.label})',
                    ),
                  ),
                  for (final type in DeviceType.values)
                    if (type != DeviceType.unknown)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) => setState(() => _type = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLength: _maxNoteLength,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Not',
                  border: OutlineInputBorder(),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Bu cihazı tanıyorum'),
                value: _isKnown,
                onChanged: (value) => setState(() => _isKnown = value ?? false),
              ),
              if (_failure != null) FailureView(failure: _failure!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
