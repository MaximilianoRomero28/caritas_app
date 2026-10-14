from pydantic import BaseModel


class cargarProducto(BaseModel):
    nombre_producto: str
    cantidad: int


class retiroProducto(BaseModel):
    cantidad:int
    familia_id:int


class agregarProducto(BaseModel):
    cantidad:int
    medio:str


class cargarFamilia(BaseModel):
    nombre: str
    direccion:str
    integrantes:int


class sumarCaja(BaseModel):
    cantidad_monto:float
    medio:str

class retiroCaja(BaseModel):
    monto:int
    destino:str