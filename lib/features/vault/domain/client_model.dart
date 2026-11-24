class PageCredential {
  final String id;
  final String siteName;
  final String url;
  final String username;
  final String password;
  final String notes;
  final DateTime updatedAt;

  const PageCredential({
    required this.id,
    required this.siteName,
    required this.url,
    required this.username,
    required this.password,
    this.notes = '',
    required this.updatedAt,
  });

  String get displayTitle {
    if (siteName.trim().isNotEmpty) return siteName.trim();
    final uri = Uri.tryParse(url.trim());
    if (uri != null && uri.host.isNotEmpty) return uri.host;
    return url.trim().isNotEmpty ? url.trim() : 'Página sin nombre';
  }

  PageCredential copyWith({
    String? id,
    String? siteName,
    String? url,
    String? username,
    String? password,
    String? notes,
    DateTime? updatedAt,
  }) {
    return PageCredential(
      id: id ?? this.id,
      siteName: siteName ?? this.siteName,
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'siteName': siteName,
        'url': url,
        'username': username,
        'password': password,
        'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PageCredential.fromJson(Map<String, dynamic> json) {
    return PageCredential(
      id: json['id']?.toString() ?? '',
      siteName: json['siteName']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ClientRecord {
  final String id;
  final String cc;
  final String nombre;
  final List<PageCredential> pages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientRecord({
    required this.id,
    required this.cc,
    required this.nombre,
    this.pages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get initials {
    final parts = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  ClientRecord copyWith({
    String? id,
    String? cc,
    String? nombre,
    List<PageCredential>? pages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientRecord(
      id: id ?? this.id,
      cc: cc ?? this.cc,
      nombre: nombre ?? this.nombre,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cc': cc,
        'nombre': nombre,
        'pages': pages.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ClientRecord.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'] as List<dynamic>? ?? const [];
    return ClientRecord(
      id: json['id']?.toString() ?? '',
      cc: json['cc']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      pages: rawPages
          .whereType<Map>()
          .map((p) => PageCredential.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
