import 'income_source.dart';
import 'deduction.dart';

enum WorkSchedule { medioTiempo, tiempoCompleto, mixto }

extension WorkScheduleLabel on WorkSchedule {
  String get label {
    switch (this) {
      case WorkSchedule.medioTiempo:
        return 'Medio tiempo';
      case WorkSchedule.tiempoCompleto:
        return 'Tiempo completo';
      case WorkSchedule.mixto:
        return 'Mixto';
    }
  }

  /// Valor exacto que espera/devuelve la API en el campo work_schedule.
  String get apiValue {
    switch (this) {
      case WorkSchedule.medioTiempo:
        return 'medio_tiempo';
      case WorkSchedule.tiempoCompleto:
        return 'tiempo_completo';
      case WorkSchedule.mixto:
        return 'mixto';
    }
  }

  static WorkSchedule fromApiValue(String value) {
    switch (value) {
      case 'tiempo_completo':
        return WorkSchedule.tiempoCompleto;
      case 'mixto':
        return WorkSchedule.mixto;
      case 'medio_tiempo':
      default:
        return WorkSchedule.medioTiempo;
    }
  }
}

/// Una planilla real: el período que cubre, cuándo y cómo se paga,
/// y el detalle de ingresos y descuentos de ese período.
class PayPeriod {
  final String id;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime payDate;
  final String paymentMethod;
  final WorkSchedule schedule;
  final List<IncomeSource> incomeSources;
  final List<DeductionRule> deductions;

  const PayPeriod({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.payDate,
    required this.paymentMethod,
    required this.schedule,
    required this.incomeSources,
    required this.deductions,
  });

  double get grossPay => incomeSources.fold(0.0, (sum, i) => sum + i.amount);

  double get totalDeductions =>
      deductions.fold(0.0, (sum, d) => sum + d.amount);

  double get netPay => grossPay - totalDeductions;

  /// Construye una planilla a partir del JSON de PayPeriodResource.
  factory PayPeriod.fromJson(Map<String, dynamic> json) {
    return PayPeriod(
      id: json['id'].toString(),
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      payDate: DateTime.parse(json['pay_date'] as String),
      paymentMethod: json['payment_method'] as String,
      schedule: WorkScheduleLabel.fromApiValue(json['work_schedule'] as String),
      incomeSources: (json['incomes'] as List<dynamic>? ?? [])
          .map((e) => IncomeSource.fromJson(e as Map<String, dynamic>))
          .toList(),
      deductions: (json['deductions'] as List<dynamic>? ?? [])
          .map((e) => DeductionRule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
