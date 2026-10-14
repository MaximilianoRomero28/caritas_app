from fastapi import Depends, APIRouter,HTTPException
import modelos
import conexion
from  datetime import datetime,timezone
import clases
from sqlalchemy.orm import Session
from typing import Optional
from sqlalchemy import desc


router=APIRouter()

@router.post("/v1/admin/cargar/producto", status_code=201)
def cargar_producto(datos:clases.cargarProducto,
    db:Session=Depends(conexion.get_db)):

    fecha_base=datetime.now(timezone.utc).replace(tzinfo=None)

    nueva_carga=modelos.Producto(
        nombre_producto=datos.nombre_producto,
        stock=datos.cantidad,
        fecha_carga=fecha_base
    )

    db.add(nueva_carga)
    db.flush()

    if datos.cantidad >0:
        db.add(modelos.SumarStock(
            producto_id=nueva_carga.id,
            cantidad=datos.cantidad,
            medio="Stock inicial",
            fecha_carga=fecha_base
        ))

    db.commit()
    db.refresh(nueva_carga)

    return{"status":"PRODUCTO_REGISTRADO","nuevo_producto_id":nueva_carga.id}

@router.delete("/v1/admin/eliminar/{producto_id}", status_code=200)
def delete_producto(producto_id:int,db: Session=Depends(conexion.get_db)):

    producto=db.query(modelos.Producto).filter(modelos.Producto.id==producto_id).first()

    if not producto:
        raise HTTPException(status_code=404,detail="Producto inexistente")

    fecha_eliminacion=datetime.now(timezone.utc).replace(tzinfo=None)

    db.query(modelos.Retiro).filter(modelos.Retiro.producto_id==producto_id).delete()
    db.query(modelos.SumarStock).filter(modelos.SumarStock.producto_id==producto_id).delete()

    db.delete(producto)
    db.commit()

    return {"status": "OK", "detalle": "Producto eliminado.", "fecha_delete": fecha_eliminacion}


@router.get("/v1/admin/buscar/producto",status_code=200)
def buscar_producto_predictivo(termino:Optional[str]=None, 
    db:Session=Depends(conexion.get_db)):

    query = db.query(modelos.Producto)
    if termino:
        query = query.filter(modelos.Producto.nombre_producto.contains(termino))
    
    resultados = query.all()

    respuesta=[]

    for producto in resultados:

        respuesta.append({
            "id": producto.id,
            "nombre_producto": producto.nombre_producto,
            "fecha_carga": producto.fecha_carga
        })

    return respuesta

@router.patch("/v1/admin/retirar/{producto_id}", status_code=200)
def retirar_producto(datos: clases.retiroProducto, producto_id:int,
    db:Session=Depends(conexion.get_db)):

    producto=db.query(modelos.Producto).filter(
        modelos.Producto.id==producto_id
    ).first()

    if not producto:
        raise HTTPException(status_code=404,detail="Producto inexistente")

   
    famiia=db.query(modelos.Familia).filter(
        modelos.Familia.id==datos.familia_id
    ).first()

    if not famiia:
        raise HTTPException(status_code=404,detail="La familia seleccionada no existe")

    if datos.cantidad>producto.stock:
        raise HTTPException(status_code=400,detail="Cantidad insuficiente")

    hoy=datetime.now(timezone.utc).replace(tzinfo=None)
    
    producto.stock=producto.stock-datos.cantidad

    nuevo_retiro=modelos.Retiro(
        producto_id=producto_id,
        familia_id=famiia.id,
        cantidad=datos.cantidad,
        fecha_retiro= hoy
    )

    db.add(nuevo_retiro)
    db.commit()
    db.refresh(producto)

    return {"status":"Stock actualizado","nuevo_stock": producto.stock,"retiro_id":nuevo_retiro.id}


@router.patch("/v1/admin/sumar/{producto_id}/stock",status_code=200)
def sumar_stock(datos:clases.agregarProducto, producto_id:int,
    db:Session=Depends(conexion.get_db)):

    producto=db.query(modelos.Producto).filter(
        modelos.Producto.id==producto_id
    ).first()

    if not producto:
        raise HTTPException(status_code=404,detail="Producto inexistente")

    producto.stock=producto.stock+datos.cantidad

    hoy=datetime.now(timezone.utc).replace(tzinfo=None)

    nuevo_ingreso=modelos.SumarStock(
        producto_id=producto.id,
        cantidad=datos.cantidad,
        fecha_carga=hoy,
        medio= datos.medio
    )

    db.add(nuevo_ingreso)
    db.commit()
    db.refresh(producto)

    return {"status": "Stock_incrementado","nuevo_stock":producto.stock}


@router.get("/v1/admin/productos/todos",status_code=200)
def obtener_productos_todos(db:Session=Depends(conexion.get_db)):

    return db.query(modelos.Producto).all()

@router.get("/v1/admin/historial/general", status_code=200)
def historial_general(limit: int=50,offset:int=0,
    db:Session=Depends(conexion.get_db)):

    tope=limit+offset

    movimientos=[]

    ingresos=(
        db.query(modelos.SumarStock, modelos.Producto.nombre_producto)
        .join(modelos.Producto, modelos.Producto.id == modelos.SumarStock.producto_id)
        .order_by(desc(modelos.SumarStock.fecha_carga))
        .limit(tope)
        .all()
    )

    for a, nombre in ingresos:
        
        movimientos.append({
            "tipo": "INGRESO",
            "producto": nombre,
            "cantidad": a.cantidad,
            "detalle": a.medio,        
            "fecha": a.fecha_carga,
        })

    retiros = (
        db.query(
            modelos.Retiro,
            modelos.Producto.nombre_producto,
            modelos.Familia.nombre_familia,
        )
        .join(modelos.Producto, modelos.Producto.id == modelos.Retiro.producto_id)
        .join(modelos.Familia, modelos.Familia.id == modelos.Retiro.familia_id)
        .order_by(desc(modelos.Retiro.fecha_retiro))
        .limit(tope)
        .all()
    )

    for r, producto, familia in retiros:
        movimientos.append({
            "tipo": "RETIRO",
            "producto": producto,
            "cantidad": r.cantidad,
            "detalle": familia,       
            "fecha": r.fecha_retiro,
        })


    movimientos.sort(key=lambda m: m["fecha"], reverse=True)

    return movimientos[offset: offset+limit]


@router.get("/v1/admin/historial/familia/{familia_id}", status_code=200)
def historial_familia(
    familia_id: int,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(conexion.get_db),
):
    familia = db.query(modelos.Familia).filter(
        modelos.Familia.id == familia_id
    ).first()

    if not familia:
        raise HTTPException(status_code=404, detail="La familia no existe")

    filas = (
        db.query(modelos.Retiro, modelos.Producto.nombre_producto)
        .join(modelos.Producto, modelos.Producto.id == modelos.Retiro.producto_id)
        .filter(modelos.Retiro.familia_id == familia_id)
        .order_by(desc(modelos.Retiro.fecha_retiro))
        .limit(limit)
        .offset(offset)
        .all()
    )

    return {
        "familia_id": familia.id,
        "familia": familia.nombre_familia,
        "movimientos": [
            {
                "tipo": "RETIRO",
                "producto": producto,
                "cantidad": r.cantidad,
                "fecha": r.fecha_retiro,
            }
            for r, producto in filas
        ],
    }