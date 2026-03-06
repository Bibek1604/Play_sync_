import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/tournament_entity.dart';
import '../providers/tournament_notifier.dart';
import '../../../../core/widgets/back_button_widget.dart';

/// Create or edit a tournament.
class CreateTournamentPage extends ConsumerStatefulWidget {
  /// If non-null, we're editing an existing tournament.
  final TournamentEntity? existingTournament;

  const CreateTournamentPage({super.key, this.existingTournament});

  @override
  ConsumerState<CreateTournamentPage> createState() =>
      _CreateTournamentPageState();
}

class _CreateTournamentPageState extends ConsumerState<CreateTournamentPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _maxPlayersCtrl;
  late final TextEditingController _entryFeeCtrl;
  late final TextEditingController _prizeCtrl;
  late final TextEditingController _rulesCtrl;
  late final TextEditingController _gameCtrl;

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'offline';

  bool get _isEditing => widget.existingTournament != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTournament;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _maxPlayersCtrl =
        TextEditingController(text: t?.maxPlayers.toString() ?? '10');
    _entryFeeCtrl =
        TextEditingController(text: t?.entryFee.toString() ?? '');
    _prizeCtrl = TextEditingController(text: t?.prize ?? '');
    _rulesCtrl = TextEditingController(text: t?.rules ?? '');
    _gameCtrl = TextEditingController(text: t?.game ?? '');
    _startDate = t?.startDate;
    _endDate = t?.endDate;
    _selectedType = t?.type ?? 'offline';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _maxPlayersCtrl.dispose();
    _entryFeeCtrl.dispose();
    _prizeCtrl.dispose();
    _rulesCtrl.dispose();
    _gameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: BackButtonWidget(label: 'Back'),
        ),
        leadingWidth: 100,
        title: Text(_isEditing ? 'Edit Tournament' : 'Create Tournament'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tournament Name *',
                  prefixIcon: Icon(Icons.emoji_events),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Type dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tournament Type *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'offline', child: Text('Offline')),
                  DropdownMenuItem(value: 'online', child: Text('Online')),
                ],
                onChanged: (v) => setState(() => _selectedType = v ?? 'offline'),
              ),
              const SizedBox(height: 16),

              // Game
              TextFormField(
                controller: _gameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Game Name',
                  prefixIcon: Icon(Icons.sports_esports),
                ),
              ),
              const SizedBox(height: 16),

              // Max Players
              TextFormField(
                controller: _maxPlayersCtrl,
                decoration: const InputDecoration(
                  labelText: 'Max Players *',
                  prefixIcon: Icon(Icons.groups),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 2) return 'Min 2 players';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Entry Fee
              TextFormField(
                controller: _entryFeeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Entry Fee (Rs.)',
                  prefixIcon: Icon(Icons.monetization_on),
                  hintText: '0 for free',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Prize
              TextFormField(
                controller: _prizeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Prize',
                  prefixIcon: Icon(Icons.card_giftcard),
                  hintText: 'e.g. Rs. 5000 for winner',
                ),
              ),
              const SizedBox(height: 16),

              // Start date
              _DatePickerField(
                label: 'Start Date & Time',
                value: _startDate,
                onPicked: (d) => setState(() => _startDate = d),
              ),
              const SizedBox(height: 16),

              // End date
              _DatePickerField(
                label: 'End Date & Time',
                value: _endDate,
                onPicked: (d) => setState(() => _endDate = d),
              ),
              const SizedBox(height: 16),

              // Rules
              TextFormField(
                controller: _rulesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rules',
                  prefixIcon: Icon(Icons.rule),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Error message
              if (state.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(state.error!,
                      style: TextStyle(color: AppColors.error)),
                ),

              // Submit
              FilledButton.icon(
                onPressed: state.isLoading ? null : _submit,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(
                  state.isLoading
                      ? 'Saving...'
                      : _isEditing
                          ? 'Update Tournament'
                          : 'Create Tournament',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'type': _selectedType,
      'maxPlayers': int.tryParse(_maxPlayersCtrl.text) ?? 10,
      if (_entryFeeCtrl.text.isNotEmpty)
        'entryFee': double.tryParse(_entryFeeCtrl.text) ?? 0,
      if (_prizeCtrl.text.isNotEmpty) 'prize': _prizeCtrl.text.trim(),
      if (_gameCtrl.text.isNotEmpty) 'game': _gameCtrl.text.trim(),
      if (_rulesCtrl.text.isNotEmpty) 'rules': _rulesCtrl.text.trim(),
      if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
      if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
    };

    final notifier = ref.read(tournamentProvider.notifier);
    bool success;

    if (_isEditing) {
      success =
          await notifier.updateTournament(widget.existingTournament!.id, data);
    } else {
      success = await notifier.createTournament(data);
    }

    if (success && mounted) Navigator.pop(context, true);
  }
}

// ── Date Picker Field ───────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy • h:mm a');

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null || !context.mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
        );
        if (time == null) return;

        onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onPicked(DateTime.now()),
                )
              : null,
        ),
        child: Text(
          value != null ? df.format(value!) : 'Tap to select',
          style: TextStyle(
            color: value != null ? null : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
