/*
	Parcial T-SQL 19/11/2022 de Lacquaniti

	Implementar una regla de negocio en linea donde nunca una factura nueva tenga un precio
	distinto al que figura en la tabla PRODUCTO. Registrar en una estructura adicional
	todos los casos donde se intenta guardar un precio distinto

*/

CREATE TABLE producto_precio_mal (
	prod_codigo char(8),
	prod_precio_mal decimal(12,2)
)

CREATE TRIGGER precio_correcto
ON Item_Factura
INSTEAD OF INSERT
AS
BEGIN

    -- 1 Registrar precios mal
    INSERT INTO producto_precio_mal (prod_codigo, prod_precio_mal)
    SELECT i.item_producto, i.item_precio
    FROM inserted i
    JOIN Producto p ON i.item_producto = p.prod_codigo
    WHERE i.item_precio <> p.prod_precio;

    -- 2️ Insertar en Item_Factura con precios correctos
    INSERT INTO Item_Factura (item_numero, item_cantidad, item_precio, item_producto, item_sucursal, item_tipo)
    SELECT 
        i.item_numero,
        i.item_cantidad,
        p.prod_precio, -- precio corregido
        i.item_producto,
        i.item_sucursal,
        i.item_tipo
    FROM inserted i
    JOIN Producto p ON i.item_producto = p.prod_codigo;

END;
GO