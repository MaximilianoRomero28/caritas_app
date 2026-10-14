import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class FinanzasScreen extends StatefulWidget{
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState()=> _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  final String _baseUrl = "10.0.2.2:8000";
  final int _cajaPrincipalId = 1; // Cáritas maneja una única caja física central

  double _saldoActual = 0.0;
  List<dynamic> _historialMovimientos = [];
  bool _cargandoCaja = true;

  @override
  void initState() {
    super.initState();
    _fetchDatosCaja();
  }

  // 📡 1. Traer Estado de la Caja y Movimientos
  Future<void> _fetchDatosCaja() async {

    setState(() => _cargandoCaja = true);

    final url=Uri.http(_baseUrl,"/v1/admin/caja/todo");

    try {

      final responseCaja = await http.get(url);

      if (responseCaja.statusCode == 200) {
        final data = convert.jsonDecode(responseCaja.body);
        setState(() {
          _saldoActual = (data['monto'] as num).toDouble();
          // Mock temporal de movimientos hasta que vincules el listado del historial
          _historialMovimientos = data['movimientos'] ?? [];
          _cargandoCaja = false;
        });
      }
    } catch (e) {
      setState(() => _cargandoCaja = false);
      _mostrarSnackBar("Error al conectar con la caja de Cáritas", Colors.redAccent);
    }
  }

  // 📡 2. Registrar Ingreso (PATCH /v1/admin/agregar/{caja_id})
  Future<void> _apiAgregarDinero(double monto, String medio) async {
    
    final url=Uri.http(_baseUrl,"/v1/admin/caja/ingresar");

    try {
      final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: convert.jsonEncode({
          "cantidad_monto": monto,
          "medio": medio,
        }),
      );

      if (response.statusCode == 200) {
        _mostrarSnackBar("Dinero ingresado con éxito", const Color(0xFF10B981));
        _fetchDatosCaja(); // Recarga el saldo actual y feed
      }
    } catch (e) {
      _mostrarSnackBar("Error de red al sumar dinero", Colors.redAccent);
    }
  }

  // 📡 3. Registrar Retiro / Gasto (PATCH /v1/admin/retirar/{caja_id})
  Future<void> _apiRetirarDinero(double monto, String destino) async {
    
    final url= Uri.http(_baseUrl,"/v1/admin/retiro/$_cajaPrincipalId");

    try {
      final response = await http.patch(url,
        headers: {"Content-Type": "application/json"},
        body: convert.jsonEncode({
          "monto": monto,
          "destino": destino,
        }),
      );

      if (response.statusCode == 200) {
        _mostrarSnackBar("Gasto asentado correctamente", const Color(0xFF10B981));
        _fetchDatosCaja();
      } else {
        final errorData = convert.jsonEncode(response.body);
        _mostrarSnackBar("$errorData['detail']", Colors.orangeAccent);
      }
    } catch (e) {
      _mostrarSnackBar("Error de red al procesar el retiro", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Caja de la Parroquia', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _cargandoCaja
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 💳 TARJETA PREMIUM DE SALDO (Estilo Fintech)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)], // Azul cobalto a marino profundo
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SALDO DISPONIBLE",
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "\$${_saldoActual.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🎛️ BOTONES DE ACCIÓN RÁPIDA (Lado a lado, optimizando espacio)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _abrirDialogoAccionCaja(esIngreso: true),
                          icon: const Icon(Icons.arrow_upward_rounded),
                          label: const Text("Ingresar", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _abrirDialogoAccionCaja(esIngreso: false),
                          icon: const Icon(Icons.arrow_downward_rounded),
                          label: const Text("Gastar", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 24.0, bottom: 12.0),
                  child: Text("Movimientos Recientes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),

                // 📜 FEED VERTICAL DE HISTORIAL DE MOVIMIENTOS
                Expanded(
                  child: _historialMovimientos.isEmpty
                      ? const Center(child: Text("No se registraron movimientos todavía"))
                      : ListView.builder(
                          itemCount: _historialMovimientos.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final mov = _historialMovimientos[index];
                            final bool esIngreso = mov['tipo'] == "INGRESO";

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Card(
                                color: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade100),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: esIngreso ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.orangeAccent.withValues(alpha: 0.1),
                                    child: Icon(
                                      esIngreso ? Icons.add_rounded : Icons.remove_rounded,
                                      color: esIngreso ? const Color(0xFF10B981) : Colors.orangeAccent,
                                    ),
                                  ),
                                  title: Text(mov['detalle'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    (mov['fecha'] ?? '').toString().split('T').first, 
                                    style: const TextStyle(fontSize: 12)),
                                  trailing: Text(
                                    "${esIngreso ? '+' : '-'} \$${mov['monto']}",
                                    style: TextStyle(
                                      color: esIngreso ? const Color(0xFF10B981) : Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
    );
  }

  // 📝 Emergente dinámico único para Ingresar o Gastar dinero según la bandera
  void _abrirDialogoAccionCaja({required bool esIngreso}) {
    final TextEditingController montoController = TextEditingController();
    final TextEditingController detalleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(esIngreso ? "Registrar Ingreso" : "Registrar Egreso / Gasto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Monto (\$)", prefixText: "\$ "),
            ),
            TextField(
              controller: detalleController,
              decoration: InputDecoration(
                labelText: esIngreso ? "Medio u Origen (ej: Bono Contribución)" : "Destino del gasto (ej: Librería)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: esIngreso ? const Color(0xFF10B981) : Colors.orangeAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final double money = double.tryParse(montoController.text) ?? 0.0;
              final String det = detalleController.text.trim();
              Navigator.pop(context);

              if (money > 0 && det.isNotEmpty) {
                if (esIngreso) {
                  _apiAgregarDinero(money, det);
                } else {
                  _apiRetirarDinero(money, det);
                }
              }
            },
            child: const Text("Confirmar"),
          )
        ],
      ),
    );
  }

  void _mostrarSnackBar(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto), 
        backgroundColor: color, 
        duration: const Duration(seconds: 3)
      )
    );
  }
}

