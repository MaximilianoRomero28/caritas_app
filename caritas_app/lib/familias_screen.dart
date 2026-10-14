import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class FamiliasScreen extends StatefulWidget{
  const FamiliasScreen({super.key});

  @override
  State<FamiliasScreen> createState() => _FamiliasScreenState();
}

class _FamiliasScreenState extends State<FamiliasScreen> {
  final String _baseUrl = "10.0.2.2:8000";
  
  List<dynamic> _familias = [];
  bool _cargandoFamilias = true;

  @override
  void initState() {
    super.initState();
    _fetchFamilias(); // Carga las familias al iniciar
  }

  //1. Traer listado de Familias (GET /v1/admin/familias)
  Future<void> _fetchFamilias() async {

    final url= Uri.http(_baseUrl,"/v1/admin/familias/listar");
    try {
      setState(() => _cargandoFamilias = true);
     
      final response = await http.get(url);

      if (response.statusCode == 200) {

        final datos= convert.jsonDecode(response.body);

        setState(() {
          _familias = datos['familia'];
          _cargandoFamilias = false;
        });
      } else {
        
        setState(() {
          _familias = [];
          _cargandoFamilias = false;
        });
      }
    } catch (e) {
      setState(() => _cargandoFamilias = false);
      _mostrarSnackBar("Error de conexión al cargar familias", Colors.redAccent);
    }
  }

  //2. Cargar Nueva Familia (POST /v1/admin/familia/cargar)
  Future<void> _apiCargarFamilia(String nombre, String direccion, int integrantes) async {
    
    final url=Uri.http(_baseUrl,"/v1/admin/familia/cargar");
    
    try {
      final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: convert.jsonEncode({
          "nombre": nombre,
          "direccion": direccion,
          "integrantes": integrantes,
        }),
      );

      if (response.statusCode == 201) {
        _mostrarSnackBar("Familia registrada con éxito", const Color(0xFF10B981));
        _fetchFamilias(); // Recarga la lista de contactos
      }
    } catch (e) {
      _mostrarSnackBar("Error de red al registrar familia", Colors.redAccent);
    }
  }

  //3. Eliminar Familia en Cascada (DELETE /v1/admin/{id}/eliminar)
  Future<void> _apiEliminarFamilia(int familiaId) async {

    final url= Uri.http(_baseUrl,"/v1/admin/$familiaId/eliminar");
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        _mostrarSnackBar("Familia e historial eliminados", Colors.blueGrey);
        _fetchFamilias();
      }
    } catch (e) {
      _mostrarSnackBar("Error de red al intentar borrar la familia", Colors.redAccent);
    }
  }


  Future<Map<String, dynamic>> _fetchHistorialFamilia(int familiaId) async {
    try {
      
      final url = Uri.http(_baseUrl, '/v1/admin/historial/familia/$familiaId', {
        'limit': '50',
        'offset': '0'
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return convert.jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error al traer historial de familia: $e");
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Familias Asistidas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _cargandoFamilias
          ? const Center(child: CircularProgressIndicator())
          : _familias.isEmpty
              ? const Center(child: Text("No hay familias cargadas en el sistema"))
              : ListView.builder(
                  itemCount: _familias.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final fam = _familias[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(fam['nombre_familia'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: Text("${fam['direccion']} • ${fam['integrantes']} integrantes", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: ()  => _mostrarOpcionesFamilia(fam),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialogoCrearFamilia(),
        label: const Text('Nueva Familia'),
        icon: const Icon(Icons.person_add_alt_1),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  //Hoja inferior de control de la Familia seleccionada
  void _mostrarOpcionesFamilia(Map<String, dynamic> fam) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Usamos la clave que venga de tu backend ('nombre_familia' o 'nombre_family')
                        Text(fam['nombre_familia'] ?? fam['nombre_familia'] ?? 'Familia', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        Text(fam['direccion'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(context);
                      _apiEliminarFamilia(fam['id']);
                    },
                  )
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700, // Color formal a tono con el historial de productos
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Cierra el modal de opciones
                    _abrirPantallaHistorialFamilia(fam); // Abre el feed del nuevo endpoint
                  },
                  icon: const Icon(Icons.history_rounded),
                  label: const Text("Ver Historial de Entregas", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // Pop-up interactivo: Crear Familia Desde Cero
  void _abrirDialogoCrearFamilia() {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController dirController = TextEditingController();
    final TextEditingController intController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cargar Nueva Familia"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreController, decoration: const InputDecoration(labelText: "Apellido / Nombre Responsable")),
            TextField(controller: dirController, decoration: const InputDecoration(labelText: "Dirección de la vivienda")),
            TextField(controller: intController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Cantidad de Integrantes")),
          ],
        ),
        actions: [
           TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancelar")
          ),
          ElevatedButton(
            onPressed: () {
              final String nombre = nombreController.text.trim();
              final String direccion = dirController.text.trim();
              final int integrantes = int.tryParse(intController.text) ?? 1;
              Navigator.pop(context);
              if (nombre.isNotEmpty && direccion.isNotEmpty) {
                _apiCargarFamilia(nombre, direccion, integrantes);
              }
            },
            child: const Text("Registrar"),
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

  void _abrirPantallaHistorialFamilia(Map<String, dynamic> fam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite expandir de forma cómoda en el móvil
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.75, // Ocupa el 75% de la pantalla del celular
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in_outlined, size: 28, color: Colors.orangeAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Entregas a: ${fam['nombre_familia'] ?? fam['nombre_familia'] ?? 'Familia'}", 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              //Renderizador dinámico asíncrono conectado al endpoint de retiros
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _fetchHistorialFamilia(fam['id'] ?? fam['familia_id'] ?? 0),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!['movimientos'] == null || (snapshot.data!['movimientos'] as List).isEmpty) {
                      return const Center(child: Text("Esta familia no registra retiros de mercadería todavía."));
                    }

                    final listadoMovimientos = snapshot.data!['movimientos'] as List<dynamic>;

                    return ListView.builder(
                      itemCount: listadoMovimientos.length,
                      itemBuilder: (context, index) {
                        final mov = listadoMovimientos[index];
                        
                        
                        String fechaCorta = "Reciente";
                        if (mov['fecha'] != null) {
                          final partes = mov['fecha'].toString().split('T');
                          if (partes.isNotEmpty) fechaCorta = partes[0];
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            color: Colors.grey.shade50,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade100),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orangeAccent, // Naranja indicando egreso/retiro de mercadería
                                child: Icon(Icons.outbox_rounded, color: Colors.white, size: 20),
                              ),
                              title: Text(
                                "${mov['producto']} (-${mov['cantidad']} u.)", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                              ),
                              subtitle: const Text("Entregado a la familia"),
                              trailing: Text(
                                fechaCorta, 
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


 
