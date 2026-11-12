import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/inventory_provider.dart';
import '../widgets/product_image_widget.dart';

class ProductDetailScreen extends ConsumerWidget {
  final ProductWithStock productWithStock;

  const ProductDetailScreen({super.key, required this.productWithStock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(movementsProvider);
    final product = productWithStock.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ProductImageWidget(
                  imagePath: product.image,
                  width: 100,
                  height: 100,
                  borderRadius: 8,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SKU: ${product.skuId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Stock Inicial: ${product.initialStock}'),
                      Text('Mínimo: ${product.minStock} | Lead Time: ${product.leadTime} días'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: productWithStock.isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: productWithStock.isLowStock ? Colors.red.shade200 : Colors.green.shade200),
                        ),
                        child: Text(
                          'Stock Actual: ${productWithStock.currentStock}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: productWithStock.isLowStock ? Colors.red.shade900 : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.blue),
                SizedBox(width: 8),
                Text('Historial de Movimientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: movementsAsync.when(
              data: (movements) {
                final productMovements = movements.where((m) => m.productName.trim().toLowerCase() == product.name.trim().toLowerCase()).toList();

                if (productMovements.isEmpty) {
                  return const Center(child: Text('No hay movimientos registrados.'));
                }

                productMovements.sort((a, b) => b.date.compareTo(a.date));

                return ListView.builder(
                  itemCount: productMovements.length,
                  itemBuilder: (context, index) {
                    final mov = productMovements[index];
                    final isEntrada = mov.type.toLowerCase() == 'entrada';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEntrada ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isEntrada ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                        title: Text(
                          '${mov.type} - Cantidad: ${mov.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Fecha: ${mov.date}${mov.usuarioNombre.isNotEmpty ? " • Por: ${mov.usuarioNombre}" : ""}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                            if (mov.observation.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.comment_outlined, size: 14, color: Colors.amber.shade900),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        mov.observation,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.brown.shade900,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        isThreeLine: mov.observation.isNotEmpty,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
