import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SecureChatEscrowPage extends StatefulWidget {
  const SecureChatEscrowPage({super.key});

  @override
  State<SecureChatEscrowPage> createState() =>
      _SecureChatEscrowPageState();
}

class _SecureChatEscrowPageState extends State<SecureChatEscrowPage> {
  final TextEditingController _controller = TextEditingController();

  bool showScheduler = false;
  bool showVerification = false;
  bool escrowActive = true;

  List<_EscrowMessage> messages = [
    _EscrowMessage(
      text: "Hi! I'm excited to learn guitar 🎸",
      isUser: false,
    ),
    _EscrowMessage(
      text: "Great! I want to improve Spanish 🇪🇸",
      isUser: true,
    ),
    _EscrowMessage(
      isSchedule: true,
    ),
    _EscrowMessage(
      isEscrow: true,
      escrowStatus: "locked",
    ),
  ];

  void sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      messages.add(
        _EscrowMessage(
          text: _controller.text,
          isUser: true,
        ),
      );
      _controller.clear();
    });
  }

  void completeEscrow() {
    setState(() {
      messages.add(
        _EscrowMessage(
          isEscrow: true,
          escrowStatus: "completed",
        ),
      );
      showVerification = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            if (escrowActive) _escrowBanner(),
            Expanded(child: _messages()),
            if (showScheduler) _schedulerPanel(),
            _input(),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/matching'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 10),
          const Text("Sarah Martinez",
              style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // ESCROW BANNER
  Widget _escrowBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.deepPurple.withValues(alpha: 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("50 HC locked",
              style: TextStyle(color: Colors.white)),
          TextButton(
            onPressed: () => setState(() => showVerification = true),
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  // MESSAGES
  Widget _messages() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: messages.map((m) {
        if (m.isSchedule) return _scheduleCard();
        if (m.isEscrow) return _escrowCard(m);

        return Align(
          alignment:
              m.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: m.isUser
                  ? Colors.deepPurple
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(m.text ?? "",
                style: const TextStyle(color: Colors.white)),
          ),
        );
      }).toList(),
    );
  }

  // SCHEDULE CARD
  Widget _scheduleCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.blueGrey,
      child: const Text("Session Scheduled",
          style: TextStyle(color: Colors.white)),
    );
  }

  // ESCROW CARD
  Widget _escrowCard(_EscrowMessage m) {
    final completed = m.escrowStatus == "completed";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completed ? Colors.green : Colors.deepPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        completed ? "Session Completed ✅" : "Tokens Locked 🔒",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // SCHEDULER
  Widget _schedulerPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Column(
        children: const [
          Text("Schedule Session",
              style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // INPUT
  Widget _input() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() => showScheduler = !showScheduler);
            },
            icon: const Icon(Icons.calendar_month, color: Colors.white),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Message...",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _EscrowMessage {
  final String? text;
  final bool isUser;
  final bool isSchedule;
  final bool isEscrow;
  final String? escrowStatus;

  _EscrowMessage({
    this.text,
    this.isUser = false,
    this.isSchedule = false,
    this.isEscrow = false,
    this.escrowStatus,
  });
}
