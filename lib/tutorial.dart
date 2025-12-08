import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialPage extends StatefulWidget {
  final int idCliente;

  const TutorialPage({super.key, required this.idCliente});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _index = 0;

  final List<String> imagenes = List.generate(
      12, (i) => "https://185.189.221.84/tutorial/${i + 1}.png");

  Future<void> _finalizar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("tutorial_visto_${widget.idCliente}", true);
    Navigator.pop(context);
  }

  void _siguiente() {
    if (_index < imagenes.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    } else {
      _finalizar();
    }
  }

  void _anterior() {
    if (_index > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
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

            // -------- BOTONES --------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // ---- BOTÓN ANTERIOR (solo aparece si _index > 0) ----
                  if (_index > 0)
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _anterior,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Anterior",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (_index > 0) const SizedBox(width: 15),

                  // ---- BOTÓN SIGUIENTE / FINALIZAR ----
                  Expanded(
                    child: SizedBox(
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
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}