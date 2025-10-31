/*
	Ejercicio de parcial B 25oct-2025

	Implementar una regla de negocio en línea que registre los productos
	que al momento de venderse registraron un aumento superior al 10 %
	del precio de venta que tuvieron en el mes anterior. Se deberá registrar
	el producto, la fecha en el cual se hace la venta, el precio anterior y el
	precio nuevo.
*/

CREATE TABLE Registro (
	reg_producto char(8),
	reg_fecha DATETIME,
	reg_precio_anterior decimal(12,2),
	reg_precio_posterior decimal(12,2),
	reg_factura_nueva char(8),
	reg_factura_vieja char(8)
)

-- Esta version no contempla un INSERT de varias filas, en ese caso se deberia agregar un cursor que lea cada fila del inserted.
CREATE TRIGGER registrar_producto_que_aumento
ON Item_Factura
AFTER INSERT
AS
BEGIN

	DECLARE @producto_vendido char(8)
	DECLARE @precio_nuevo decimal(12,2)
	DECLARE @precio_viejo decimal(12,2)
	DECLARE @fecha_actual DATETIME
	DECLARE @factura_nueva char(8)
	DECLARE @factura_vieja char(8)

	SELECT @precio_nuevo = i.item_precio, @producto_vendido = i.item_producto, @fecha_actual = f.fact_fecha, @factura_nueva = f.fact_numero
	FROM inserted i
	JOIN Factura f ON f.fact_numero = i.item_numero


	DECLARE productos_aptos_para_registrar CURSOR FOR
		SELECT f.fact_numero, i.item_precio -- Factura vieja y Precio viejo
		FROM Item_Factura i
		JOIN Factura f ON f.fact_numero = i.item_numero
		WHERE MONTH(f.fact_fecha) = MONTH(@fecha_actual)-1 AND  -- Busca todas las fehcas del ems anterior, por lo que puede devolver varias respuestas
			YEAR (f.fact_fecha) = YEAR(@fecha_actual) AND
			i.item_producto = @producto_vendido AND 
			((100*@precio_nuevo) / i.item_precio) - 100 >= 10
	
	OPEN productos_aptos_para_registrar
	FETCH NEXT FROM productos_aptos_para_registrar INTO @factura_vieja, @precio_viejo
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
			INSERT INTO Registro (reg_producto, reg_fecha, reg_precio_anterior, reg_precio_posterior, reg_factura_nueva, reg_factura_vieja)
			VALUES (@producto_vendido, @fecha_actual, @precio_viejo, @precio_nuevo, @factura_nueva, @factura_vieja)

			FETCH NEXT FROM productos_aptos_para_registrar INTO @factura_vieja, @precio_viejo
	END;
END
GO