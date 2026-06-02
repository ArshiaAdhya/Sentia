import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../garden_state.dart';
import '../../../services/api_service.dart';
import '../../../services/chat_service.dart';

// ─── Data model ───────────────────────────────────────────────────────────────
enum _Sender { ai, user }

class _ChatMessage {
  final String text;
  final _Sender sender;
  _ChatMessage({required this.text, required this.sender});
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final _state = GardenState();

  // Chat message list
  final List<_ChatMessage> _messages = [];

  bool _isSending = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _initSessionAndLoadHistory();
  }

  Future<void> _initSessionAndLoadHistory() async {
    final userId = await ApiService.getUserId();
    final sessionId = await ApiService.getOrCreateSessionId(userId);

    if (!mounted) return;

    setState(() {
      _sessionId = sessionId;
    });

    await _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final sessionId = _sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    try {
      final res = await ApiService.get('/get_chat?session_id=$sessionId');
      // If we got history back, load it in!
      if (res['messages'] != null && (res['messages'] as List).isNotEmpty) {
        final msgs = res['messages'] as List;
        setState(() {
          _messages.clear();
          for (final msg in msgs) {
            _messages.add(_ChatMessage(
              text: msg['content'] ?? '',
              sender: msg['role'] == 'assistant' ? _Sender.ai : _Sender.user,
            ));
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final sessionId = _sessionId;

    if (sessionId == null || sessionId.isEmpty) return;
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, sender: _Sender.user));
      _textController.clear();
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final userId = await ApiService.getUserId();
      if (userId.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final res = await ChatService.sendMessageToSentia(
        rawUserMessage: text,
        userId: userId,
        sessionId: sessionId,
      );

      _state.syncProgress(seeds: res.seeds, streak: res.streak);
      if (res.seeds != null || res.streak != null) {
        await _state.refreshHomeData();
      }
      if (res.conversationCompleted) {
        await _state.loadJournalDates();
      }

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: res.reply,
            sender: _Sender.ai,
          ));
          _isSending = false;
        });
        _scrollToBottom();
        _showSeedRewardIfNeeded(res.seedReward);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text:
                "I'm having trouble connecting right now. Let's try again in a moment. 🌱",
            sender: _Sender.ai,
          ));
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSeedRewardIfNeeded(Map<String, dynamic>? reward) {
    if (reward == null || reward['awarded'] != true || !mounted) return;

    final earnedSeeds = _rewardInt(reward, 'earnedSeeds') ??
        _rewardInt(reward, 'earnedMoodSeeds') ??
        0;
    final oldSeeds = _rewardInt(reward, 'oldSeeds') ?? 0;
    final newSeeds = _rewardInt(reward, 'newSeeds') ??
        _rewardInt(reward, 'totalSeeds') ??
        oldSeeds + earnedSeeds;

    if (earnedSeeds <= 0) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SeedRewardDialog(
        earnedSeeds: earnedSeeds,
        oldSeeds: oldSeeds,
        newSeeds: newSeeds,
      ),
    );
  }

  int? _rewardInt(Map<String, dynamic> reward, String key) {
    final value = reward[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Garden background ─────────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/garden_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── Soft dark overlay for readability ─────────────────────────────
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.18),
            ),
          ),

          // ── Main content column ───────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top app bar
                _buildTopBar(),

                // Chat messages list
                Expanded(
                  child: _buildMessageList(),
                ),

                // Input bar + bottom nav space
                _buildInputBar(bottomPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Seeds pill
          _GlassPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌱', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                AnimatedBuilder(
                  animation: _state,
                  builder: (_, __) => Text(
                    '${_state.seeds}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Title
          Expanded(
            child: Text(
              'Sentia AI',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),

          // Streak pill
          _GlassPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _state,
                  builder: (_, __) => Text(
                    '${_state.streak}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('🔥', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ───────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          // Typing indicator
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isAI = msg.sender == _Sender.ai;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAI) ...[
            // Penguin avatar
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/penguin_avatar.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],

          // Bubble
          Flexible(
            child: _ChatBubble(
              isAI: isAI,
              text: msg.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.6), width: 2),
            ),
            child: ClipOval(
              child: Image.asset('assets/images/penguin_avatar.png',
                  fit: BoxFit.cover),
            ),
          ),
          _GlassBubble(
            isAI: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _TypingDot(delay: i * 200)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────────
  Widget _buildInputBar(double bottomPadding) {
    // Reserve space for bottom nav bar (96) + extra padding (24)
    final navBarSpace = bottomPadding > 0 ? bottomPadding : 96.0 + 24.0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, navBarSpace),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(32),
              border:
                  Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              children: [
                // Image/attachment icon
                _InputIconButton(
                  icon: Icons.image_outlined,
                  onTap: () {},
                ),
                const SizedBox(width: 8),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    onSubmitted: (_) => _sendMessage(),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.65),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),

                // Mic icon
                _InputIconButton(
                  icon: Icons.mic_outlined,
                  onTap: () {},
                ),
                const SizedBox(width: 6),

                // Send button
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B5E43),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B5E43).withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isAI;
  final String text;

  const _ChatBubble({
    required this.isAI,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isAI ? 4 : 20),
      bottomRight: Radius.circular(isAI ? 20 : 4),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.74,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isAI
              ? const Color(0xFF263F2C).withOpacity(0.94)
              : Colors.white.withOpacity(0.94),
          borderRadius: borderRadius,
          border: Border.all(
            color: isAI
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.7),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Text(
                text,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isAI ? Colors.white : const Color(0xFF1F2C24),
                  height: 1.45,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBubble extends StatelessWidget {
  final Widget child;
  final bool isAI;
  const _GlassBubble({required this.child, required this.isAI});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isAI
                ? const Color(0xFF3B5E43).withOpacity(0.8)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InputIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _InputIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: Colors.white70,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class SeedRewardDialog extends StatelessWidget {
  final int earnedSeeds;
  final int oldSeeds;
  final int newSeeds;

  const SeedRewardDialog({
    super.key,
    required this.earnedSeeds,
    required this.oldSeeds,
    required this.newSeeds,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🌱 +$earnedSeeds Seeds',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF263F2C),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5EF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(
                    'Seeds',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF5A685D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$oldSeeds → $newSeeds',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3B5E43),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5E43),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
