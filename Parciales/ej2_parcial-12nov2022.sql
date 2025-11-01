/*
	Ejercicio T-SQL del Parcial 12/11/2022 Lacquaniti

	Implementar una regla de negocio de validación en línea que permita
	validar STOCK al realizarse una venta. Cada venta se debe descontar
	sobre el depósito '00'. En caso de que se venda un producto compuesto,
	el descuento de stock se debe realizar por sus componentes. Si no hay
	STOCK para ese artículo, no se deberá guardar ese artículo, pero si
	los otros en los cuales hay stock positivo. Es decir, dolamente se 
	deberán guardar aquellos para los cuales si hay stock, sin guardarse
	los que no poseen cantidades suficientes.
*/

ALTER TABLE STOCK ADD CONSTRAINT const_stock_positivo CHECK (stoc_cantidad >= 0)
	
CREATE OR ALTER TRIGGER tr_descontar_stock ON dbo.Item_Factura INSTEAD OF INSERT
AS
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	
	-- Variables
	DECLARE @producto char(8), @cantidad_vendida decimal(12,2), @componente char(8), @cantidad_componente decimal(12,2)
	
	-- Cursor
	DECLARE cursor_producto CURSOR FOR
		SELECT i.item_producto, SUM(i.item_cantidad)
		FROM INSERTED i
		GROUP BY i.item_producto
		
	OPEN cursor_producto
	FETCH cursor_producto INTO @producto, @cantidad_vendida
	
	WHILE @@FETCH_STATUS = 0
		BEGIN
		
		-- Si no es compuesto, descuento sobre el producto original
		IF NOT EXISTS (SELECT 1 FROM Composicion c WHERE c.comp_producto = @producto)
			BEGIN
				UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidad_vendida WHERE stoc_deposito = '00' AND stoc_producto = @producto
				IF @@ERROR != 0   
					BEGIN
						PRINT(CONCAT('EL PRODUCTO ', @producto, 'YA NO TIENE STOCK'))
					END
				ELSE
					BEGIN
						INSERT INTO GD2C2022PRACTICA.dbo.Item_Factura
						(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
						SELECT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio
						FROM INSERTED WHERE item_producto = @producto
					END
			END
		
		-- Si es compuesto itero y descuento sobre los componentes
		DECLARE cursor_componente CURSOR FOR
			SELECT comp_componente, comp_cantidad
			FROM Composicion
			WHERE comp_producto = @producto
		
		OPEN cursor_componente
		FETCH cursor_componente INTO @componente, @cantidad_componente
		
		WHILE @@FETCH_STATUS = 0
			BEGIN
				UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidad_vendida * @cantidad_componente WHERE stoc_deposito = '00' AND stoc_producto = @componente
				IF @@ERROR != 0   
				BEGIN
					PRINT(CONCAT('EL PRODUCTO ', @componente, 'YA NO TIENE STOCK'))
				END
				ELSE
				BEGIN
					INSERT INTO Item_Factura
					(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
					SELECT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio
					FROM INSERTED WHERE item_producto = @componente
				END
				
				FETCH cursor_componente INTO @componente,@cantidad_componente
			END
			
		CLOSE cursor_componente
		DEALLOCATE cursor_componente
		
		FETCH cursor_producto INTO @producto,@cantidad_vendida
		END
	
	CLOSE cursor_producto
	DEALLOCATE cursor_producto
GO