import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../state/profile_store.dart';
import '../theme.dart';
import '../widgets/basics.dart';

enum _Mode { pick, manage, edit }

/// "Who's watching?": pick, add, edit or delete profiles, or carry on as a
/// guest. Profiles are optional.
class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key, this.onDone});

  /// Set when this is the first screen at launch: called once a choice is
  /// made. When null the screen was opened on top of the app and just closes.
  final VoidCallback? onDone;

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  _Mode _mode = _Mode.pick;
  Profile? _editing; // null while adding a new profile
  int _draftAvatar = 0;
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _finish() {
    final onDone = widget.onDone;
    if (onDone != null) {
      onDone();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _choose(Profile? profile) {
    store.setActive(profile);
    _finish();
  }

  void _startEdit(Profile? profile) {
    setState(() {
      _mode = _Mode.edit;
      _editing = profile;
      _draftAvatar = profile?.avatar ?? store.freeAvatar(avatarColors.length);
      _name.text = profile?.name ?? '';
      _error = null;
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty || store.nameTaken(name, except: _editing)) {
      setState(() {
        _error = name.isEmpty ? 'Enter a name for this profile.' : 'There is already a profile with that name.';
      });
      return;
    }
    FocusScope.of(context).unfocus();

    final editing = _editing;
    if (editing != null) {
      store.update(editing, name, _draftAvatar);
      setState(() => _mode = _Mode.manage);
    } else {
      _choose(store.create(name, _draftAvatar)); // a new profile is used straight away
    }
  }

  Future<void> _delete() async {
    final profile = _editing;
    if (profile == null) return;
    final yes = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialog) => CupertinoAlertDialog(
        title: Text('Delete “${profile.name}”?'),
        content: const Text("Everything saved on this profile will be deleted. This can't be undone."),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    store.delete(profile);
    setState(() => _mode = store.profiles.isEmpty ? _Mode.pick : _Mode.manage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Image.asset('assets/fakeflix-logo.png', height: 22),
                  const Spacer(),
                  if (widget.onDone == null)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: ListenableBuilder(
                    listenable: store,
                    builder: (context, _) => _mode == _Mode.edit ? _form() : _picker(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _picker() {
    final managing = _mode == _Mode.manage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          managing ? 'Manage Profiles' : "Who's watching?",
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final profile in store.profiles)
              _Tile(
                name: profile.name,
                onTap: () => managing ? _startEdit(profile) : _choose(profile),
                art: Stack(
                  fit: StackFit.expand,
                  children: [
                    Avatar.of(profile, size: 96, radius: 6),
                    if (managing)
                      Container(
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(CupertinoIcons.pencil, size: 34, color: Colors.white),
                      ),
                  ],
                ),
              ),
            if (store.profiles.length < ProfileStore.maxProfiles)
              _Tile(
                name: 'Add Profile',
                onTap: () => _startEdit(null),
                art: const Icon(Icons.add_rounded, size: 56, color: AppColors.dim),
              ),
          ],
        ),
        const SizedBox(height: 26),
        const Text(
          'Profiles are optional. Each one keeps its own list, likes, watch history and Continue Watching, stored only on this device.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.dim, fontSize: 13.5, height: 1.5),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: managing
              ? [GhostButton(label: 'Done', solid: true, onTap: () => setState(() => _mode = _Mode.pick))]
              : [
                  if (store.profiles.isNotEmpty)
                    GhostButton(label: 'Manage Profiles', onTap: () => setState(() => _mode = _Mode.manage)),
                  GhostButton(label: 'Continue as guest', onTap: () => _choose(null)),
                ],
        ),
      ],
    );
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _editing == null ? 'Add Profile' : 'Edit Profile',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 26),
        Avatar(colorIndex: _draftAvatar, size: 96, radius: 6),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: TextField(
            controller: _name,
            maxLength: 20,
            autocorrect: false,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            cursorColor: Colors.white,
            style: const TextStyle(fontSize: 17, color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Name',
              hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
              counterText: '',
              filled: true,
              fillColor: Color(0xFF666666),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < avatarColors.length; i++)
              GestureDetector(
                onTap: () => setState(() => _draftAvatar = i),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: avatarColors[i],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: i == _draftAvatar ? Colors.white : Colors.transparent, width: 2),
                  ),
                ),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13.5)),
        ],
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            GhostButton(label: 'Save', solid: true, onTap: _save),
            GhostButton(
              label: 'Cancel',
              onTap: () => setState(() => _mode = _editing == null ? _Mode.pick : _Mode.manage),
            ),
            if (_editing != null) GhostButton(label: 'Delete Profile', danger: true, onTap: _delete),
          ],
        ),
      ],
    );
  }
}

/// A profile square with its name underneath.
class _Tile extends StatelessWidget {
  const _Tile({required this.name, required this.art, required this.onTap});
  final String name;
  final Widget art;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 96, height: 96, child: art),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
