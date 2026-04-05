import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme.dart';

/// Consent screen — user must accept the wellness coaching disclaimer
/// before accessing the app. Shown once on first use.
class ConsentScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const ConsentScreen({super.key, required this.onAccepted});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _isSubmitting = false;

  Future<void> _accept() async {
    setState(() => _isSubmitting = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('bot_profiles')
            .update({'disclaimer_accepted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('person_id', userId);
      }
    } catch (_) {
      // Store locally even if DB update fails — don't block the user
    }

    widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HealthFlexx Coach')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wellness Coaching Disclaimer & Informed Consent',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      '1. Not Medical Advice',
                      'HealthFlexx Coach is an AI-powered wellness coaching application that '
                      'provides general guidance on physical activity (steps), sleep habits, and '
                      'nutrition. The information, suggestions, and coaching provided through this '
                      'app are for educational and informational purposes only and are not intended '
                      'to substitute for professional medical advice, diagnosis, or treatment.',
                    ),
                    _section(
                      '2. Not a Healthcare Provider',
                      'HealthFlexx Coach is not a licensed physician, therapist, dietitian, or '
                      'healthcare provider. The coaching techniques used in this app (including '
                      'Functional Imagery Training and Cognitive Behavioral Therapy for Insomnia '
                      'principles) are drawn from published research but are delivered in a wellness '
                      'coaching context, not a clinical one.',
                    ),
                    _section(
                      '3. Consult Your Healthcare Provider',
                      'Always seek the advice of your physician or other qualified healthcare '
                      'provider before beginning any new health program, including changes to your '
                      'physical activity, sleep routine, or diet. If you have or suspect you have a '
                      'medical condition, are taking medication, or have specific health concerns, '
                      'consult your doctor before using this app.',
                    ),
                    _section(
                      '4. No Guarantee of Results',
                      'Individual results vary. HealthFlexx Coach makes no guarantees regarding '
                      'health outcomes, weight loss, sleep improvement, or any other specific result '
                      'from using this service.',
                    ),
                    _section(
                      '5. Emergency Situations',
                      'This app is not designed for emergency or crisis situations. If you are '
                      'experiencing a medical emergency, call 911 or your local emergency services '
                      'immediately. If you are experiencing a mental health crisis, contact the 988 '
                      'Suicide and Crisis Lifeline (call or text 988).',
                    ),
                    _section(
                      '6. Your Responsibility',
                      'You are fully responsible for your own health, wellbeing, and decisions. By '
                      'using this app, you confirm that you are voluntarily participating in wellness '
                      'coaching and that you assume full responsibility for any actions you take based '
                      'on the information provided.',
                    ),
                    _section(
                      '7. Data and Privacy',
                      'HealthFlexx Coach collects health-related data (including sleep patterns, step '
                      'counts, and coaching conversations) to personalize your experience. This data '
                      'is handled in accordance with our Privacy Policy.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'By tapping "I Agree" below, you confirm that:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    _bullet('You have read and understand this disclaimer'),
                    _bullet('You understand that HealthFlexx Coach provides wellness coaching, not medical care'),
                    _bullet('You will consult a healthcare professional for any medical concerns'),
                    _bullet('You voluntarily consent to participate in AI-powered wellness coaching'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _accept,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('I Agree', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF444444))),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('\u2022  ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }
}
