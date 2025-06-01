import 'package:ai_assitant/pallete.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'feature_box.dart';
import 'openai_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  final flutterTts = FlutterTts();
  final OpenAIService openAIService = OpenAIService();

  String lastWords = '';
  String? displayedSentence;
  String? generatedContent;
  String? generatedImageUrl;
  bool isProcessing = false; // New state to track AI processing

  int start = 200;
  int delay = 200;

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setSharedInstance(true);
    setState(() {});
  }

  Future<bool> requestMicPermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> initSpeechToText() async {
    bool hasPermission = await requestMicPermission();
    if (hasPermission) {
      await speechToText.initialize(
        onError: (error) => print('Speech-to-Text Error: $error'),
      );
      setState(() {});
    } else {
      print('Microphone permission denied');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission is required for voice input')),
      );
    }
  }

  Future<void> startListening() async {
    print('Starting to listen...');
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  Future<void> stopListening() async {
    print('Stopping listening...');
    await speechToText.stop();
    setState(() {
      displayedSentence = null; // Clear displayed sentence when listening stops
    });
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
      displayedSentence = _getLastSentence(lastWords);
      print('Recognized words: $lastWords');
      print('Displayed sentence: $displayedSentence');
    });
  }

  String? _getLastSentence(String text) {
    if (text.isEmpty) return null;
    final sentences = text.split(RegExp(r'[.!?]+'));
    final validSentences = sentences.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return validSentences.isNotEmpty ? validSentences.last : null;
  }

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: BounceInDown(
          child: const Text("AI Assistant"),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Virtual Assistant Picture
            ZoomIn(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      margin: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        color: Pallete.assistantCircleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    height: 125,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/virtualAssistant.png'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // User's Spoken Text
            FadeInLeft(
              child: Visibility(
                visible: displayedSentence != null && speechToText.isListening,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 40).copyWith(top: 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Pallete.borderColor,
                    ),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      topRight: Radius.zero,
                    ),
                    color: Pallete.secondSuggestionBoxColor.withOpacity(0.1),
                  ),
                  child: Text(
                    displayedSentence ?? 'Listening...',
                    style: const TextStyle(
                      color: Pallete.mainFontColor,
                      fontSize: 16,
                      fontFamily: 'Cera Pro',
                    ),
                  ),
                ),
              ),
            ),
            // AI Thinking Indicator
            FadeInRight(
              child: Visibility(
                visible: isProcessing,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 40).copyWith(top: 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Pallete.borderColor,
                    ),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      topLeft: Radius.zero,
                    ),
                    color: Pallete.firstSuggestionBoxColor.withOpacity(0.1),
                  ),
                  child: const Text(
                    'AI is thinking...',
                    style: TextStyle(
                      color: Pallete.mainFontColor,
                      fontSize: 16,
                      fontFamily: 'Cera Pro',
                    ),
                  ),
                ),
              ),
            ),
            // Chat Bubble (AI Response)
            FadeInRight(
              child: Visibility(
                visible: generatedImageUrl == null && !isProcessing,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 40).copyWith(
                    top: 30,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Pallete.borderColor,
                    ),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      topLeft: Radius.zero,
                    ),
                  ),
                  child: Text(
                    generatedContent == null
                        ? "Good Morning, What task can I do for you?"
                        : generatedContent!,
                    style: TextStyle(
                      color: Pallete.mainFontColor,
                      fontSize: generatedContent == null ? 25 : 16,
                      fontFamily: 'Cera Pro',
                    ),
                  ),
                ),
              ),
            ),
            if (generatedImageUrl != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(generatedImageUrl!),
                ),
              ),
            SlideInLeft(
              child: Visibility(
                visible: generatedContent == null && generatedImageUrl == null && !isProcessing,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(
                    top: 10,
                    left: 22,
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Here are a few features",
                    style: TextStyle(
                      fontFamily: "Cera Pro",
                      color: Pallete.mainFontColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Features List
            Visibility(
              visible: generatedContent == null && generatedImageUrl == null && !isProcessing,
              child: Column(
                children: [
                  SlideInLeft(
                    delay: Duration(milliseconds: start),
                    child: const FeatureBox(
                      color: Pallete.firstSuggestionBoxColor,
                      headerText: 'ChatGPT',
                      descText: 'A smarter way to stay organized and informed with ChatGPT',
                    ),
                  ),
                  SlideInLeft(
                    delay: Duration(milliseconds: start + delay),
                    child: const FeatureBox(
                      color: Pallete.secondSuggestionBoxColor,
                      headerText: 'Dall-E',
                      descText: 'Get inspired and stay creative with your personal assistant powered by Dall-E',
                    ),
                  ),
                  SlideInLeft(
                    delay: Duration(milliseconds: start + 6 * delay),
                    child: const FeatureBox(
                      color: Pallete.thirdSuggestionBoxColor,
                      headerText: 'Smart Voice Assistant',
                      descText: 'Get the best of both worlds with a voice assistant powered by Dall-E and ChatGPT',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ZoomIn(
        delay: Duration(milliseconds: start + 3 * delay),
        child: FloatingActionButton(
          backgroundColor: Pallete.firstSuggestionBoxColor,
          onPressed: () async {
            if (await speechToText.hasPermission && speechToText.isNotListening) {
              await startListening();
            } else if (speechToText.isListening) {
              setState(() {
                isProcessing = true; // Show thinking indicator
              });
              try {
                final speech = await openAIService.isArtPromptAPI(lastWords);
                setState(() {
                  if (speech.contains('https')) {
                    generatedImageUrl = speech;
                    generatedContent = null;
                  } else {
                    generatedImageUrl = null;
                    generatedContent = speech;
                    systemSpeak(speech); // Speak the response
                  }
                  isProcessing = false; // Hide thinking indicator
                });
              } catch (e) {
                print('Error processing speech: $e');
                setState(() {
                  isProcessing = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error processing request')),
                );
              }
              await stopListening();
            } else {
              initSpeechToText();
            }
          },
          child: Icon(speechToText.isListening ? Icons.mic_off : Icons.mic),
        ),
      ),
    );
  }
}