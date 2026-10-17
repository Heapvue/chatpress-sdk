import 'package:flutter/material.dart';
import 'package:chatpress/chatpress.dart';

void main() {
  runApp(const ExampleApp());
}

/// Replace these with your real values from the Chatpress dashboard.
const _config = ChatpressConfig(
  apiKey: 'cp_EQq4Rm8_Nqc2-OUrcWeCWu8XCQDDq_Sh',
  chatbotId: 'ad246b16-8b2e-4269-874b-1208e8c924a3',
  baseUrl: 'https://rag.heapvue.com',

  // ⚠️ Set previewMode: false in production and whitelist your app origin
  // in the Chatpress dashboard instead.
  previewMode: true,
);

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatpress SDK Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C63FF),
        fontFamily: 'SF Pro Display',
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FB),
      appBar: AppBar(
        title: const Text('Chatpress Example'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4A3FD4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.smart_toy_rounded, color: Colors.white, size: 36),
                  SizedBox(height: 12),
                  Text(
                    'Chatpress SDK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Integrate a powerful AI chatbot into your Flutter app with a single widget.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Option 1: Full-screen page
            _DemoButton(
              label: 'Open as Full-Screen Page',
              icon: Icons.open_in_full_rounded,
              onTap: () => ChatpressLauncher.openPage(context, _config),
            ),
            const SizedBox(height: 14),

            // Option 2: Bottom sheet
            _DemoButton(
              label: 'Open as Bottom Sheet',
              icon: Icons.expand_less_rounded,
              outlined: true,
              onTap: () => ChatpressLauncher.openSheet(context, _config),
            ),
            const SizedBox(height: 14),

            // Option 3: Dark theme
            _DemoButton(
              label: 'Open with Dark Theme',
              icon: Icons.dark_mode_rounded,
              outlined: true,
              onTap: () => ChatpressLauncher.openPage(
                context,
                _config,
                theme: ChatTheme.dark,
              ),
            ),
          ],
        ),
      ),
      // Option 4: FAB
      floatingActionButton: ChatpressFab(config: _config),
    );
  }
}

class _DemoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  const _DemoButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6C63FF),
          side: const BorderSide(color: Color(0xFF6C63FF)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      );
    }
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label:
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
