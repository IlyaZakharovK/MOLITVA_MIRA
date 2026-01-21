enum RequestStatus { pending, approved, rejected }

extension RequestStatusUi on RequestStatus {
  String get label => switch (this) {
    RequestStatus.pending => 'На рассмотрении',
    RequestStatus.approved => 'Одобрено',
    RequestStatus.rejected => 'Отклонено',
  };

  bool get isFinal => this == RequestStatus.approved || this == RequestStatus.rejected;
}
