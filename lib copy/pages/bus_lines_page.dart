import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BusLinesPage extends StatefulWidget {
  const BusLinesPage({super.key});

  @override
  _BusLinesPageState createState() => _BusLinesPageState();
}

class _BusLinesPageState extends State<BusLinesPage> {
  final Map<String, String> _lineNames = {
    '10': 'Terminal Santa Cruz ↔ Terminal Alvorada EXPRESSO',
    // Adicione outras linhas conforme necessário
  };

  Future<List<dynamic>> _fetchBusLines() async {
    final response = await http.get(Uri.parse('https://dados.mobilidade.rio/gps/brt'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['veiculos']; // Acessando a lista de veículos
    } else {
      throw Exception('Falha ao carregar linhas de ônibus');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linhas de Ônibus'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchBusLines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar dados'));
          } else {
            final busLines = snapshot.data!;
            return ListView.builder(
              itemCount: busLines.length,
              itemBuilder: (context, index) {
                final line = busLines[index];
                final code = line['linha'];
                final name = _lineNames[code] ?? 'Desconhecida'; // Nome da linha do mapa

                return ListTile(
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código: ${line['codigo']}'),
                      Text('Placa: ${line['placa'] ?? 'N/A'}'),
                      Text('Trajeto: ${line['trajeto'] ?? 'N/A'}'),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
