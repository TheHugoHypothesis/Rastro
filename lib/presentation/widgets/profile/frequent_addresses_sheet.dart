import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../providers/app_state_provider.dart';

void showFrequentAddressesSheet({
  required BuildContext context,
  required WidgetRef ref,
  required bool isDark,
  required Color surfaceColor,
  required Color textColor,
  required Color subtextColor,
  required Color borderColor,
  required Color primaryLight,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _FrequentAddressesSheetWidget(
      isDark: isDark,
      surfaceColor: surfaceColor,
      textColor: textColor,
      subtextColor: subtextColor,
      borderColor: borderColor,
      primaryLight: primaryLight,
    ),
  );
}

class _FrequentAddressesSheetWidget extends ConsumerStatefulWidget {
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subtextColor;
  final Color borderColor;
  final Color primaryLight;

  const _FrequentAddressesSheetWidget({
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
    required this.primaryLight,
  });

  @override
  ConsumerState<_FrequentAddressesSheetWidget> createState() =>
      __FrequentAddressesSheetWidgetState();
}

class __FrequentAddressesSheetWidgetState
    extends ConsumerState<_FrequentAddressesSheetWidget> {
  String? _editingId; // 'home', 'work'
  String? _editingLabel; // 'Casa', 'Trabalho'
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _suggestions = [];
        });
        return;
      }
      setState(() {
        _isLoading = true;
      });

      // Busca endereços usando a API Nominatim via RoutingService
      final routingService = ref.read(routingServiceProvider);
      final results = await routingService.searchAddress(query);

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(frequentAddressesProvider);
    final homeAddress = favorites.firstWhere(
      (item) => item['id'] == 'home',
      orElse: () => {},
    );
    final workAddress = favorites.firstWhere(
      (item) => item['id'] == 'work',
      orElse: () => {},
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 20,
        ),
        child: Column(
          children: [
            // Barra de arraste brutalista
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.border : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            if (_editingId == null) ...[
              Text(
                'Endereços Frequentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: widget.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Defina locais frequentes para facilitar as buscas e visualizá-los no mapa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.subtextColor,
                ),
              ),
              const SizedBox(height: 24),

              // Bloco de Casa
              _buildFavoriteItem(
                id: 'home',
                label: 'Casa',
                icon: Icons.home_rounded,
                address: homeAddress,
              ),
              const SizedBox(height: 16),

              // Bloco de Trabalho
              _buildFavoriteItem(
                id: 'work',
                label: 'Trabalho',
                icon: Icons.work_rounded,
                address: workAddress,
              ),
              const SizedBox(height: 32),
            ] else ...[
              // Modo de edição / busca
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: widget.textColor),
                    onPressed: () {
                      setState(() {
                        _editingId = null;
                        _editingLabel = null;
                        _searchCtrl.clear();
                        _suggestions = [];
                      });
                    },
                  ),
                  Text(
                    'Definir $_editingLabel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: widget.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(
                  color: widget.textColor,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Pesquise o endereço...',
                  hintStyle: TextStyle(color: widget.subtextColor),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: widget.isDark
                        ? AppColors.primaryLight
                        : widget.primaryLight,
                  ),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.primaryLight,
                            ),
                          ),
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: widget.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: widget.isDark
                          ? AppColors.primaryLight
                          : widget.primaryLight,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: widget.isDark
                      ? AppColors.cardDark
                      : AppColors.lightSurfaceElevated,
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 12),

              // Lista de sugestões
              Expanded(
                child: _suggestions.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'Digite um endereço acima para buscar'
                              : 'Nenhum endereço encontrado',
                          style: TextStyle(color: widget.subtextColor),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            title: Text(
                              item['title'] ?? '',
                              style: TextStyle(
                                color: widget.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              item['subtitle'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: widget.subtextColor),
                            ),
                            onTap: () {
                              final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
                              final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;
                              
                              ref.read(frequentAddressesProvider.notifier).setAddress(
                                    id: _editingId!,
                                    label: _editingLabel!,
                                    title: item['title'] ?? '',
                                    subtitle: item['subtitle'] ?? '',
                                    lat: lat,
                                    lon: lon,
                                  );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$_editingLabel definido com sucesso!',
                                  ),
                                ),
                              );

                              setState(() {
                                _editingId = null;
                                _editingLabel = null;
                                _searchCtrl.clear();
                                _suggestions = [];
                              });
                            },
                          );
                        },
                      ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteItem({
    required String id,
    required String label,
    required IconData icon,
    required Map<String, dynamic> address,
  }) {
    final hasAddress = address.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: widget.isDark ? AppColors.primaryLight : widget.primaryLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasAddress ? address['title'] : 'Não definido',
                  style: TextStyle(
                    color: hasAddress ? widget.textColor : widget.subtextColor,
                    fontSize: 14,
                    fontWeight: hasAddress ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (hasAddress) ...[
                  const SizedBox(height: 2),
                  Text(
                    address['subtitle'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.subtextColor,
                      fontSize: 12,
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (hasAddress) ...[
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: widget.isDark ? AppColors.primaryLight : widget.primaryLight,
              ),
              onPressed: () {
                setState(() {
                  _editingId = id;
                  _editingLabel = label;
                });
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              onPressed: () {
                ref.read(frequentAddressesProvider.notifier).removeAddress(id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label removido com sucesso!'),
                  ),
                );
              },
            ),
          ] else ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: widget.isDark
                      ? AppColors.primaryLight
                      : widget.primaryLight,
                ),
              ),
              onPressed: () {
                setState(() {
                  _editingId = id;
                  _editingLabel = label;
                });
              },
              child: Text(
                'Definir',
                style: TextStyle(
                  color: widget.isDark
                      ? AppColors.primaryLight
                      : widget.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
