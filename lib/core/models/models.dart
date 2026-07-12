// Models

class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String role; // 'student' | 'startup'
  final String? university;
  final String? major;
  final String? graduationYear;
  final List<String> skills;
  final String? bio;
  final String? linkedinUrl;
  final String? portfolioUrl;
  final String? cvUrl;
  final String? companyId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.role,
    this.university,
    this.major,
    this.graduationYear,
    this.skills = const [],
    this.bio,
    this.linkedinUrl,
    this.portfolioUrl,
    this.cvUrl,
    this.companyId,
  });
}

class CompanyModel {
  final String id;
  final String name;
  final String logoUrl;
  final String coverUrl;
  final String tagline;
  final String description;
  final String industry;
  final String location;
  final String stage; // 'Seed', 'Series A', etc.
  final int teamSize;
  final String website;
  final String? linkedinUrl;
  final String? twitterUrl;
  final List<String> perks;
  final bool isVerified;
  final double rating;
  final int reviewCount;

  const CompanyModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.coverUrl,
    required this.tagline,
    required this.description,
    required this.industry,
    required this.location,
    required this.stage,
    required this.teamSize,
    required this.website,
    this.linkedinUrl,
    this.twitterUrl,
    this.perks = const [],
    this.isVerified = false,
    this.rating = 4.5,
    this.reviewCount = 0,
  });
}

class OpportunityModel {
  final String id;
  final String companyId;
  final String companyName;
  final String companyLogo;
  final String title;
  final String type; // 'Internship' | 'Full-time' | 'Part-time' | 'Contract'
  final String location;
  final bool isRemote;
  final String duration;
  final String? stipend;
  final String description;
  final List<String> requirements;
  final List<String> responsibilities;
  final List<String> skills;
  final String category;
  final DateTime postedAt;
  final DateTime deadline;
  final int applicantCount;
  final bool isFeatured;
  final bool isSaved;

  const OpportunityModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.companyLogo,
    required this.title,
    required this.type,
    required this.location,
    required this.isRemote,
    required this.duration,
    this.stipend,
    required this.description,
    this.requirements = const [],
    this.responsibilities = const [],
    this.skills = const [],
    required this.category,
    required this.postedAt,
    required this.deadline,
    this.applicantCount = 0,
    this.isFeatured = false,
    this.isSaved = false,
  });

  OpportunityModel copyWith({bool? isSaved}) {
    return OpportunityModel(
      id: id,
      companyId: companyId,
      companyName: companyName,
      companyLogo: companyLogo,
      title: title,
      type: type,
      location: location,
      isRemote: isRemote,
      duration: duration,
      stipend: stipend,
      description: description,
      requirements: requirements,
      responsibilities: responsibilities,
      skills: skills,
      category: category,
      postedAt: postedAt,
      deadline: deadline,
      applicantCount: applicantCount,
      isFeatured: isFeatured,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class ApplicationModel {
  final String id;
  final String opportunityId;
  final String opportunityTitle;
  final String companyName;
  final String companyLogo;
  final String status; // 'applied' | 'reviewing' | 'interview' | 'offer' | 'rejected'
  final DateTime appliedAt;
  final DateTime? updatedAt;
  final String? coverLetter;
  final List<ApplicationEvent> timeline;

  const ApplicationModel({
    required this.id,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.companyName,
    required this.companyLogo,
    required this.status,
    required this.appliedAt,
    this.updatedAt,
    this.coverLetter,
    this.timeline = const [],
  });
}

class ApplicationEvent {
  final String status;
  final String message;
  final DateTime timestamp;

  const ApplicationEvent({
    required this.status,
    required this.message,
    required this.timestamp,
  });
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'application', 'message', 'match', 'system'
  final DateTime timestamp;
  final bool isRead;
  final String? avatarUrl;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.avatarUrl,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? avatarUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });
}

class ConversationModel {
  final String id;
  final String participantName;
  final String participantAvatar;
  final String participantRole;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<MessageModel> messages;

  const ConversationModel({
    required this.id,
    required this.participantName,
    required this.participantAvatar,
    required this.participantRole,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.messages = const [],
  });
}
