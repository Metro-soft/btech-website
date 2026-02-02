import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/admin_theme.dart';
import '../services/admin_audit_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/constants/api_constants.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  final AdminAuditService _auditService = AdminAuditService();
  late IO.Socket socket;

  List<dynamic> _logs = [];
  bool _isLoading = true;
  String? _selectedTopic;

  final List<String> _topics = [
    'All',
    'auth',
    'security',
    'finance',
    'system',
    'admin'
  ];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.on('audit_log', (data) {
      if (mounted) {
        setState(() {
          _logs.insert(0, data);
        });
      }
    });
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs({String? topic}) async {
    setState(() => _isLoading = true);
    try {
      final response = await _auditService.getLogs(
        page: 1, // Always fetch page 1 for now (latest)
        limit: 1000, // Console mode: Fetch large batch
        topic: topic == 'All' ? null : topic,
      );

      setState(() {
        _logs = response['logs'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error cleanly
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: $e"), backgroundColor: AdminTheme.dangerRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("System Audit Logs", style: AdminTheme.header),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(
                      Icons
                          .terminal, // Changed icon to terminal to reflect mode
                      size: 16,
                      color: AdminTheme.primaryAccent),
                  const SizedBox(width: 8),
                  Text("Live Console", // Changed label
                      style: GoogleFonts.outfit(
                          color: AdminTheme.primaryAccent, fontSize: 12))
                ],
              ),
            )
          ],
        ),

        const SizedBox(height: 20),

        // Filter Bar
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _topics.length,
            separatorBuilder: (c, i) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final topic = _topics[index];
              final isSelected = _selectedTopic == topic ||
                  (_selectedTopic == null && topic == 'All');
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTopic = topic;
                  });
                  _fetchLogs(topic: topic);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: isSelected
                          ? AdminTheme.primaryAccent
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected
                              ? AdminTheme.primaryAccent
                              : Colors.white12)),
                  child: Center(
                    child: Text(
                      topic.toUpperCase(),
                      style: TextStyle(
                          color: isSelected
                              ? AdminTheme.background
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Logs Table
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AdminTheme.primaryAccent))
              : Container(
                  decoration: AdminTheme.glassDecoration,
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 6), // COMPACT HEADER
                        decoration: const BoxDecoration(
                            color: Colors.white10, // Distinct Header Background
                            border: Border(
                                bottom: BorderSide(color: Colors.white24))),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                                flex: 1,
                                child: Text("#",
                                    style: GoogleFonts.robotoMono(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                            Container(
                                width: 1,
                                height: 16,
                                color: Colors.white24), // DIVIDER
                            const SizedBox(width: 8),
                            Expanded(
                                flex: 2,
                                child: Text("TIME",
                                    style: GoogleFonts.robotoMono(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                            Container(
                                width: 1,
                                height: 16,
                                color: Colors.white24), // DIVIDER
                            const SizedBox(width: 8),
                            Expanded(
                                flex: 1,
                                child: Text("BUFFER",
                                    style: GoogleFonts.robotoMono(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                            Container(
                                width: 1,
                                height: 16,
                                color: Colors.white24), // DIVIDER
                            const SizedBox(width: 8),
                            Expanded(
                                flex: 2,
                                child: Text("TOPICS",
                                    style: GoogleFonts.robotoMono(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                            Container(
                                width: 1,
                                height: 16,
                                color: Colors.white24), // DIVIDER
                            const SizedBox(width: 8),
                            Expanded(
                                flex: 6, // Expanded to take IP space
                                child: Text("MESSAGE",
                                    style: GoogleFonts.robotoMono(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),

                      // List
                      Expanded(
                        child: _logs.isEmpty
                            ? Center(
                                child: Text("No logs found",
                                    style: GoogleFonts.robotoMono(
                                        color: Colors.white70)))
                            : ListView.separated(
                                reverse: true, // Newest at bottom
                                itemCount: _logs.length,
                                separatorBuilder: (c, i) => const Divider(
                                    color: Colors.white10,
                                    height: 1), // GRID LINE
                                itemBuilder: (context, index) {
                                  final log = _logs[index];
                                  final topics =
                                      (log['topics'] as List?)?.join(', ') ??
                                          'N/A';
                                  final isCritical =
                                      topics.contains('critical');

                                  // Calculate chronological number (1 = Oldest)
                                  final number = _logs.length - index;

                                  // Construct Message (Mikrotik style: User (IP): Action Resource)
                                  final ip = log['ipAddress'] ?? 'Unknown';

                                  String nameStr = 'System';
                                  String idStr = '';
                                  Map<String, dynamic>? userMap;
                                  bool isClickable = false;

                                  if (log['user'] is Map) {
                                    userMap = log['user'];
                                    nameStr = userMap!['name'] ??
                                        userMap['email'] ??
                                        'User';
                                    final id = userMap['_id']?.toString();
                                    final idSuffix =
                                        id != null && id.length >= 6
                                            ? id.substring(id.length - 6)
                                            : (id ?? 'NA');
                                    idStr = " (ID:$idSuffix)";
                                    isClickable = true;
                                  } else if (log['user'] is String) {
                                    nameStr = 'User';
                                    final userString = log['user'].toString();
                                    final idSuffix = userString.length >= 6
                                        ? userString
                                            .substring(userString.length - 6)
                                        : userString;
                                    idStr = " (ID:$idSuffix)";
                                  }

                                  String action =
                                      log['action']?.toString() ?? 'EVENT';

                                  // Smart Action Derivation (if action is missing or generic)
                                  if (action == 'EVENT') {
                                    final topicsRaw = (log['topics'] as List?)
                                            ?.map((e) =>
                                                e.toString().toLowerCase())
                                            .toList() ??
                                        [];
                                    if (topicsRaw.contains('login'))
                                      action = 'LOGIN';
                                    else if (topicsRaw.contains('logout'))
                                      action = 'LOGOUT';
                                    else if (topicsRaw.contains('sqli'))
                                      action = 'SQL_INJECTION';
                                    else if (topicsRaw.contains('dos'))
                                      action = 'DOS_ATTACK';
                                    else if (topicsRaw.contains('bruteforce'))
                                      action = 'BRUTE_FORCE';
                                    else if (topicsRaw.contains('create'))
                                      action = 'CREATE';
                                    else if (topicsRaw.contains('update'))
                                      action = 'UPDATE';
                                    else if (topicsRaw.contains('delete'))
                                      action = 'DELETE';
                                    else if (topicsRaw.contains('payment'))
                                      action = 'PAYMENT';
                                    else if (topicsRaw.contains('auth'))
                                      action = 'AUTH';
                                  }

                                  final resource = log['resource'] ?? '';
                                  // Support older logs where 'message' might have been used instead of 'description'
                                  String? desc =
                                      log['description'] ?? log['message'];

                                  // SMART CLEANUP: Standardize historical messages to remove redundancy
                                  if (desc != null) {
                                    if (desc.startsWith("User ") &&
                                        desc.contains(" logged in")) {
                                      desc = "Login successful";
                                    }
                                  }

                                  // Always use structured format: User [IP]: Content
                                  final content = desc ?? "$action $resource";
                                  final suffix = " [$ip]: $content";
                                  final fullMessage = "$nameStr$idStr$suffix";

                                  return Container(
                                    color: isCritical
                                        ? AdminTheme.dangerRed.withOpacity(0.1)
                                        : index % 2 == 0
                                            ? Colors.white.withOpacity(
                                                0.02) // Zebra striping
                                            : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 0,
                                        vertical: 2), // ULTRA COMPACT PADDING
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 8),
                                        Expanded(
                                            flex: 1,
                                            child: Text("$number",
                                                style: GoogleFonts.robotoMono(
                                                    color: Colors.white38,
                                                    fontSize: 11))),
                                        Container(
                                            width: 1,
                                            height: 14,
                                            color: Colors.white12), // DIVIDER
                                        const SizedBox(width: 8),
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                                _formatTimestamp(
                                                    log['timestamp']),
                                                style: GoogleFonts.robotoMono(
                                                    color: AdminTheme
                                                        .primaryAccent,
                                                    fontSize: 11))),
                                        Container(
                                            width: 1,
                                            height: 14,
                                            color: Colors.white12), // DIVIDER
                                        const SizedBox(width: 8),
                                        Expanded(
                                            flex: 1,
                                            child: Text(log['buffer'] ?? 'db',
                                                style: GoogleFonts.robotoMono(
                                                    color: Colors.white70,
                                                    fontSize: 11))),
                                        Container(
                                            width: 1,
                                            height: 14,
                                            color: Colors.white12), // DIVIDER
                                        const SizedBox(width: 8),
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                                topics, // Raw topics text for compactness
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.robotoMono(
                                                    color: isCritical
                                                        ? AdminTheme.dangerRed
                                                        : Colors.white70,
                                                    fontSize: 11))),
                                        Container(
                                            width: 1,
                                            height: 14,
                                            color: Colors.white12), // DIVIDER
                                        const SizedBox(width: 8),
                                        Expanded(
                                            flex:
                                                6, // Expanded to take IP space
                                            child: Tooltip(
                                              message: fullMessage,
                                              child: isClickable
                                                  ? RichText(
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      text: TextSpan(children: [
                                                        TextSpan(
                                                          text: nameStr,
                                                          style: GoogleFonts
                                                              .robotoMono(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text: idStr,
                                                          style: GoogleFonts
                                                              .robotoMono(
                                                                  color: AdminTheme
                                                                      .primaryAccent, // Link Color
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  decoration:
                                                                      TextDecoration
                                                                          .underline),
                                                          recognizer:
                                                              TapGestureRecognizer()
                                                                ..onTap = () {
                                                                  context.push(
                                                                      '/admin/users/details',
                                                                      extra:
                                                                          userMap);
                                                                },
                                                        ),
                                                        TextSpan(
                                                            text: suffix,
                                                            style: GoogleFonts
                                                                .robotoMono(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        11))
                                                      ]),
                                                    )
                                                  : Text(fullMessage,
                                                      style: GoogleFonts
                                                          .robotoMono(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 11),
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                            )),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Removed Pagination Controls
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('MMM/dd/yyyy HH:mm:ss').format(dt);
    } catch (e) {
      return timestamp;
    }
  }
}
