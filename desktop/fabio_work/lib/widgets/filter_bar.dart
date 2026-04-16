import 'package:flutter/material.dart';

class FilterBar extends StatefulWidget {
  final void Function({
    String? status,
    String? codigoCliente,
    String? productId,
    String? uuid,
  }) onFilter;

  const FilterBar({super.key, required this.onFilter});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  final _clienteController = TextEditingController();
  final _productController = TextEditingController();
  final _uuidController = TextEditingController();
  String? _selectedStatus;

  static const _statuses = [
    'created',
    'paid',
    'shipped',
    'delivered',
    'canceled',
    'pending',
    'confirmed',
    'separated',
  ];

  void _apply() {
    widget.onFilter(
      status: _selectedStatus,
      codigoCliente: _clienteController.text.trim(),
      productId: _productController.text.trim(),
      uuid: _uuidController.text.trim(),
    );
  }

  void _clear() {
    setState(() {
      _selectedStatus = null;
      _clienteController.clear();
      _productController.clear();
      _uuidController.clear();
    });
    widget.onFilter();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _productController.dispose();
    _uuidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _uuidController,
                  decoration: const InputDecoration(
                    labelText: 'UUID do Pedido',
                    prefixIcon: Icon(Icons.tag, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_outlined, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ..._statuses.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.toUpperCase()),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedStatus = v),
                ),
              ),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _clienteController,
                  decoration: const InputDecoration(
                    labelText: 'ID Cliente',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _productController,
                  decoration: const InputDecoration(
                    labelText: 'ID Produto',
                    prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              FilledButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Buscar'),
              ),
              OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Limpar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
