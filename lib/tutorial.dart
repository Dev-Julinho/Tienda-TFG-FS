import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _index = 0;

  final List<String> imagenes = [
    "https://185.189.221.84/tutorial/1.png",
    "https://185.189.221.84/tutorial/2.png",
    "https://185.189.221.84/tutorial/3.png",
    "https://185.189.221.84/tutorial/4.png",
    "https://185.189.221.84/tutorial/5.png",
    "https://185.189.221.84/tutorial/6.png",
    "https://185.189.221.84/tutorial/7.png",
    "https://185.189.221.84/tutorial/8.png",
    "https://185.189.221.84/tutorial/9.png",
    "https://185.189.221.84/tutorial/10.png",
    "https://185.189.221.84/tutorial/11.png",
    "https://185.189.221.84/tutorial/12.png",
  ];

  Future<void> _finalizar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("tutorial_visto", true);
    Navigator.pop(context);
  }

  void _siguiente() {
    if (_index < imagenes.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finalizar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: imagenes.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  return Center(
                    child: Image.network(
                      imagenes[i],
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _siguiente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _index == imagenes.length - 1
                        ? "Finalizar"
                        : "Siguiente",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}