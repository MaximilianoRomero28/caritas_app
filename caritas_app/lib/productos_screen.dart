import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {

  List <dynamic> _productos=[];
  bool _cargando=true;

  final String baseUrl="10.0.2.2:8000";

  //Retirar stock
  Future<void> _apiRetirarProducto(int productoId, int familiaId, int cantidad) async{

    final url=Uri.http(baseUrl,"/v1/admin/retirar/$productoId");

    try{
      final respuesta=await http.patch(url,
        headers: {
          "Content-Type": "application/json",
        },
        body: convert.jsonEncode({
          "familia_id":familiaId,
          "cantidad": cantidad,
        })    
      );

      if (respuesta.statusCode==200){
        _mostrarSnackBar("Egreso registrado con éxito", const Color(0xFF10B981));
        _fetchProductosdeBackend();
      } else {
        final errorData=convert.jsonDecode(respuesta.body);
        _mostrarSnackBar("$errorData['detail]",Colors.orangeAccent);
      }
    } catch (e) {
      _mostrarSnackBar("Error de red al procesar el retiro", Colors.redAccent);
    }
  }

  //Historial general
  Future<List<dynamic>> _fetchHistorialGeneral() async {

    final url= Uri.http(baseUrl,"/v1/admin/historial/general");

    try {
      final response= await http.get(url);
      debugPrint("HISTORIAL: ${response.statusCode}");

      if (response.statusCode==200) {
        return convert.jsonDecode(response.body);
      }
      debugPrint("Cuerpo: ${response.body}");
    } catch (e) {
      debugPrint("Error al traer historial: $e");
    }
    return const [];
  }


  //Sumar Stock
  Future<void> _apiSumarStock(int productoId, int cantidad, String medio) async {
    final url=Uri.http(baseUrl,"/v1/admin/sumar/$productoId/stock");

    try{
      final respuesta=  await http.patch(url,
        headers: {
          "content-Type": "application/json",
        },
        body: convert.jsonEncode({
         "cantidad": cantidad,
          "medio": medio,
        })
      );

      if (respuesta.statusCode==200){
        _mostrarSnackBar("Stock incrementado correctamente", const Color(0xFF10B981));
      } else {
        _mostrarSnackBar("Error al actualizar el stock", Colors.orangeAccent);
      }
    } catch (e) {
      _mostrarSnackBar("Error de red al sumar stock", Colors.redAccent);
    }
  }

  //eliminar producto
  Future <void> _apiEliminarProducto(int productoId) async {
    final url= Uri.http(baseUrl,"/v1/admin/eliminar/$productoId");

    try{
      final respuesta=await http.delete(url);

      if (respuesta.statusCode==200) {
        _mostrarSnackBar("Producto e historial borrados", Colors.blueGrey);
        _fetchProductosdeBackend();
      } else{
        _mostrarSnackBar("No se pudo eliminar el producto", Colors.redAccent);
      }
    } catch (e) {
      _mostrarSnackBar("Error de red al intentar eliminar.", Colors.redAccent);
    }
  }

  @override
  void initState(){
    super.initState();
    _fetchProductosdeBackend();
  }

  //Listado
  Future<void> _fetchProductosdeBackend() async{
    setState(()=> _cargando=true);
    
    try {

      final url= Uri.http(baseUrl,"/v1/admin/productos/todos");

      final respuesta=await http.get(url).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (respuesta.statusCode==200) {
        setState(() {
          _productos=convert.jsonDecode(respuesta.body);
          _cargando=false;
        });
      }
    } catch (e){
      if(!mounted) return;

      setState(() => _cargando=false);

      _mostrarSnackBar("Error al conectar con el servidor", Colors.redAccent); 
    }
  }

  Future<void> _apiCargarNuevoProducto(String nombre, int cantidad) async {

   
    try{

      final url=Uri.http(baseUrl,"/v1/admin/cargar/producto");

      final respuesta=await http.post(url,
        headers: {
          "Content-Type": "application/json",
        },
        body: convert.jsonEncode({
          "nombre_producto":nombre,
          "cantidad":cantidad,
        })
      );

      if (respuesta.statusCode==201){
        _mostrarSnackBar("Producto registrado con éxito", const Color(0xFF10B981));
        _fetchProductosdeBackend();
      } else {
        _mostrarSnackBar("Error al registrar producto", Colors.orangeAccent);
      }
    } catch (e) {
      debugPrint("Error: $e");
      _mostrarSnackBar("Error de red al cargar producto", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Inventario Cáritas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔎 1. BUSCADOR PREDICTIVO (Autocomplete)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (option) => option['nombre_producto'] ?? '',
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                );
              },
              optionsBuilder: (textEditingValue) async {
                if (textEditingValue.text.length < 2) return const Iterable.empty();
                try {
                  final url = Uri.http('10.0.2.2:8000', '/v1/admin/buscar/producto', {'termino': textEditingValue.text});
                  final respuesta = await http.get(url);
                  if (respuesta.statusCode == 200) {
                    final List<dynamic> datos = convert.jsonDecode(respuesta.body);
                    return datos.map((json) => json as Map<String, dynamic>);
                  }
                } catch (e) {
                  debugPrint(e.toString());
                }
                return const Iterable.empty();
              },
              onSelected: (Map<String, dynamic> seleccion) {
                _mostrarOpcionesProducto(seleccion);
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text("Todos los Productos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),

          //2. LISTA GENERAL DE STOCK
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _productos.isEmpty
                    ? const Center(child: Text("No hay productos cargados en el stock"))
                    : ListView.builder(
                        itemCount: _productos.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final prod = _productos[index];
                          final int currentStock = prod['stock'] ?? 0;

                          final Color stockColor = currentStock == 0
                              ? Colors.redAccent
                              : (currentStock < 10 ? Colors.orangeAccent : const Color(0xFF10B981));

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
                                title: Text(prod['nombre_producto'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: stockColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                                  child: Text('$currentStock u.', style: TextStyle(color: stockColor, fontWeight: FontWeight.bold)),
                                ),
                                onTap: () => _mostrarOpcionesProducto(prod),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      
      // 3. BOTÓN FLOTANTE PARA CARGAR PRODUCTO NUEVO
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left:32.0),
        child: Row(
          children: [
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: "btnHistorial",
                onPressed: () => _abrirPantallaHistorial(),
                label: const Text('Historial'),
                icon: const Icon(Icons.history_toggle_off_rounded),
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child:FloatingActionButton.extended(
                heroTag: "btnNuevoProd",
                onPressed: () => _abrirDialogoCrearProducto(),
                label: const Text('Nuevo Producto'),
                icon: const Icon(Icons.add),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              )
            )
            
          ],
        ),
      )
      
    );
  }

  void _abrirPantallaHistorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height*0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history,size: 28, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text("Historial General", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24),

              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _fetchHistorialGeneral(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState==ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No se registraron ingresos todavía."));
                    }

                    final listaHistorial= snapshot.data!;

                    return ListView.builder(
                      itemCount: listaHistorial.length,
                      itemBuilder: (context, index) {
                        final registro= listaHistorial[index];

                        final bool esIngreso=registro['tipo']=='INGRESO';
                        final Color colorMov= esIngreso ? const Color(0xFF10B981) : Colors.orangeAccent;

                        final String fechaCorta= registro['fecha'].toString().split('T')[0];

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
                              leading: CircleAvatar(
                                backgroundColor: colorMov,
                                child: Icon(
                                  esIngreso ? Icons.add_rounded : Icons.remove_rounded, 
                                  color: Colors.white
                                ),
                              ),
                              title: Text(
                                 "${registro['producto']} (${esIngreso ? '+' : '-'}${registro['cantidad']} u.)",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text(
                                esIngreso
                                  ? "Vía: ${registro['detalle'] ?? 'No especificado'}"
                                  : "Entregado a: ${registro['detalle'] ?? 'No especificado'}",
                              ),
                              trailing: Text(
                                fechaCorta,
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        );
      }
    );
  }

  

  void _mostrarOpcionesProducto(Map<String, dynamic> prod) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    child: Text(
                      prod['nombre_producto'] ?? '', 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), 
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(context);
                      _apiEliminarProducto(prod['id']);
                    },
                  )
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981), 
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(vertical: 12), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () { 
                        Navigator.pop(context); 
                        _abrirDialogoSumar(prod); 
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Sumar Stock"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent, 
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(vertical: 12), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () { 
                        Navigator.pop(context); 
                        _abrirDialogoRetirar(prod); 
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text("Entregar"),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // Pop-up interactivo: Crear Producto Desde Cero
  void _abrirDialogoCrearProducto() {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController cantController = TextEditingController(text: "0");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cargar Nuevo Producto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController, 
              decoration: const InputDecoration(labelText: "Nombre del Producto (ej: Arroz 1kg)")
            ),
            TextField(
              controller: cantController, 
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(labelText: "Stock Inicial")
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final String nombre = nombreController.text.trim();
              final int cant = int.tryParse(cantController.text) ?? 0;
              Navigator.pop(context);
              if (nombre.isNotEmpty) _apiCargarNuevoProducto(nombre, cant);
            },
            child: const Text("Cargar"),
          )
        ],
      ),
    );
  }

  // Pop-up interactivo: Sumar Stock a existente
  void _abrirDialogoSumar(Map<String, dynamic> prod) {
    final TextEditingController cantController = TextEditingController();
    final TextEditingController medioController = TextEditingController(text: "Donación");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ingresar ${prod['nombre_producto']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cantController, 
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(labelText: "Cantidad")
            ),
            TextField(
              controller: medioController, 
              decoration: const InputDecoration(labelText: "Origen / Medio")
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final int cant = int.tryParse(cantController.text) ?? 0;
              Navigator.pop(context);
              if (cant > 0) _apiSumarStock(prod['id'], cant, medioController.text);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  // Pop-up interactivo: Registrar Retiros
  void _abrirDialogoRetirar(Map<String, dynamic> prod) {
    final TextEditingController cantController = TextEditingController();
    int? familiaSeleccionadaId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Retirar ${prod['nombre_producto']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Autocomplete<Map<String,dynamic>>(
              displayStringForOption: (f)=> f['nombre'] ?? '',
              optionsBuilder: (textEditingValue) async {
                if (textEditingValue.text.length<2) return const Iterable.empty();
                try {
                  final url=Uri.http(baseUrl,'/v1/admin/buscar/familia',
                  {'termino': textEditingValue.text});

                  final respuesta= await http.get(url);

                  if (respuesta.statusCode==200){
                    final List<dynamic> datos=convert.jsonDecode(respuesta.body);
                    return datos.map((e) => e as Map<String, dynamic>);
                  }
                } catch (e) {
                  debugPrint("Error buscando familia: $e");
                }
                return const Iterable.empty();
              },

              onSelected: (familia)=>familiaSeleccionadaId=familia['id'],
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (_) => familiaSeleccionadaId=null,
                  decoration: const InputDecoration(
                    labelText: "Familia",
                    hintText: "Escribí el nombre...",
                    prefixIcon: Icon(Icons.search)
                  ),
                );
              } , 
            ),
            TextField(
              controller: cantController, 
              keyboardType: TextInputType.number, 
              decoration: const InputDecoration(labelText: "Cantidad a entregar")
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final int cant = int.tryParse(cantController.text) ?? 0;
              
              if (familiaSeleccionadaId==null) {
                _mostrarSnackBar("Elegí una familia de la lista", Colors.orangeAccent);
                return;
              }
              if (cant<=0) {
                _mostrarSnackBar("Ingresá una cantidad válida", Colors.orangeAccent);
                return;
              }
              Navigator.pop(context);
              _apiRetirarProducto((prod['id']), familiaSeleccionadaId!, cant);
            },
            child: const Text("Registrar Retiro"),
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

  

