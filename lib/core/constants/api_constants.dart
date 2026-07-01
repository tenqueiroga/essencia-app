class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://essencia.laravel.cloud/api';

  // Auth
  static const String authGoogleRedirect = '/auth/google/redirect';
  static const String authGoogleCallback = '/auth/google/callback';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // User
  static const String userProfile = '/user/profile';
  static const String userExport = '/user/export';
  static const String userAccount = '/user/account';

  // Collection
  static const String collection = '/collection';
  static const String collectionProfile = '/collection/profile';
  static const String collectionStats = '/collection/stats';

  // Perfumes
  static const String perfumesSearch = '/perfumes/search';
  static const String perfumesExplore = '/perfumes/explore';

  // Journal
  static const String journal = '/journal';
  static const String journalStats = '/journal/stats';

  // Chat
  static const String chatConversations = '/chat/conversations';

  // Weather & Suggestions
  static const String weatherUpdate = '/weather/update';
  static const String suggestionsSeasonal = '/suggestions/seasonal';

  // Feed
  static const String feed = '/feed';

  // Badges
  static const String badges = '/badges';
  static const String badgesCheck = '/badges/check';
}
