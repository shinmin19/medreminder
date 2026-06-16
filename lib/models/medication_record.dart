class MedicationRecord {
  final String id;
  final String medicationId;
  final String? scheduleId;
  final DateTime scheduledTime;
  final DateTime? takenAt;
  final bool isTaken;
  final bool isSkipped;
  final String? notes;

  MedicationRecord({
    required this.id,
    required this.medicationId,
    this.scheduleId,
    required this.scheduledTime,
    this.takenAt,
    this.isTaken = false,
    this.isSkipped = false,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'schedule_id': scheduleId,
      'scheduled_time': scheduledTime.millisecondsSinceEpoch,
      'taken_at': takenAt?.millisecondsSinceEpoch,
      'is_taken': isTaken ? 1 : 0,
      'is_skipped': isSkipped ? 1 : 0,
      'notes': notes,
    };
  }

  factory MedicationRecord.fromMap(Map<String, dynamic> map) {
    return MedicationRecord(
      id: map['id'] as String,
      medicationId: map['medication_id'] as String,
      scheduleId: map['schedule_id'] as String?,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduled_time'] as int),
      takenAt: map['taken_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['taken_at'] as int)
          : null,
      isTaken: (map['is_taken'] as int) == 1,
      isSkipped: (map['is_skipped'] as int) == 1,
      notes: map['notes'] as String?,
    );
  }

  MedicationRecord copyWith({
    DateTime? takenAt,
    bool? isTaken,
    bool? isSkipped,
    String? notes,
  }) {
    return MedicationRecord(
      id: id,
      medicationId: medicationId,
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      takenAt: takenAt ?? this.takenAt,
      isTaken: isTaken ?? this.isTaken,
      isSkipped: isSkipped ?? this.isSkipped,
      notes: notes ?? this.notes,
    );
  }
}
