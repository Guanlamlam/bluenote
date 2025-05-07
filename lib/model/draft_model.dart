class DraftPost {
  final int? id;
  final String userId;
  final String item;
  final String contact;
  final String contactNumber;
  final String location;
  final String type;
  final String timestamp;

  DraftPost({
    this.id,
    required this.userId,
    required this.item,
    required this.contact,
    required this.contactNumber,
    required this.location,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'item': item,
      'contact': contact,
      'contactNumber': contactNumber,
      'location': location,
      'type': type,
      'timestamp': timestamp,
    };
  }
}
