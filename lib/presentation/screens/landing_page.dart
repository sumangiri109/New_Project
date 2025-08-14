import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _footerKey = GlobalKey();

  void _scrollToFooter() {
    final context = _footerKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Sticky top nav:
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _NavBar(onContactTap: _scrollToFooter),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Hero Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Image.asset(
                      'images/homepageImage.png',
                      width: 700,
                      height: 500,
                    ),
                  ),
                  const SizedBox(width: 50),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 70, top: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get Your pay before your payday with us!!',
                            style: GoogleFonts.workSans(
                              fontSize: 55,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 13),
                          Text(
                            'We have helped over thousands of Nepalese improve their financial health by paying off and advancing debt and collection fees, resulting in improved credit and less in collections calls.',
                            style: GoogleFonts.workSans(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 120),
                          SizedBox(
                            height: 70,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'APPLY NOW',
                                style: GoogleFonts.workSans(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // How It Works Section
            const HowItWorksSection(),

            // Calculate Extra Payment Section
            const CalculateExtraPaymentSection(),

            // Footer Section
            FooterSection(key: _footerKey),
          ],
        ),
      ),
    );
  }
}

// ---------------------- NAV BAR ----------------------
class _NavBar extends StatelessWidget {
  final VoidCallback onContactTap;
  const _NavBar({super.key, required this.onContactTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          Text(
            'Company Name',
            style: GoogleFonts.workSans(
              fontSize: 30,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ...['About Us', 'FAQ', 'SIGN IN'].map(
            (text) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => print('$text clicked'),
                  child: Text(
                    text,
                    style: GoogleFonts.workSans(
                      fontSize: 18,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Contact Us link:
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onContactTap,
                child: Text(
                  'Contact Us',
                  style: GoogleFonts.workSans(
                    fontSize: 18,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Apply Now',
                style: GoogleFonts.workSans(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------- HOW IT WORKS SECTION ----------------------
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'images/how_it_works.png',
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.fitWidth,
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(right: 40, left: 40, top: 230),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it Works',
                  style: GoogleFonts.workSans(
                    fontSize: 55,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 100),
                Wrap(
                  spacing: 28,
                  runSpacing: 80,
                  alignment: WrapAlignment.start,
                  children: const [
                    InfoCard(
                      emoji: '💻',
                      title: 'Apply Online',
                      description:
                          'Or over the phone, if that is easier for you. We will gather the information we need to provide you with a fast credit decision and a loan recommendation that will fit your budget.',
                    ),
                    InfoCard(
                      emoji: '😎',
                      title: 'Work with experts',
                      description:
                          'Help us gain a full picture of your financial situation and the overdue bills that are impacting you.',
                    ),
                    InfoCard(
                      emoji: '💰',
                      title: 'Pay Your debt',
                      description:
                          'We will provide a loan to pay off the overdue bills that are dragging down your credit score and help you get back on the path to better credit.',
                    ),
                    InfoCard(
                      emoji: '✅',
                      title: 'Pay minimal interest',
                      description:
                          'You only pay a small service fee — no hidden charges.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const InfoCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 343,
      height: 450,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 35),
          Text(
            title,
            style: GoogleFonts.workSans(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 85, 85, 85),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            description,
            style: GoogleFonts.workSans(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------- CALCULATE EXTRA PAYMENT SECTION ----------------------

class CalculateExtraPaymentSection extends StatefulWidget {
  const CalculateExtraPaymentSection({super.key});

  @override
  State<CalculateExtraPaymentSection> createState() =>
      _CalculateExtraPaymentSectionState();
}

class _CalculateExtraPaymentSectionState
    extends State<CalculateExtraPaymentSection> {
  double monthlySalary = 100000;
  int loanMonths = 12;

  double get cutRate => 0.02;

  // Eligible loan per month = salary - 2%
  double get eligibleLoan => monthlySalary * (1 - cutRate);

  // Total loan = eligibleLoan × duration
  double get totalLoan => eligibleLoan * loanMonths;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'images/calculate_extra4.png',
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.fitWidth,
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 130),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.fromLTRB(30, 45, 30, 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.elliptical(10, 20),
                    bottomRight: Radius.elliptical(10, 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculate Your Loan Eligibility',
                      style: GoogleFonts.workSans(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Monthly Salary Input
                    Text(
                      'Enter your monthly salary (रु):',
                      style: GoogleFonts.workSans(
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: monthlySalary.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(
                        () => monthlySalary =
                            double.tryParse(value) ?? monthlySalary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Loan Duration Input
                    Text(
                      'Enter loan duration (months):',
                      style: GoogleFonts.workSans(
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: loanMonths.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(
                        () => loanMonths = int.tryParse(value) ?? loanMonths,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Eligible Loan Display
                    Text(
                      'Your Eligible Loan per Month :',
                      style: GoogleFonts.workSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'रु ${eligibleLoan.toStringAsFixed(2)}',
                      style: GoogleFonts.workSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Total Loan Display
                    Text(
                      'Your Total Loan Amount :',
                      style: GoogleFonts.workSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'रु ${totalLoan.toStringAsFixed(2)}',
                      style: GoogleFonts.workSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------- FOOTER SECTION ----------------------
class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      color: const Color(0xFFFFF3E0), // soft orange bg
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 800;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSmall)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo & tagline
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company Name',
                            style: GoogleFonts.workSans(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bringing your pay closer to you.',
                            style: GoogleFonts.workSans(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.facebook),
                                onPressed: () {},
                                color: Colors.orange.shade700,
                              ),
                              IconButton(
                                icon: const Icon(Icons.mail),
                                onPressed: () {},
                                color: Colors.orange.shade700,
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone),
                                onPressed: () {},
                                color: Colors.orange.shade700,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 80),

                    // Quick Links (no Contact Us)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Links',
                            style: GoogleFonts.workSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...['About Us', 'FAQ', 'Apply Now'].map(
                            (text) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => print('$text clicked'),
                                  child: Text(
                                    text,
                                    style: GoogleFonts.workSans(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 80),

                    // Contact Info
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Us',
                            style: GoogleFonts.workSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Email: support@company.com',
                            style: GoogleFonts.workSans(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Phone: +977 9800000000',
                            style: GoogleFonts.workSans(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Address: Kathmandu, Nepal',
                            style: GoogleFonts.workSans(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              if (isSmall) ...[
                Text(
                  'Company Name',
                  style: GoogleFonts.workSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bringing your pay closer to you.',
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.facebook),
                      onPressed: () {},
                      color: Colors.orange.shade700,
                    ),
                    IconButton(
                      icon: const Icon(Icons.mail),
                      onPressed: () {},
                      color: Colors.orange.shade700,
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () {},
                      color: Colors.orange.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Divider(color: Colors.orange.shade200),
                const SizedBox(height: 30),
                Text(
                  'Quick Links',
                  style: GoogleFonts.workSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                ...['About Us', 'FAQ', 'Apply Now'].map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      text,
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Contact Us',
                  style: GoogleFonts.workSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Email: support@company.com',
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: +977 9800000000',
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Address: Kathmandu, Nepal',
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],

              const SizedBox(height: 60),
              Divider(color: Colors.orange.shade300),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '© 2025 Company Name. All rights reserved.',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
