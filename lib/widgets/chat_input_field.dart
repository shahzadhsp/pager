import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  const ChatInputField({super.key, required this.onSendMessage});
  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _hasText = false;
  bool _speechAvailable = false;
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _textController.addListener(() {
      if (mounted) {
        setState(() {
          _hasText = _textController.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _initSpeech() async {
    _speechAvailable = await _speechToText.initialize(
      onError: (error) {
        log('Speech error: $error');
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
      onStatus: (status) {
        log('Speech status: $status');
        if (status == 'notListening' || status == 'done') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    if (!_speechAvailable) {
      log('Speech not available');
      return;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      log('Mic permission denied');
      return;
    }

    setState(() => _isListening = true);

    await _speechToText.listen(
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 7),
      // cancelOnError: true,
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.confirmation,

      onResult: (result) {
        if (!mounted) return;

        log('--- SPEECH RESULT ---');
        log('Recognized Words: ${result.recognizedWords}');
        log('Confidence: ${result.confidence}');
        log('Final Result: ${result.finalResult}');

        setState(() {
          _textController.text = result.recognizedWords;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
      },
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;

    await _speechToText.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _handleSend() {
    if (_textController.text.trim().isNotEmpty) {
      widget.onSendMessage(_textController.text.trim());
      _textController.clear();
      if (mounted) setState(() {});
    }
    _stopListening();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8.0,
      color: theme.cardColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: _isListening
                      ? 'listening'.tr()
                      : 'writeMessage'.tr(),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                minLines: 1,
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8.0),
            _buildSendOrMicButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSendOrMicButton(ThemeData theme) {
    if (_hasText) {
      return IconButton.filled(
        style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primary),
        icon: const Icon(Icons.send),
        onPressed: _handleSend,
      );
    }

    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: _isListening
            ? theme.colorScheme.error
            : theme.colorScheme.primary,
      ),
      icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
      onPressed: () {
        if (_isListening) {
          _stopListening();
        } else {
          _startListening();
        }
      },
    );
  }
}
