import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;           // 剂量：如 "1片"、"2粒"、"5ml"
  final String medicationType;   // 类型：口服/外用/注射
  final String colorHex;         // 药品颜色（十六进制）
  final int iconIndex;           // 药品图标索引
  final String notes;            // 备注
  final int totalPills;          // 总药量
  final int remainingPills;      // 剩余数量
  final int refillThreshold;     // 补药提醒阈值（天数）
  final DateTime? expiryDate;    // 有效期
  final List<MedicationSchedule> schedules;
  final bool isActive;           // 是否启用
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    required this.id,
    required this.name,
    this.dosage = '1片',
    this.medicationType = '口服',
    this.colorHex = '#4CAF50',
    this.iconIndex = 0,
    this.notes = '',
    this.totalPills = 30,
    this.remainingPills = 30,
    this.refillThreshold = 7,
    this.expiryDate,
    this.schedules = const [],
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Color get color => Color(int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'medicationType': medicationType,
      'colorHex': colorHex,
      'iconIndex': iconIndex,
      'notes': notes,
      'totalPills': totalPills,
      'remainingPills': remainingPills,
      'refillThreshold': refillThreshold,
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'] ?? '1片',
      medicationType: map['medicationType'] ?? '口服',
      colorHex: map['colorHex'] ?? '#4CAF50',
      iconIndex: map['iconIndex'] ?? 0,
      notes: map['notes'] ?? '',
      totalPills: map['totalPills'] ?? 30,
      remainingPills: map['remainingPills'] ?? 30,
      refillThreshold: map['refillThreshold'] ?? 7,
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
      isActive: (map['isActive'] ?? 1) == 1,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Medication copyWith({
    String? name,
    String? dosage,
    String? medicationType,
    String? colorHex,
    int? iconIndex,
    String? notes,
    int? totalPills,
    int? remainingPills,
    int? refillThreshold,
    DateTime? expiryDate,
    List<MedicationSchedule>? schedules,
    bool? isActive,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      medicationType: medicationType ?? this.medicationType,
      colorHex: colorHex ?? this.colorHex,
      iconIndex: iconIndex ?? this.iconIndex,
      notes: notes ?? this.notes,
      totalPills: totalPills ?? this.totalPills,
      remainingPills: remainingPills ?? this.remainingPills,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      expiryDate: expiryDate ?? this.expiryDate,
      schedules: schedules ?? this.schedules,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class MedicationSchedule {
  final String id;
  final String medicationId;
  final TimeOfDay time;          // 服药时间
  final String frequency;        // daily / interval / weekly
  final int intervalDays;        // 间隔天数（interval模式）
  final List<int> weekdays;      // 周几服药（weekly模式）
  final int advanceMinutes;      // 提前N分钟提醒
  final int repeatIntervalMinutes; // 间隔N分钟重复提醒
  final int repeatCount;         // 重复次数
  final bool isEnabled;

  MedicationSchedule({
    required this.id,
    required this.medicationId,
    required this.time,
    this.frequency = 'daily',
    this.intervalDays = 1,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.advanceMinutes = 10,
    this.repeatIntervalMinutes = 15,
    this.repeatCount = 3,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'hour': time.hour,
      'minute': time.minute,
      'frequency': frequency,
      'intervalDays': intervalDays,
      'weekdays': weekdays.join(','),
      'advanceMinutes': advanceMinutes,
      'repeatIntervalMinutes': repeatIntervalMinutes,
      'repeatCount': repeatCount,
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  factory MedicationSchedule.fromMap(Map<String, dynamic> map) {
    return MedicationSchedule(
      id: map['id'],
      medicationId: map['medicationId'],
      time: TimeOfDay(hour: map['hour'] ?? 8, minute: map['minute'] ?? 0),
      frequency: map['frequency'] ?? 'daily',
      intervalDays: map['intervalDays'] ?? 1,
      weekdays: (map['weekdays'] ?? '1,2,3,4,5,6,7').toString().split(',').map((e) => int.parse(e)).toList(),
      advanceMinutes: map['advanceMinutes'] ?? 10,
      repeatIntervalMinutes: map['repeatIntervalMinutes'] ?? 15,
      repeatCount: map['repeatCount'] ?? 3,
      isEnabled: (map['isEnabled'] ?? 1) == 1,
    );
  }

  MedicationSchedule copyWith({
    TimeOfDay? time,
    String? frequency,
    int? intervalDays,
    List<int>? weekdays,
    int? advanceMinutes,
    int? repeatIntervalMinutes,
    int? repeatCount,
    bool? isEnabled,
  }) {
    return MedicationSchedule(
      id: id,
      medicationId: medicationId,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      intervalDays: intervalDays ?? this.intervalDays,
      weekdays: weekdays ?? this.weekdays,
      advanceMinutes: advanceMinutes ?? this.advanceMinutes,
      repeatIntervalMinutes: repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      repeatCount: repeatCount ?? this.repeatCount,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
