class MenuItemModel {
  final String id;
  final String name;
  final String imageUrl;
  final int price;
  final String category;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
  });

  factory MenuItemModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return MenuItemModel(
      id: docId,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: data['price'] ?? 0,
      category: data['category'] ?? '',
    );
  }
}
