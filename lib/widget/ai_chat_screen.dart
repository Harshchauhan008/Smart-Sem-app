import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:smartsem/widget/timetable_review_screen.dart';
import '../service/api_client.dart';
import '../service/chat_service.dart';
import 'package:file_picker/file_picker.dart' as fp;

import '../service/subject_service.dart';
import '../service/timetable_import_service.dart';

class AiChatScreen extends StatefulWidget {
  final int semesterId;

  const AiChatScreen({
    super.key,
    required this.semesterId,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const Color navy = Color(0xFF102A56);
  static const Color blue = Color(0xFF2563EB);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];

  int? _conversationId;
  bool _isInitializing = true;
  bool _isSending = false;
  String? _error;

  fp.PlatformFile? _selectedFile;
  Uint8List? _selectedBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _createConversation();
  }

  Future<void> _createConversation() async {
    try {
      final id = await ChatService.createConversation(
        semesterId: widget.semesterId,
      );

      if (!mounted) return;

      setState(() {
        _conversationId = id;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending || _conversationId == null) {
      return;
    }

    _messageController.clear();

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text,
      });
      _isSending = true;
      _error = null;
    });

    _scrollToBottom();

    try {
      final response = await ChatService.sendMessage(
        conversationId: _conversationId!,
        message: text,
      );

      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': response['answer']?.toString() ??
              'I could not generate a response.',
        });
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Message failed to send. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final fp.PlatformFile? picked = await fp.FilePicker.pickFile(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      // null means the user canceled the picker
      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedFile = picked;
        _selectedBytes = bytes;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select file: $e')),
      );
    }
  }


  Future<void> _uploadSelectedFile() async {
    final file = _selectedFile;
    final bytes = _selectedBytes;

    if (file == null || bytes == null || _isUploading) return;

    // Captured now, before any waiting. The upload and the AI reading can
    // take a minute or more, and this chat widget may be rebuilt meanwhile
    // (for example when the dashboard reloads the semester). The navigator
    // and messenger belong to the app, so they still work in that case.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isUploading = true;
      _error = null;
    });

    void showSnack(String message, {int seconds = 6}) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: seconds),
        ),
      );
    }

    void addChatMessage(String text) {
      // The chat list only exists while this widget is alive.
      if (!mounted) return;

      setState(() {
        _messages.add({'role': 'assistant', 'text': text});
      });
      _scrollToBottom();
    }

    try {
      // Images are treated as timetable uploads.
      // PDFs remain ordinary academic documents.
      final isTimetableImage = _selectedIsImage;

      debugPrint('Selected file: ${file.name}');
      debugPrint('Is image: $isTimetableImage');
      debugPrint('Semester ID: ${widget.semesterId}');

      // ---- Step 1: upload the document ----
      final dynamic response;

      try {
        response = await ApiClient.uploadDocument(
          semesterId: widget.semesterId,
          fileName: file.name,
          bytes: bytes,
          documentType: isTimetableImage ? 'TIMETABLE' : 'OTHER',
        );
      } catch (e) {
        debugPrint('STEP 1 FAILED (upload): $e');
        showSnack(
          'Upload failed: ${e.toString().replaceFirst('Exception: ', '')}',
          seconds: 8,
        );
        return;
      }

      debugPrint('STEP 1 OK: document uploaded. mounted=$mounted');

      if (mounted) {
        setState(() {
          _selectedFile = null;
          _selectedBytes = null;
        });
      }

      addChatMessage(
        'Document uploaded successfully: '
            '${response['originalFileName'] ?? file.name}.',
      );

      if (!isTimetableImage) return;

      // ---- Step 2: let the AI read the timetable image ----
      debugPrint('STEP 2: starting timetable preview...');

      final List<Map<String, dynamic>> entries;

      try {
        entries = await TimetableImportService.preview(widget.semesterId);
      } catch (e) {
        // The document is already saved. Do NOT upload again; that only
        // uses more AI calls. The Schedule screen can retry the reading.
        debugPrint('STEP 2 FAILED (preview): $e');

        addChatMessage(
          'Your timetable image is saved, but I could not read it right '
              'now (the AI service may be busy). Please wait a minute, then '
              'open **Schedule** and tap the scanner icon to try again. You do '
              'not need to upload it again.',
        );
        return;
      }

      debugPrint(
        'STEP 2 OK: ${entries.length} entries found. mounted=$mounted',
      );

      if (entries.isEmpty) {
        showSnack('No timetable classes were detected.');
        return;
      }

      // ---- Step 3: the student reviews the detected classes ----
      debugPrint('STEP 3: opening review screen...');

      if (!navigator.mounted) {
        debugPrint('STEP 3 SKIPPED: navigator is gone.');
        return;
      }

      final approvedEntries =
      await navigator.push<List<Map<String, dynamic>>>(
        MaterialPageRoute(
          builder: (_) => TimetableReviewScreen(entries: entries),
        ),
      );

      debugPrint(
        'STEP 3 done. Approved entries: ${approvedEntries?.length ?? 0}',
      );

      if (approvedEntries == null || approvedEntries.isEmpty) return;

      // ---- Step 4: import the approved classes ----
      try {
        final subjects =
        await SubjectService.getSubjects(widget.semesterId);

        if (subjects.isEmpty) {
          showSnack('Add subjects to this semester before importing.');
          return;
        }

        // The backend matches each entry's subjectName to the right
        // subject of this semester, so any subject id works here.
        final saved = await TimetableImportService.importEntries(
          subjects.first.id,
          approvedEntries,
        );

        debugPrint('STEP 4 OK: $saved classes saved.');

        addChatMessage(
          'Timetable import completed. $saved classes saved successfully.',
        );
        showSnack('Imported $saved timetable classes.');
      } catch (e) {
        debugPrint('STEP 4 FAILED (import): $e');
        showSnack(
          'Import failed: ${e.toString().replaceFirst('Exception: ', '')}',
          seconds: 8,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _selectedIsImage {
    final name = _selectedFile?.name.toLowerCase() ?? '';
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFE8F0FF),
              child: Icon(Icons.auto_awesome, color: blue),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SmartSem AI',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your academic study buddy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitializing
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : _error != null && _conversationId == null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not start your conversation.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isInitializing = true;
                          _error = null;
                        });
                        _createConversation();
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
                : _messages.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: blue,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'What would you like to learn today?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ask questions about your subjects, '
                          'study materials, or college schedule.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
              _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('SmartSem is thinking...'),
                    ),
                  );
                }

                final message = _messages[index];
                final isUser = message['role'] == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth:
                      MediaQuery.sizeOf(context).width *
                          0.82,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? blue : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: isUser
                          ? null
                          : Border.all(
                        color: const Color(0xFFE6EAF0),
                      ),
                    ),
                    child: MarkdownBody(
                      data: message['text'] ?? '',
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isUser ? Colors.white : navy,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        h1: TextStyle(
                          color: isUser ? Colors.white : navy,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: TextStyle(
                          color: isUser ? Colors.white : navy,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: TextStyle(
                          color: isUser ? Colors.white : navy,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        strong: TextStyle(
                          color: isUser ? Colors.white : navy,
                          fontWeight: FontWeight.bold,
                        ),
                        listBullet: TextStyle(
                          color: isUser ? Colors.white : navy,
                          fontSize: 15,
                        ),
                        code: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_error != null && _conversationId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedFile != null && _selectedBytes != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          if (_selectedIsImage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _selectedBytes!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            const Icon(
                              Icons.picture_as_pdf_outlined,
                              color: blue,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFile!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove file',
                            onPressed: _isUploading
                                ? null
                                : () {
                              setState(() {
                                _selectedFile = null;
                                _selectedBytes = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                          FilledButton(
                            onPressed:
                            _isUploading ? null : _uploadSelectedFile,
                            child: _isUploading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Text('Upload'),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Attach PDF or image',
                        onPressed:
                        _isUploading || _isSending ? null : _pickFile,
                        icon: const Icon(
                          Icons.attach_file_rounded,
                          color: blue,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Ask SmartSem anything...',
                            filled: true,
                            fillColor: const Color(0xFFF5F7FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isSending || _conversationId == null
                            ? null
                            : _sendMessage,
                        icon: const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}