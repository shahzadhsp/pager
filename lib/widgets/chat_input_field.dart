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

  // void _initSpeech() async {
  //   try {
  //     _speechAvailable = await _speechToText.initialize(
  //       onError: (error) => print('Speech recognition error: $error'),
  //       onStatus: (status) => print('Speech recognition status: $status'),
  //     );
  //     if (mounted) setState(() {});
  //   } catch (e) {
  //     print("Error initializing speech to text: $e");
  //     setState(() => _speechAvailable = false);
  //   }
  // }
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

  // Future<void> _startListening() async {
  //   if (!_speechAvailable) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('voiceRecognition'.tr())));
  //     return;
  //   }
  //   var microphoneStatus = await Permission.microphone.request();
  //   if (!microphoneStatus.isGranted) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('microphonePermission'.tr())));
  //     return;
  //   }
  //   if (_isListening) return;
  //   await _speechToText.listen(
  //     onResult: (result) {
  //       if (mounted) {
  //         setState(() {
  //           _textController.text = result.recognizedWords;
  //           // Move o cursor para o final do texto
  //           _textController.selection = TextSelection.fromPosition(
  //             TextPosition(offset: _textController.text.length),
  //           );
  //         });
  //       }
  //     },
  //     localeId: 'pt_BR',
  //     // Define o idioma para Português do Brasil
  //     // Set the language to Brazilian Portuguese.
  //     listenFor: const Duration(seconds: 10),
  //     // Limite de tempo para a gravação
  //     // Time limit for the recording.
  //     pauseFor: const Duration(seconds: 3),
  //     // Pausa após 3s de silêncio
  //     // Pause after 3 seconds of silence.”
  //   );
  //   if (mounted) setState(() => _isListening = true);
  // }

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
      localeId: 'pt_BR',
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _textController.text = result.recognizedWords;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
      },
    );
  }

  // Future<void> _stopListening() async {
  //   if (!_isListening) return;
  //   await _speechToText.stop();
  //   if (mounted) setState(() => _isListening = false);
  // }
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

  // Widget _buildSendOrMicButton(ThemeData theme) {
  //   if (_hasText) {
  //     return IconButton.filled(
  //       style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primary),
  //       icon: const Icon(Icons.send),
  //       onPressed: _handleSend,
  //     );
  //   } else {
  //     return GestureDetector(
  //       onLongPress: _startListening,
  //       onLongPressUp: _stopListening,
  //       child: IconButton.filled(
  //         style: IconButton.styleFrom(
  //           backgroundColor: _isListening
  //               ? theme.colorScheme.error
  //               : theme.colorScheme.primary,
  //         ),
  //         icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
  //         onPressed: () {
  //           // Um clique curto no microfone informa o utilizador sobre como usar
  //           ScaffoldMessenger.of(context).removeCurrentSnackBar();
  //           ScaffoldMessenger.of(
  //             context,
  //           ).showSnackBar(SnackBar(content: Text('pressAndHold'.tr())));
  //         },
  //       ),
  //     );
  //   }
  // }
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
