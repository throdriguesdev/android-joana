import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart'; // Para carregar os dados das paradas

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Map<String, String> _lineNames = {
    // Definição das linhas como antes
  };

  bool _showBuses = true;
  bool _showStops = true;

  Future<List<dynamic>> _fetchBusData() async {
    try {
      final response = await http.get(Uri.parse('https://dados.mobilidade.rio/gps/brt'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['veiculos']; // Acessando a lista de veículos
      } else {
        throw Exception('Falha ao carregar dados dos ônibus');
      }
    } catch (e) {
      print('Erro ao buscar dados dos ônibus: $e');
      return [];
    }
  }

  Future<List<dynamic>> _loadStopsData() async {
    try {
      final String response = await rootBundle.loadString('assets/brt_stations.json');
      final data = jsonDecode(response);
      return data; // Acessando a lista de paradas
    } catch (e) {
      print('Erro ao carregar dados das paradas: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ônibus no Mapa'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case 'Paradas':
                    _showBuses = false;
                    _showStops = true;
                    break;
                  case 'Linhas':
                    _showBuses = true;
                    _showStops = false;
                    break;
                  case 'Ambos':
                    _showBuses = true;
                    _showStops = true;
                    break;
                }
              });
            },
            itemBuilder: (BuildContext context) {
              return {'Paradas', 'Linhas', 'Ambos'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([_fetchBusData(), _loadStopsData()]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar dados'));
          } else {
            final busData = snapshot.data![0] ?? [];
            final stopsData = snapshot.data![1] ?? [];

            print('Dados dos ônibus: $busData'); // Debugging
            print('Dados das paradas: $stopsData'); // Debugging

            return FlutterMap(
              options: MapOptions(
                center: LatLng(-22.9068, -43.1729), // Localização inicial
                zoom: 12,
              ),
              nonRotatedChildren: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    if (_showBuses) ...busData.map((bus) {
                      final code = bus['linha'];
                      final name = _lineNames[code] ?? 'Desconhecida'; // Nome da linha

                      return Marker(
                        width: 40.0,
                        height: 40.0,
                        point: LatLng(bus['latitude'], bus['longitude']),
                        builder: (ctx) => GestureDetector(
                          onTap: () {
                            _showBusDetails(context, name, bus);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.directions_bus, color: Colors.white, size: 30),
                          ),
                        ),
                      );
                    }).toList(),
                    if (_showStops) ...stopsData.map((stop) {
                      return Marker(
                        width: 40.0,
                        height: 40.0,
                        point: LatLng(stop['coordenada'][1], stop['coordenada'][0]),
                        builder: (ctx) => GestureDetector(
                          onTap: () {
                            _showStopDetails(context, stop);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 30),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void _showBusDetails(BuildContext context, String lineName, Map<String, dynamic> bus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalhes do Ônibus ${bus['codigo']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Linha: $lineName'),
              Text('Placa: ${bus['placa'] ?? 'N/A'}'),
              Text('Velocidade: ${bus['velocidade']} km/h'),
              Text('Trajeto: ${bus['trajeto'] ?? 'N/A'}'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showStopDetails(BuildContext context, Map<String, dynamic> stop) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Parada: ${stop['nome']}'),
          content: SizedBox(
            width: 250,
            child: Text('Nome da parada: ${stop['nome']}'),
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
