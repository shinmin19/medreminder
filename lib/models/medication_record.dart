class MedicationRecord {
  final String id;
  final String medicationId;
  final String scheduleId;
  final DateTime scheduledTime;   // 计划服药时间
  final DateTime? actualTime;     // 实际服药时间
  final String status;            // taken / missed / skipped
  final String notes;
  final DateTime createdAt;

  MedicationRecord({
    required this.id,
    required this.medicationId,
    required this.scheduleId,
    required this.scheduledTime,
    this.actualTime,
    this.status = 'missed',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduleId': scheduleId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'actualTime': actualTime?.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicationRecord.fromMap(Map<String, dynamic> map) {
    return MedicationRecord(
      id: map['id'],
      medicationId: map['medicationId'],
      scheduleId: map['scheduleId'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      actualTime: map['actualTime'] != null ? DateTime.parse(map['actualTime']) : null,
      status: map['status'] ?? 'missed',
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }

  MedicationRecord copyWith({
    DateTime? actualTime,
    String? status,
    String? notes,
  }) {
    return MedicationRecord(
      id: id,
      medicationId: medicationId,
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
