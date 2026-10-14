from fastapi import APIRouter, HTTPException, Depends
import modelos
import conexion
from sqlalchemy.orm import Session
import clases
from datetime import datetime,timezone

router=APIRouter()

@router.post("/v1/admin/caja/ingresar",status_code=201)
def cargar_caja(datos:clases.sumarCaja, db:Session=Depends(conexion.get_db)):

    if datos.cantidad_monto<=0:
        raise HTTPException(status_code=400,detail="El monto debe ser mayor a 0.")

    hoy=datetime.now(timezone.utc).replace(tzinfo=None)

    caja=db.query(modelos.Caja).order_by(modelos.Caja.id).first()

    if caja is None:
        caja=modelos.Caja(
            monto=datos.cantidad_monto,
            fecha_carga=hoy)
        db.add(caja)
        db.flush()
        creada=True
    else:
        caja.monto=caja.monto+datos.cantidad_monto
        creada=False

    db.add(modelos.SumarCaja(
        caja_id= caja.id,
        monto=datos.cantidad_monto,
        fecha_suma=hoy,
        medio=datos.medio
    ))

    db.commit()
    db.refresh(caja)

    return{
        "status": "CAJA_CREADA" if creada else "OK",
        "caja_id": caja.id,
        "nueva_caja": caja.monto
    }
   


@router.patch("/v1/admin/retiro/{caja_id}",status_code=200)
def retiro_caja(datos:clases.retiroCaja,caja_id:int,
    db:Session=Depends(conexion.get_db)):

    caja=db.query(modelos.Caja).filter(
        modelos.Caja.id==caja_id
    ).first()

    if not caja:
        raise HTTPException(status_code=404,detail="La caja no existe")

    if datos.monto>caja.monto:
        raise HTTPException(status_code=400,detail="El monto en la caja es insuficiente")

    caja.monto=caja.monto-datos.monto

    hoy=datetime.now(timezone.utc).replace(tzinfo=None)

    nuevo_retiro=modelos.RetiroCaja(
        caja_id=caja.id,
        monto=datos.monto,
        fecha_retiro=hoy,
        destino=datos.destino
    )

    db.add(nuevo_retiro)
    db.commit()
    db.refresh(caja)

    return{"status":"RETIRO_EXITOSO","caja_monto":caja.monto}

@router.get("/v1/admin/caja/todo",status_code=200)
def listado_caja(db:Session=Depends(conexion.get_db)):

    caja=db.query(modelos.Caja).order_by(modelos.Caja.id).first()

    if caja is None:
        return {"monto": 0, "movimientos":[]}

    movimientos=[]

    sumas=db.query(modelos.SumarCaja).filter(
        modelos.SumarCaja.caja_id==caja.id
    ).all()

    for s in sumas:
        movimientos.append({
            "tipo": "INGRESO",
            "monto": s.monto,
            "detalle": s.medio,
            "fecha": s.fecha_suma
        })

    retiros = db.query(modelos.RetiroCaja).filter(
        modelos.RetiroCaja.caja_id == caja.id
    ).all()

    for r in retiros:
        movimientos.append({
            "tipo": "EGRESO",
            "monto": r.monto,
            "detalle": r.destino,
            "fecha": r.fecha_retiro
        })

    movimientos.sort(key=lambda m: m["fecha"], reverse=True)

    return {"monto": caja.monto, "movimientos": movimientos}