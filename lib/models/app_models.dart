class Child {
  final String id;
  final String name;
  final String avatarUrl;
  final String groupName;

  Child({required this.id, required this.name, required this.avatarUrl, required this.groupName});
}

enum AttendanceStatus { present, absent, late }

class AttendanceRecord {
  final String childId;
  final DateTime date;
  final AttendanceStatus status;
  final String? note;

  AttendanceRecord({required this.childId, required this.date, required this.status, this.note});
}

class MenuItem {
  final String title;
  final String description;
  final String category; // e.g., "Déjeuner", "Goûter"

  MenuItem({required this.title, required this.description, required this.category});
}

class DailyMenu {
  final DateTime date;
  final List<MenuItem> items;

  DailyMenu({required this.date, required this.items});
}

class Activity {
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String icon;

  Activity({required this.title, required this.description, required this.startTime, required this.endTime, required this.icon});
}

class Invoice {
  final String id;
  final String childId;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;

  Invoice({required this.id, required this.childId, required this.amount, required this.dueDate, required this.isPaid});
}

class Story {
  final String title;
  final String content;
  final String coverImage;
  final String author;

  Story({required this.title, required this.content, required this.coverImage, required this.author});
}

enum UserRole { admin, parent }

class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  AppUser({required this.id, required this.email, required this.name, required this.role});
}
