class Medication {
  final String id;
  final String name;
  final String? dosage;
  final String? unit;
  final String? notes;
  final List<MedicationSchedule> schedules;
  final bool isActive;
  final DateTime createdAt;

  Medication({
    required this.id,
    required this.name,
    this.dosage,
    this.unit,
    this.notes,
    this.schedules = const [],
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map, {List<MedicationSchedule> schedules = const []}) {
    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String?,
      unit: map['unit'] as String?,
      notes: map['notes'] as String?,
      schedules: schedules,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Medication copyWith({
    String? name,
    String? dosage,
    String? unit,
    String? notes,
    List<MedicationSchedule>? schedules,
    bool? isActive,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      schedules: schedules ?? this.schedules,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

class MedicationSchedule {
  final String id;
  final String medicationId;
  final String timeOfDay; // HH:mm format
  final List<int> repeatDays; // 1-7 (Mon-Sun)
  final bool isActive;

  MedicationSchedule({
    required this.id,
    required this.medicationId,
    required this.timeOfDay,
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7],
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'time_of_day': timeOfDay,
      'repeat_days': repeatDays.join(','),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory MedicationSchedule.fromMap(Map<String, dynamic> map) {
    return MedicationSchedule(
      id: map['id'] as String,
      medicationId: map['medication_id'] as String,
      timeOfDay: map['time_of_day'] as String,
      repeatDays: (map['repeat_days'] as String).split(',').map(int.parse).toList(),
      isActive: (map['is_active'] as int) == 1,
    );
  }
}
