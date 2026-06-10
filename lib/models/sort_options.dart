enum SortField { date, name }

enum SortDirection { asc, desc }

extension SortFieldLabel on SortField {
  String get label => switch (this) {
        SortField.date => 'Date',
        SortField.name => 'Name',
      };
}
