class SavedDocument {
  final String id;
  final String title;
  final String fileName;
  final String fileType;
  final String fileSize;
  final DateTime createdAt;
  final String documentType; // Contract, Will, etc.
  final bool isBlockchainVerified;
  final String? blockchainHash;
  final String? thumbnailUrl;
  final String storageUrl;
  final String userId;

  SavedDocument({
    required this.id,
    required this.title,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
    required this.documentType,
    required this.isBlockchainVerified,
    this.blockchainHash,
    this.thumbnailUrl,
    required this.storageUrl,
    required this.userId,
  });

  factory SavedDocument.fromJson(Map<String, dynamic> json) {
    return SavedDocument(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      documentType: json['documentType'] ?? 'Document',
      isBlockchainVerified: json['isBlockchainVerified'] ?? false,
      blockchainHash: json['blockchainHash'],
      thumbnailUrl: json['thumbnailUrl'],
      storageUrl: json['storageUrl'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
      'documentType': documentType,
      'isBlockchainVerified': isBlockchainVerified,
      'blockchainHash': blockchainHash,
      'thumbnailUrl': thumbnailUrl,
      'storageUrl': storageUrl,
      'userId': userId,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get fileExtension {
    return fileType.toUpperCase();
  }
}