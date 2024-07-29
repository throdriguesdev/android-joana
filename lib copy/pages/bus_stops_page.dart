import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class BusStopsPage extends StatelessWidget {
  const BusStopsPage({super.key});

  Future<List<dynamic>> _loadBusStops() async {
    final String response = await rootBundle.loadString('assets/brt_stations.json');
    return jsonDecode(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paradas de Ônibus'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _loadBusStops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar dados'));
          } else {
            final busStops = snapshot.data!;
            return ListView.builder(
              itemCount: busStops.length,
              itemBuilder: (context, index) {
                final stop = busStops[index];
                final name = stop['nome'];
                final latitude = stop['coordenada'][1];
                final longitude = stop['coordenada'][0];

                return ListTile(
                  title: Text(name),
                  subtitle: Text('Coordenadas: ($latitude, $longitude)'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
