import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import '../providers/propiedades_provider.dart';

class VoiceAssistantDialog extends StatefulWidget {
  const VoiceAssistantDialog({super.key});

  @override
  State<VoiceAssistantDialog> createState() => _VoiceAssistantDialogState();
}

class _VoiceAssistantDialogState extends State<VoiceAssistantDialog> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Toca el micrófono y empieza a hablar...';
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _processCommand(_text);
          }
        },
        onError: (val) => setState(() {
          _isListening = false;
          _text = 'Error: No se pudo reconocer la voz';
        }),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
          localeId: 'es_ES',
        );
      } else {
        setState(() {
          _isListening = false;
          _text = 'Permisos de micrófono denegados.';
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _processCommand(_text);
    }
  }

  bool _isProcessing = false;

  void _processCommand(String text) {
    if (_isProcessing) return;
    if (text.isEmpty || text == 'Toca el micrófono y empieza a hablar...') return;
    
    _isProcessing = true;
    final lowerText = text.toLowerCase();
    String? tipoOp;
    String? est;

    if (lowerText.contains('venta')) {
      tipoOp = 'Venta';
    } else if (lowerText.contains('alquiler') || lowerText.contains('alquilar')) {
      tipoOp = 'Alquiler';
    }

    if (lowerText.contains('disponible')) {
      est = 'Disponible';
    } else if (lowerText.contains('vendida')) {
      est = 'Vendida';
    }

    if (tipoOp != null || est != null) {
      context.read<PropiedadesProvider>().setFiltros(
        tipoOp: tipoOp,
        est: est,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filtro aplicado por voz: ${tipoOp ?? ''} ${est ?? ''}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Cerrar el diálogo si fue exitoso
    } else {
      setState(() {
        _text = '"$text"\nNo entendí el comando. Prueba diciendo "buscar casas en alquiler" o "ver propiedades en venta".';
      });
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Asistente de Voz',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _text,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _listen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isListening ? 100 : 80,
                width: _isListening ? 100 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    if (_isListening)
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isListening ? 'Escuchando...' : 'Presiona para hablar',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
