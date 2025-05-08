class MenuItemModel {
  final String id;
  final String name;
  final String imageUrl;
  final int price;
  final String category;
  final int stock;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.stock,
  });

  factory MenuItemModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return MenuItemModel(
      id: docId,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: data['price'] ?? 0,
      category: data['category'] ?? '',
      stock: data['stock'] ?? 0,
    );
  }
}
