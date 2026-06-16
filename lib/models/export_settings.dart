enum ExportFormat { table, productCard }

enum ExportColumn {
  date('Date', 1.4),
  name('Name', 2.8),
  type('Type', 1.3),
  brand('Brand', 1.6),
  purity('Purity', 0.9),
  owner('Owner', 1.2),
  price('Price', 1.6),
  remarks('Remarks', 2.6);

  final String label;
  final double flex;
  const ExportColumn(this.label, this.flex);
}

class ExportSettings {
  final ExportFormat format;
  final Set<ExportColumn> columns;

  /// Which owner IDs to include. Items with a null ownerId are always included.
  final Set<int> selectedUserIds;

  final DateTime? fromDate;
  final DateTime? toDate;
  final bool groupByUser;
  final bool includePhotos; // product card format only

  const ExportSettings({
    required this.format,
    required this.columns,
    required this.selectedUserIds,
    this.fromDate,
    this.toDate,
    required this.groupByUser,
    required this.includePhotos,
  });
}
