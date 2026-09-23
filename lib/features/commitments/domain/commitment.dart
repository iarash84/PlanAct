import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';

enum CommitmentStatus { active, paused, archived, completed, cancelled }

enum CommitmentKind { oneOff, recurring }

enum CommitmentPriority { low, normal, high, urgent }

class Commitment {
  Commitment({
    required this.id,
    required String title,
    required this.createdAt,
    this.status = CommitmentStatus.active,
    this.kind = CommitmentKind.oneOff,
    this.priority = CommitmentPriority.normal,
    this.description,
    Set<String> tags = const {},
    List<String> attachmentIds = const [],
  }) : title = _validateTitle(title),
       tags = Set.unmodifiable(
         tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty),
       ),
       attachmentIds = List.unmodifiable(attachmentIds);

  factory Commitment.create({
    required String title,
    DateTime? now,
    CommitmentKind kind = CommitmentKind.oneOff,
    CommitmentPriority priority = CommitmentPriority.normal,
    String? description,
    Set<String> tags = const {},
    List<String> attachmentIds = const [],
  }) {
    return Commitment(
      id: StableId.generate(),
      title: title,
      createdAt: (now ?? DateTime.now()).toUtc(),
      kind: kind,
      priority: priority,
      description: description,
      tags: tags,
      attachmentIds: attachmentIds,
    );
  }

  final StableId id;
  final String title;
  final DateTime createdAt;
  final CommitmentStatus status;
  final CommitmentKind kind;
  final CommitmentPriority priority;
  final String? description;
  final Set<String> tags;
  final List<String> attachmentIds;

  Commitment complete() {
    if (status != CommitmentStatus.active) {
      throw const ValidationError('Only an active commitment can be completed');
    }
    return _copyWith(status: CommitmentStatus.completed);
  }

  Commitment cancel() {
    if (status != CommitmentStatus.active &&
        status != CommitmentStatus.paused) {
      throw const ValidationError(
        'Only an active or paused commitment can be cancelled',
      );
    }
    return _copyWith(status: CommitmentStatus.cancelled);
  }

  Commitment pause() {
    if (status != CommitmentStatus.active) {
      throw ValidationError('Only an active commitment can be paused');
    }
    return _copyWith(status: CommitmentStatus.paused);
  }

  Commitment resume() {
    if (status != CommitmentStatus.paused) {
      throw ValidationError('Only a paused commitment can be resumed');
    }
    return _copyWith(status: CommitmentStatus.active);
  }

  Commitment archive() {
    if (status == CommitmentStatus.archived) {
      throw ValidationError('An archived commitment cannot be archived again');
    }
    return _copyWith(status: CommitmentStatus.archived);
  }

  Commitment _copyWith({required CommitmentStatus status}) {
    return Commitment(
      id: id,
      title: title,
      createdAt: createdAt,
      status: status,
      kind: kind,
      priority: priority,
      description: description,
      tags: tags,
      attachmentIds: attachmentIds,
    );
  }

  static String _validateTitle(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const ValidationError('Commitment title cannot be empty');
    }
    return normalized;
  }
}
