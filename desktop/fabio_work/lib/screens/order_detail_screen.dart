import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../widgets/status_chip.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(order.uuid),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, currencyFormat),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCustomerCard(theme)),
                const SizedBox(width: 16),
                Expanded(child: _buildSellerCard(theme)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPaymentCard(theme)),
                const SizedBox(width: 16),
                Expanded(child: _buildShipmentCard(theme)),
              ],
            ),
            const SizedBox(height: 24),
            _buildItemsTable(theme, currencyFormat),
            if (order.metadata != null) ...[
              const SizedBox(height: 24),
              _buildMetadataCard(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withAlpha(180)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
                const SizedBox(height: 4),
                Text(order.uuid, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (order.createdAt != null)
                  Text('Criado em: ${_formatDate(order.createdAt!)}',
                      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
              const SizedBox(height: 4),
              Text(fmt.format(order.total),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (order.status != null) StatusChip(status: order.status!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(ThemeData theme) {
    final c = order.customer;
    return _infoCard(
      theme,
      icon: Icons.person_outline,
      title: 'Cliente',
      rows: [
        if (c != null) ...[
          _row('ID', '${c.id}'),
          _row('Nome', c.name ?? '-'),
          _row('Email', c.email ?? '-'),
          _row('Documento', c.document ?? '-'),
        ] else
          _row('', 'Sem dados'),
      ],
    );
  }

  Widget _buildSellerCard(ThemeData theme) {
    final s = order.seller;
    return _infoCard(
      theme,
      icon: Icons.store_outlined,
      title: 'Vendedor',
      rows: [
        if (s != null) ...[
          _row('ID', '${s.id}'),
          _row('Nome', s.name ?? '-'),
          _row('Cidade', s.city ?? '-'),
          _row('Estado', s.state ?? '-'),
        ] else
          _row('', 'Sem dados'),
      ],
    );
  }

  Widget _buildPaymentCard(ThemeData theme) {
    final p = order.payment;
    return _infoCard(
      theme,
      icon: Icons.payment_outlined,
      title: 'Pagamento',
      rows: [
        if (p != null) ...[
          _row('Metodo', p.method ?? '-'),
          _row('Status', p.status ?? '-'),
          _row('Transacao', p.transactionId ?? '-'),
        ] else
          _row('', 'Sem dados'),
      ],
    );
  }

  Widget _buildShipmentCard(ThemeData theme) {
    final s = order.shipment;
    return _infoCard(
      theme,
      icon: Icons.local_shipping_outlined,
      title: 'Envio',
      rows: [
        if (s != null) ...[
          _row('Transportadora', s.carrier ?? '-'),
          _row('Servico', s.service ?? '-'),
          _row('Status', s.status ?? '-'),
          _row('Rastreio', s.trackingCode ?? '-'),
        ] else
          _row('', 'Sem dados'),
      ],
    );
  }

  Widget _buildMetadataCard(ThemeData theme) {
    final m = order.metadata!;
    return _infoCard(
      theme,
      icon: Icons.info_outline,
      title: 'Metadata',
      rows: [
        _row('Source', m.source ?? '-'),
        _row('User Agent', m.userAgent ?? '-'),
        _row('IP', m.ipAddress ?? '-'),
      ],
    );
  }

  Widget _infoCard(ThemeData theme, {required IconData icon, required String title, required List<Widget> rows}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 20),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          ],
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildItemsTable(ThemeData theme, NumberFormat fmt) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Itens (${order.items.length})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerLow),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Produto')),
                  DataColumn(label: Text('Categoria')),
                  DataColumn(label: Text('Qtd'), numeric: true),
                  DataColumn(label: Text('Preco Unit.'), numeric: true),
                  DataColumn(label: Text('Total'), numeric: true),
                ],
                rows: order.items.map((item) {
                  final catLabel = item.category != null
                      ? '${item.category!.name ?? "-"}${item.category!.subCategory != null ? " > ${item.category!.subCategory!.name}" : ""}'
                      : '-';
                  return DataRow(cells: [
                    DataCell(Text(item.productName ?? 'ID: ${item.productId}')),
                    DataCell(Text(catLabel, style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${item.quantity}')),
                    DataCell(Text(fmt.format(item.unitPrice))),
                    DataCell(Text(fmt.format(item.total),
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return date;
    }
  }
}
