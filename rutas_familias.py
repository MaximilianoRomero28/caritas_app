from fastapi import APIRouter, Depends,HTTPException
import modelos
import clases
from sqlalchemy.orm import Session
import conexion

router=APIRouter()

@router.post("/v1/admin/familia/cargar", status_code=201)
def cargar_familia(datos:clases.cargarFamilia,
    db: Session=Depends(conexion.get_db)):

    nueva_familia=modelos.Familia(
        nombre_familia=datos.nombre,
        direccion=datos.direccion,
        integrantes=datos.integrantes
    )

    db.add(nueva_familia)
    db.commit()
    db.refresh(nueva_familia)

    return {"status": "FAMILIA_CARGADA","familia_id":nueva_familia.id}


@router.delete("/v1/admin/{familia_id}/eliminar",status_code=200)
def delete_familia(familia_id: int, db:Session=Depends(conexion.get_db)):

    familia=db.query(modelos.Familia).filter(
        modelos.Familia.id==familia_id
    ).first()

    if not familia:
        raise HTTPException(status_code=404,detail="Familia inexistente")

    db.query(modelos.Retiro).filter(modelos.Retiro.familia_id==familia_id).delete()

    db.delete(familia)
    db.commit()

    return {"status":"OK","detalle": "Familia eliminada"}

@router.get("/v1/admin/familias/listar",status_code=200)
def listar_familias(db:Session=Depends(conexion.get_db)):

    familias=db.query(modelos.Familia).all()

    familia=[]

    for f in familias:
        familia.append({
            "id": f.id,
            "nombre_familia": f.nombre_familia,
            "direccion": f.direccion,
            "integrantes": f.integrantes
        })

    return {"familia": familia}

@router.get("/v1/admin/buscar/familia", status_code=200)
def buscar_familia(termino: str, db: Session = Depends(conexion.get_db)):
    familias = (
        db.query(modelos.Familia)
        .filter(modelos.Familia.nombre_familia.ilike(f"%{termino}%"))
        .limit(10)
        .all()
    )
    return [{"id": f.id, "nombre": f.nombre_familia} for f in familias]
