/// Curated image asset paths for IULMS marketing/dashboard carousels.
///
/// All images live under `assets/images/` and are declared in `pubspec.yaml`.
/// The library/students/books/librarian carousels on the dashboard pull from
/// these lists so the user sees real library photography across horizontal
/// scrolling sections.
class ImageAssets {
  const ImageAssets._();

  /// Hero panoramic images — each one shows MULTIPLE library aspects
  /// (interior + students + books + librarian). They are auto-rotated by
  /// the [KenBurnsHero] widget with a slow zoom/pan animation.
  static const List<String> heroPanoramas = [
    'assets/images/hero_panorama.png',
    'assets/images/hero_panorama_2.png',
    'assets/images/hero_panorama_3.png',
  ];

  /// Captions paired 1:1 with [heroPanoramas] — shown over the moving image.
  static const List<String> heroCaptions = [
    'Knowledge · Heritage · Discovery',
    'Where Students Become Scholars',
    'A Space for Every Reader',
  ];

  /// Sub-captions for the hero.
  static const List<String> heroSubCaptions = [
    'Open Mon – Sat · 08:00 – 22:00',
    'Injibara University Library',
    '248 titles · 186 students · 412 available',
  ];

  /// Hero library interiors — used for the top-of-dashboard carousel.
  static const List<String> libraryScenes = [
    'assets/images/library_1.jpg',
    'assets/images/library_2.jpg',
    'assets/images/library_3.jpg',
    'assets/images/library_4.jpg',
  ];

  /// Library section captions paired 1:1 with [libraryScenes].
  static const List<String> libraryCaptions = [
    'Reading Hall',
    'Reference Stacks',
    'Quiet Study Area',
    'Periodicals Wing',
  ];

  /// Student community photos.
  static const List<String> studentScenes = [
    'assets/images/students_1.jpg',
    'assets/images/students_2.jpg',
    'assets/images/students_3.jpg',
    'assets/images/students_4.jpg',
  ];

  /// Book close-ups.
  static const List<String> bookScenes = [
    'assets/images/books_1.jpg',
    'assets/images/books_2.jpg',
    'assets/images/books_3.jpg',
    'assets/images/books_4.jpg',
  ];

  /// Librarian photos.
  static const List<String> librarianScenes = [
    'assets/images/librarian_1.jpg',
    'assets/images/librarian_2.jpg',
    'assets/images/librarian_3.png',
  ];
}
