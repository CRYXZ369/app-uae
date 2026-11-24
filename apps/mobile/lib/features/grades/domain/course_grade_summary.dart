import 'dart:convert';

class CourseGradeAssessment {
  const CourseGradeAssessment({
    required this.name,
    required this.weightPercentage,
    this.grade,
  });

  final String name;
  final double weightPercentage;
  final double? grade;

  factory CourseGradeAssessment.fromJson(Map<String, dynamic> json) =>
      CourseGradeAssessment(
        name: json['name'] as String,
        weightPercentage: _number(json['weightPercentage']),
        grade: json['grade'] == null ? null : _number(json['grade']),
      );
}

class CourseGradeSummary {
  CourseGradeSummary._({
    required this.courseName,
    required this.assessments,
    required this.totalPlannedWeight,
    required this.courseProgress,
    required this.estimatedAverage,
  });

  factory CourseGradeSummary.fromAssessments({
    required String courseName,
    required List<CourseGradeAssessment> assessments,
  }) {
    var totalWeight = 0.0;
    var gradedWeight = 0.0;
    var weightedGradeTotal = 0.0;

    for (final assessment in assessments) {
      final weight = assessment.weightPercentage;
      final grade = assessment.grade;
      if (!weight.isFinite || weight <= 0 || weight > 100) {
        throw ArgumentError.value(
          weight,
          'weightPercentage',
          'La ponderación debe ser mayor que 0 y no exceder 100.',
        );
      }
      if (grade != null && (!grade.isFinite || grade < 0 || grade > 100)) {
        throw ArgumentError.value(
          grade,
          'grade',
          'La calificación debe estar entre 0 y 100.',
        );
      }

      totalWeight += weight;
      if (grade != null) {
        gradedWeight += weight;
        weightedGradeTotal += grade * weight;
      }
    }

    if (totalWeight > 100.005) {
      throw ArgumentError.value(
        totalWeight,
        'assessments',
        'La suma de ponderaciones no puede exceder 100%.',
      );
    }

    final planIsComplete = (totalWeight - 100).abs() <= 0.005;
    return CourseGradeSummary._(
      courseName: courseName,
      assessments: List.unmodifiable(assessments),
      totalPlannedWeight: totalWeight,
      courseProgress: gradedWeight,
      estimatedAverage: planIsComplete && gradedWeight > 0
          ? weightedGradeTotal / gradedWeight
          : null,
    );
  }

  final String courseName;
  final List<CourseGradeAssessment> assessments;
  final double totalPlannedWeight;
  final double courseProgress;
  final double? estimatedAverage;

  bool get isEstimate => estimatedAverage != null;
  bool get hasCompletePlan => (totalPlannedWeight - 100).abs() <= 0.005;
  static const double scaleMaximum = 100;

  factory CourseGradeSummary.fromJson(Map<String, dynamic> json) {
    final rawAssessments = json['assessments'];
    final decoded = rawAssessments is String
        ? jsonDecode(rawAssessments)
        : rawAssessments;
    if (decoded is! List) {
      throw const FormatException('Evaluaciones inválidas.');
    }
    return CourseGradeSummary.fromAssessments(
      courseName: json['materia'] as String,
      assessments: decoded
          .map(
            (item) => CourseGradeAssessment.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

double _number(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());
