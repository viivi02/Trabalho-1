import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../widgets/filter_bar.dart';
import '../widgets/status_chip.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _api = ApiService();
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  OrdersPage? _data;
  bool _loading = true;
  String? _error;

  int _page = 0;
  final int _size = 15;
  String _sort = 'desc';

  String? _filterStatus;
  String? _filterCliente;
  String? _filterProduct;
  String? _filterUuid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_filterUuid != null && _filterUuid!.isNotEmpty) {
        final order = await _api.fetchOrderByUuid(_filterUuid!);
        setState(() {
          _data = OrdersPage(
            content: order != null ? [order] : [],
            page: 0,
            size: 1,
            totalElements: order != null ? 1 : 0,
            totalPages: 1,
          );
          _loading = false;
        });
        return;
      }

      final data = await _api.fetchOrders(
        page: _page,
        size: _size,
        sort: _sort,
        status: _filterStatus,
        codigoCliente: _filterCliente,
        productId: _filterProduct,
      );
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onFilter({String? status, String? codigoCliente, String? productId, String? uuid}) {
    _page = 0;
    _filterStatus = status;
    _filterCliente = codigoCliente;
    _filterProduct = productId;
    _filterUuid = uuid;
    _load();
  }

  void _goToPage(int page) {
    _page = page;
    _load();
  }

  void _toggleSort() {
    _sort = _sort == 'desc' ? 'asc' : 'desc';
    _page = 0;
    _load();
  }

  void _openDetail(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.receipt_long),
            SizedBox(width: 10),
            Text('Orders Dashboard'),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: _load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FilterBar(onFilter: _onFilter),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text('Erro ao carregar pedidos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final data = _data!;

    if (data.content.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Nenhum pedido encontrado', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Tente ajustar os filtros ou aguarde o consumer processar mensagens.',
                style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryBar(theme, data),
        const SizedBox(height: 12),
        Expanded(child: _buildTable(theme, data)),
        const SizedBox(height: 12),
        _buildPagination(theme, data),
      ],
    );
  }

  Widget _buildSummaryBar(ThemeData theme, OrdersPage data) {
    return Row(
      children: [
        Text(
          '${data.totalElements} pedido(s) encontrado(s)',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _toggleSort,
          icon: Icon(_sort == 'desc' ? Icons.arrow_downward : Icons.arrow_upward, size: 16),
          label: Text('Data ${_sort == "desc" ? "mais recente" : "mais antiga"}'),
        ),
      ],
    );
  }

  Widget _buildTable(ThemeData theme, OrdersPage data) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerLow),
            showCheckboxColumn: false,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('UUID')),
              DataColumn(label: Text('Data')),
              DataColumn(label: Text('Cliente')),
              DataColumn(label: Text('Canal')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Itens'), numeric: true),
              DataColumn(label: Text('Total'), numeric: true),
            ],
            rows: data.content.map((order) {
              return DataRow(
                onSelectChanged: (_) => _openDetail(order),
                cells: [
                  DataCell(Text(order.uuid, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(_formatDate(order.createdAt))),
                  DataCell(Text(order.customer?.name ?? '-')),
                  DataCell(Text(order.channel ?? '-')),
                  DataCell(order.status != null ? StatusChip(status: order.status!) : const Text('-')),
                  DataCell(Text('${order.items.length}')),
                  DataCell(Text(_currencyFormat.format(order.total),
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(ThemeData theme, OrdersPage data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _page > 0 ? () => _goToPage(0) : null,
          icon: const Icon(Icons.first_page),
          tooltip: 'Primeira',
        ),
        IconButton(
          onPressed: _page > 0 ? () => _goToPage(_page - 1) : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Anterior',
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Pagina ${data.page + 1} de ${data.totalPages}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _page < data.totalPages - 1 ? () => _goToPage(_page + 1) : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Proxima',
        ),
        IconButton(
          onPressed: _page < data.totalPages - 1 ? () => _goToPage(data.totalPages - 1) : null,
          icon: const Icon(Icons.last_page),
          tooltip: 'Ultima',
        ),
      ],
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return date;
    }
  }
}
