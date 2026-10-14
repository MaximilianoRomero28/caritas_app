from sqlalchemy import Column,String,Integer,ForeignKey,Boolean
from sqlalchemy import Float,DateTime


import conexion

class Producto(conexion.base):
    __tablename__="productos"

    id=Column(Integer,primary_key=True)
    nombre_producto=Column(String,nullable=False)
    stock=Column(Integer,nullable=False)
    fecha_carga=Column(DateTime,nullable=False)

class Familia(conexion.base):
    __tablename__="familias"

    id=Column(Integer,primary_key=True)
    nombre_familia=Column(String,nullable=False)
    direccion=Column(String,nullable=False)
    integrantes=Column(Integer,nullable=False)

class Retiro(conexion.base):
    __tablename__="retiros"

    id=Column(Integer,primary_key=True)
    producto_id=Column(Integer,ForeignKey("productos.id"), nullable=False)
    familia_id=Column(Integer,ForeignKey("familias.id"),nullable=False)
    cantidad=Column(Integer,nullable=False)
    fecha_retiro=Column(DateTime,nullable=False)

class SumarStock(conexion.base):
    __tablename__="agregarstock"

    id=Column(Integer,primary_key=True)
    producto_id=Column(Integer,ForeignKey("productos.id"),nullable=False)
    cantidad=Column(Integer,nullable=False)
    fecha_carga=Column(DateTime,nullable=False)
    medio=Column(String)

class Caja(conexion.base):
    __tablename__="caja"

    id=Column(Integer,primary_key=True)
    monto=Column(Float,nullable=False)
    fecha_carga=Column(DateTime,nullable=False)

class RetiroCaja(conexion.base):
    __tablename__="retiroCaja"

    id=Column(Integer,primary_key=True)
    caja_id=Column(Integer,ForeignKey("caja.id"),nullable=False)
    monto=Column(Float,nullable=False)
    fecha_retiro=Column(DateTime,nullable=False)
    destino=Column(String,nullable=False)

class SumarCaja(conexion.base):
    __tablename__="sumarCaja"

    id=Column(Integer,primary_key=True)
    caja_id=Column(Integer,ForeignKey("caja.id"),nullable=False)
    monto=Column(Float,nullable=False)
    fecha_suma=Column(DateTime,nullable=False)
    medio=Column(String)