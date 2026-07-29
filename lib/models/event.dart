import 'profile.dart';

typedef RSVPStatus = String; // 'going' | 'maybe' | 'declined'

class EventRSVP {
  final String id;
  final String eventId;
  final String userId;
  final RSVPStatus status;
  final String createdAt;
  final Profile? profile;

  EventRSVP({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.profile,
  });

  factory EventRSVP.fromJson(Map<String, dynamic> json) {
    Profile? p;
    if (json['profile'] != null && json['profile'] is Map<String, dynamic>) {
      p = Profile.fromJson(json['profile']);
    }

    return EventRSVP(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? 'going',
      createdAt: json['created_at'] as String? ?? '',
      profile: p,
    );
  }
}

class Event {
  final String id;
  final String mentorId;
  final String title;
  final String description;
  final String eventDate;
  final String? zoomLink;
  final String inviteType; // 'group' | 'private'
  final String? inviteeId;
  final String createdAt;
  final Profile? mentor;
  final List<EventRSVP> rsvps;

  Event({
    required this.id,
    required this.mentorId,
    required this.title,
    required this.description,
    required this.eventDate,
    this.zoomLink,
    required this.inviteType,
    this.inviteeId,
    required this.createdAt,
    this.mentor,
    this.rsvps = const [],
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    Profile? mentorProf;
    if (json['mentor'] != null && json['mentor'] is Map<String, dynamic>) {
      mentorProf = Profile.fromJson(json['mentor']);
    }

    final rawRsvps = json['rsvps'] as List<dynamic>? ?? [];
    final rsvpsList = rawRsvps
        .map((r) => EventRSVP.fromJson(r as Map<String, dynamic>))
        .toList();

    return Event(
      id: json['id'] as String,
      mentorId: json['mentor_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      eventDate: json['event_date'] as String? ?? '',
      zoomLink: json['zoom_link'] as String?,
      inviteType: json['invite_type'] as String? ?? 'group',
      inviteeId: json['invitee_id'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      mentor: mentorProf,
      rsvps: rsvpsList,
    );
  }
}
