class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}

final List<OnboardingData> onboardingPages = [
  OnboardingData(
    image: "assets/images/onboarding/onboarding1.png",
    title: "Daily Essentials",
    description:
        "Order groceries, food, fresh meat, pharmacy, and daily essentials in one app.",
  ),
  OnboardingData(
    image: "assets/images/onboarding/onboarding2.png",
    title: "Professional Services",
    description:
        "Book electricians, plumbers, AC service, cleaning, and home services easily.",
  ),
  OnboardingData(
    image: "assets/images/onboarding/onboarding3.png",
    title: "Travel Booking",
    description:
        "Book bus, train, flight, hotels, and travel services in just a few taps.",
  ),
  OnboardingData(
    image: "assets/images/onboarding/onboarding4.png",
    title: "Entertainment",
    description:
        "Book movie tickets and discover exciting entertainment near you.",
  ),
];
