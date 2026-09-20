import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';

enum CommitmentStatus { active, paused, archived }

class Commitment {
  Commitment({
    required this.id,
    required String title,
    required this.createdAt,
    this.status = CommitmentStatus.active,
  }) : title = _validateTitle(title);

  factory Commitment.create({required String title, DateTime? now}) {
    return Commitment(
      id: StableId.generate(),
      title: title,
      createdAt: (now ?? DateTime.now()).toUtc(),
    );
  }

  final StableId id;
  final String title;
  final DateTime createdAt;
  final CommitmentStatus status;

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
