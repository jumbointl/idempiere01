class IntroItem {
  final String title;
  final String description;
  final String imagePath;

  const IntroItem({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  factory IntroItem.fromMap(Map<String, String> map) {
    return IntroItem(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imagePath: map['imagePath'] ?? '',
    );
  }

  Map<String, String> toMap() {
    return {'title': title, 'description': description, 'imagePath': imagePath};
  }
}

final List<IntroItem> introItems = [
  const IntroItem(
    title: "Welcome to monalisa_app_001",
    description:
        "Simplify your financial tasks with out intuitive and powerful interface.",
    imagePath: "assets/images/intro_1.png",
  ),
  const IntroItem(
    title: "Explore Powerful Features",
    description:
        "Unlock tools designed to streamline your workflow and boost efficiency.",
    imagePath: "assets/images/intro_2.png",
  ),
  const IntroItem(
    title: "Begin Your monalisa_app_001 Journey",
    description:
        "Get started today and take control of your productivity with ease.",
    imagePath: "assets/images/intro_3.png",
  ),
];
