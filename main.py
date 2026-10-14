import conexion
from fastapi import FastAPI
from rutas_productos import router as router_cargar
from ruta_caja import router as router_caja
from rutas_familias import router as router_familias


app=FastAPI()

app.include_router(router_cargar)

app.include_router(router_caja)

app.include_router(router_familias)

conexion.base.metadata.create_all(bind=conexion.engine)