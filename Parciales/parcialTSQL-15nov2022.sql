/*
	Ejercicio T-SQL del Parcial 15/11/2022 Lacquaniti

	parecido al ejercicio 6 de la guia


*/

CREATE OR ALTER TRIGGER componer_productos
ON Item_Factura
INSTEAD OF INSERT
AS
BEGIN

	INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
	SELECT item_tipo, item_sucursal, item_numero, c.comp_producto, item_cantidad, p.prod_precio
	FROM inserted i
	JOIN Composicion c ON i.item_producto = c.comp_componente
	JOIN Producto p ON p.prod_precio = c.comp_producto -- Por las dudas hago este join, porque quizas la suma de los componentes individuales no equivale al precio del combo
	GROUP BY item_numero, c.comp_producto, item_cantidad, item_tipo, item_sucursal

END;
GO
|
SELECT * from Item_Factura

