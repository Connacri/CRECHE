import 'package:flutter/material.dart';
import 'app_models_mock.dart';

class MockAuthService extends ChangeNotifier {
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email == 'admin@creche.com') {
      _currentUser = AppUser(id: '1', email: email, name: 'Admin Julie', role: UserRole.admin);
    } else {
      _currentUser = AppUser(id: '2', email: email, name: 'Parent Marc', role: UserRole.parent);
    }
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  bool get isAuthenticated => _currentUser != null;
}

class MockDatabaseService {
  final List<Child> _children = [
    Child(id: 'c1', name: 'Léo', avatarUrl: 'assets/images/74cedd2a41f6ef0cbc37126ea12350c6.jpg', groupName: 'Petits Oursons'),
    Child(id: 'c2', name: 'Emma', avatarUrl: 'assets/images/5ac423335dba770991105fd30f6e3cf8.jpg', groupName: 'Petits Oursons'),
  ];

  final List<Story> _stories = [
    Story(
      title: 'Le Petit Nuage Rose',
      content: 'Il était une fois un petit nuage rose qui aimait faire des câlins au soleil...',
      coverImage: 'assets/images/8e16ab25c9b6075a09c2d7990984e21d.jpg',
      author: 'Fée des Crèches',
    ),
    Story(
      title: 'L\'Aventure du Tigre Rigolo',
      content: 'Milo le tigre aimait lire des livres dans la jungle enchantée...',
      coverImage: 'assets/images/bd8a5cdb0ab06e63da496e1d34edf385.jpg',
      author: 'Milo',
    ),
  ];

  Future<List<Child>> getChildren() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _children;
  }

  Future<List<Story>> getStories() async {
    return _stories;
  }

  Future<DailyMenu> getTodayMenu() async {
    return DailyMenu(
      date: DateTime.now(),
      items: [
        MenuItem(category: 'Déjeuner', title: 'Purée de carottes douce', description: 'Carottes bio et une touche de crème'),
        MenuItem(category: 'Goûter', title: 'Compote pomme-banane', description: 'Fruits frais mixés sans sucre ajouté'),
      ],
    );
  }

  Future<List<Activity>> getTodayActivities() async {
    return [
      Activity(
        title: 'Éveil Musical',
        description: 'Découverte des instruments en bois',
        startTime: DateTime.now().copyWith(hour: 10, minute: 0),
        endTime: DateTime.now().copyWith(hour: 10, minute: 45),
        icon: '🎵',
      ),
      Activity(
        title: 'Peinture aux doigts',
        description: 'Création d\'une fresque printanière',
        startTime: DateTime.now().copyWith(hour: 15, minute: 30),
        endTime: DateTime.now().copyWith(hour: 16, minute: 15),
        icon: '🎨',
      ),
    ];
  }

  Future<List<Invoice>> getInvoices(String childId) async {
    return [
      Invoice(id: 'inv1', childId: childId, amount: 450.0, dueDate: DateTime.now().subtract(const Duration(days: 5)), isPaid: true),
      Invoice(id: 'inv2', childId: childId, amount: 450.0, dueDate: DateTime.now().add(const Duration(days: 25)), isPaid: false),
    ];
  }
}
