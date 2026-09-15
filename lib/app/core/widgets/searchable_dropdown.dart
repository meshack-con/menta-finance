import 'package:flutter/material.dart';

import '../../modules/rulers/models/lookup_option.dart';
import '../theme/app_colors.dart';

/// Dropdown inayoweza ku-search - kwa orodha ndefu (mfano Matawi) badala
/// ya DropdownButtonFormField ya kawaida isiyo na search.
///
/// NB: Awali hii ilitumia Flutter's Autocomplete, ambayo haionyeshi orodha
/// mpaka mtumiaji aanze KUANDIKA (kubofya tu bila kuandika hakuonyeshi
/// chochote) - kuliwapa watumiaji hisia kwamba "chaguo hazipo". Sasa
/// inafungua dialog inayoonyesha ORODHA YOTE MARA MOJA unapobofya, na
/// TextField ya search juu yake - hakikisho la uhakika zaidi.
class SearchableDropdown extends StatelessWidget {
  final String label;
  final List<LookupOption> options;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String hint;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint = 'Tafuta na uchague...',
  });

  String get _selectedLabel {
    for (final o in options) {
      if (o.id == value) return o.name;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: options.isEmpty ? 'Inapakia... (au hakuna chaguo bado)' : hint,
          suffixIcon: const Icon(Icons.search, size: 18),
        ),
        child: Text(_selectedLabel.isEmpty ? '' : _selectedLabel, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    final searchCtrl = TextEditingController();
    final filtered = ValueNotifier<List<LookupOption>>(options);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(label),
          content: SizedBox(
            width: 380,
            height: 420,
            child: Column(
              children: [
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Tafuta...', prefixIcon: Icon(Icons.search, size: 18)),
                  onChanged: (q) {
                    filtered.value = options.where((o) => o.name.toLowerCase().contains(q.toLowerCase())).toList();
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ValueListenableBuilder<List<LookupOption>>(
                    valueListenable: filtered,
                    builder: (context, list, _) {
                      if (options.isEmpty) {
                        return const Center(child: Text('Hakuna chaguo lililopatikana bado.', style: TextStyle(color: AppColors.textSecondary)));
                      }
                      if (list.isEmpty) {
                        return const Center(child: Text('Hakuna matokeo.', style: TextStyle(color: AppColors.textSecondary)));
                      }
                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final o = list[i];
                          return ListTile(
                            title: Text(o.name),
                            onTap: () {
                              onChanged(o.id);
                              Navigator.of(dialogContext).pop();
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Funga')),
          ],
        );
      },
    );
  }
}
