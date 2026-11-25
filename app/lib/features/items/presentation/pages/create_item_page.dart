import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../bloc/items_bloc.dart';

class CreateItemPage extends StatelessWidget {
  const CreateItemPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ItemsBloc>(),
    child: const _CreateItemView(),
  );
}

class _CreateItemView extends StatefulWidget {
  const _CreateItemView();
  @override
  State<_CreateItemView> createState() => _CreateItemViewState();
}

class _CreateItemViewState extends State<_CreateItemView> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController(),
      _location = TextEditingController(),
      _proof = TextEditingController();
  String _category = 'BAGS', _type = 'FOUND';
  final _imagePicker = ImagePicker();
  Uint8List? _photoBytes;
  String? _photoData;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _proof.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<ItemsBloc, ItemsState>(
    listenWhen: (a, b) =>
        a.createdItem?.id != b.createdItem?.id && b.createdItem != null ||
        a.failure != b.failure && b.failure != null,
    listener: (context, state) {
      if (state.createdItem != null) {
        context.go('/items/${state.createdItem!.id}');
      }
      if (state.failure != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.failure!.message)));
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Nouvelle annonce')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            Text(
              'Aidez la bonne personne à retrouver son objet.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'FOUND',
                  label: Text('J’ai trouvé'),
                  icon: Icon(Icons.add_location_alt_outlined),
                ),
                ButtonSegment(
                  value: 'LOST',
                  label: Text('J’ai perdu'),
                  icon: Icon(Icons.search),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 18),
            _photoPicker(context),
            const SizedBox(height: 18),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nom de l’objet',
                hintText: 'Ex. Sac à dos noir',
                errorText: _validationError(context, 'title'),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ajoutez un titre.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Couleur, marque, détails distinctifs…',
                errorText: _validationError(context, 'description'),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Décrivez l’objet.' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: 'Catégorie',
                errorText: _validationError(context, 'category'),
              ),
              items: const [
                DropdownMenuItem(value: 'BAGS', child: Text('Sacs et bagages')),
                DropdownMenuItem(
                  value: 'ELECTRONICS',
                  child: Text('Électronique'),
                ),
                DropdownMenuItem(value: 'CLOTHING', child: Text('Vêtements')),
                DropdownMenuItem(value: 'KEYS', child: Text('Clés')),
                DropdownMenuItem(value: 'OTHER', child: Text('Autre')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Lieu',
                prefixIcon: const Icon(Icons.place_outlined),
                hintText: 'Ex. Bibliothèque, 2e étage',
                errorText: _validationError(context, 'location'),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Indiquez le lieu.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _proof,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Question de vérification (conseillé)',
                hintText: 'Ex. Que contenait la poche avant ?',
                errorText: _validationError(context, 'proofQuestion'),
              ),
              validator: (v) =>
                  _type == 'FOUND' && (v == null || v.trim().isEmpty)
                  ? 'Ajoutez une question pour vérifier les réclamations.'
                  : null,
            ),
            const SizedBox(height: 22),
            BlocBuilder<ItemsBloc, ItemsState>(
              builder: (context, state) => FilledButton.icon(
                onPressed: state.saving
                    ? null
                    : () {
                        if (!_form.currentState!.validate()) return;
                        context.read<ItemsBloc>().add(
                          ItemCreated(
                            title: _title.text.trim(),
                            description: _description.text.trim(),
                            category: _category,
                            location: _location.text.trim(),
                            type: _type,
                            proofQuestion: _proof.text.trim().isEmpty
                                ? null
                                : _proof.text.trim(),
                            imageData: _photoData,
                          ),
                        );
                      },
                icon: state.saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_outlined),
                label: Text(
                  state.saving ? 'Publication…' : 'Publier l’annonce',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _photoPicker(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Photo de l’objet',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      if (_photoBytes case final bytes?)
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 190,
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton.filledTonal(
                  tooltip: 'Retirer la photo',
                  onPressed: () => setState(() {
                    _photoBytes = null;
                    _photoData = null;
                  }),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        )
      else
        InkWell(
          onTap: () => _showPhotoSource(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffdce5df)),
            ),
            child: const Column(
              children: [
                Icon(Icons.add_a_photo_outlined, size: 28),
                SizedBox(height: 7),
                Text('Ajouter une photo'),
                SizedBox(height: 3),
                Text(
                  'Facultatif · JPEG, PNG ou WebP',
                  style: TextStyle(fontSize: 12, color: Color(0xff68736e)),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Future<void> _showPhotoSource(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickPhoto(source);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 65,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final extension = file.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final data = 'data:$mimeType;base64,${base64Encode(bytes)}';
      if (data.length > 800000) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo trop volumineuse. Choisissez une image plus légère.'),
          ),
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _photoData = data;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir cette photo.')),
      );
    }
  }
}

String? _validationError(BuildContext context, String field) {
  final failure = context.watch<ItemsBloc>().state.failure;
  return failure is ValidationFailure ? failure.fields[field] : null;
}
