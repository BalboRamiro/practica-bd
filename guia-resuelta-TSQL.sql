-- Guia de ejercicios T-SQL

/*
	 Ejercicio 1

	Hacer una función que dado un artículo y un deposito devuelva un string que
	indique el estado del depósito según el artículo. Si la cantidad almacenada es
	menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
	% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
	“DEPOSITO COMPLETO”.
*/

USE [GD2015C1]
GO

CREATE FUNCTION fx_ej1 (@deposito char(2), @producto char(8))
RETURNS varchar(MAX) AS
BEGIN

DECLARE @retorno varchar(MAX);
DECLARE @cantidad decimal(12,2);
DECLARE @maximo decimal(12,2);

SELECT @cantidad = stoc_cantidad, @maximo = stoc_stock_maximo
FROM dbo.STOCK S WHERE @deposito = stoc_deposito AND @producto = stoc_producto

IF @cantidad IS NULL
	SET @retorno = 'PRODUCTO Y/O DEPOSITO INEXISTENTES'
	
IF @cantidad >= @maximo
	SET @retorno = 'DEPOSITO COMPLETO'
ELSE
	SET @retorno = CONCAT('OCUPACION DEL DEPOSITO ', (100*@cantidad)/@maximo, '%')

RETURN @retorno

END
GO


select S.*, dbo.fx_ej1(stoc_deposito, stoc_producto)
	FROM STOCK s
GO

/*
	Ejercicio 2 (CORREGIR)

	Realizar una función que dado un artículo y una fecha, retorne el stock que
	existía a esa fecha
*/

USE [GD2015C1]
GO

CREATE FUNCTION fx_ej2 (@fecha DATETIME, @producto CHAR(8))
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @stockActual DECIMAL(12,2);
    DECLARE @vendidoDespues DECIMAL(12,2);
    DECLARE @stockFecha DECIMAL(12,2);

    -- Stock actual
    SELECT @stockActual = stoc_cantidad
    FROM STOCK
    WHERE stoc_producto = @producto;
	 
    -- Total vendido DESPUÉS de la fecha indicada
    SELECT @vendidoDespues = ISNULL(SUM(I.item_cantidad), 0)
    FROM Item_Factura I
    JOIN Factura F ON I.item_numero = F.fact_numero
    WHERE I.item_producto = @producto
      AND F.fact_fecha > @fecha;

    -- Stock que existía a la fecha
    SET @stockFecha = @stockActual + @vendidoDespues;

    RETURN @stockFecha;
END;
GO

SELECT * from Factura

SELECT F.fact_numero, F.fact_fecha, I.item_producto, dbo.fx_ej2(F.fact_fecha, I.item_producto) AS Stock_A_Fecha
	FROM Factura F
	JOIN Item_Factura I ON I.item_numero = F.fact_numero
GO

/*
	Ejercicio 3

	Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
	en caso que sea necesario. Se sabe que debería existir un único gerente general
	(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
	sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
	mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
	empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
	de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
	de empleados que había sin jefe antes de la ejecución.
*/

CREATE PROCEDURE pr_ej3 (@cantidad_de_empleados_sin_jefe INT OUTPUT) AS
BEGIN

	DECLARE @gerente_general numeric(6,0)

    SELECT @cantidad_de_empleados_sin_jefe = COUNT(*)
    FROM Empleado
    WHERE empl_jefe IS NULL;

    -- Si hay más de uno, abrimos un cursor para analizarlos
    IF @cantidad_de_empleados_sin_jefe > 1
		SELECT TOP 1 @gerente_general = empl_codigo
		FROM Empleado
		ORDER BY empl_salario DESC, empl_codigo

		UPDATE Empleado
		SET empl_jefe = @gerente_general
		WHERE empl_jefe IS NULL AND empl_codigo <> @gerente_general
END;
GO

/*
	Ejercicio 4

	Cree el/los objetos de base de datos necesarios para actualizar la columna de
	empleado empl_comision con la sumatoria del total de lo vendido por ese
	empleado a lo largo del último año. Se deberá retornar el código del vendedor
	que más vendió (en monto) a lo largo del último año.
*/

CREATE PROCEDURE pr_ej4 (@cod_vendedor_mas_ventas INT OUTPUT) AS
BEGIN

	DECLARE @ultimo_anio INT

	SELECT TOP 1 @ultimo_anio = YEAR(fact_fecha)
	FROM Factura
	ORDER BY fact_fecha DESC;

	PRINT @ultimo_anio
	
	UPDATE Empleado set empl_comision = (
		SELECT SUM(f.fact_total) 
		FROM Factura F
		WHERE YEAR(f.fact_fecha) = @ultimo_anio AND f.fact_vendedor = empl_codigo)

	SELECT @cod_vendedor_mas_ventas = e.empl_codigo 
	FROM Empleado e
	ORDER BY e.empl_comision DESC;

	PRINT @cod_vendedor_mas_ventas

END;
GO

SELECT * from Empleado

/*
	Ejercicio 5

	Realizar un procedimiento que complete con los datos existentes en el modelo
	provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
	Create table Fact_table
	( anio char(4),
	mes char(2),
	familia char(3),
	rubro char(4),
	zona char(3),
	cliente char(6),
	producto char(8),
	cantidad decimal(12,2),
	monto decimal(12,2)
	)
	Alter table Fact_table
	Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)
*/

CREATE PROCEDURE pr_ej5 () AS
BEGIN TRANSACTION
	Create table Fact_table
	( anio char(4),
	mes char(2),
	familia char(3),
	rubro char(4),
	zona char(3),
	cliente char(6),
	producto char(8),
	cantidad decimal(12,2),
	monto decimal(12,2)
	)

	INSERT INTO Fact_table

	SELECT YEAR(F.fact_fecha) AS anio, MONTH(F.fact_fecha) AS mes, P.prod_familia, P.prod_rubro, F.fact_cliente, P.prod_codigo, D.depa_zona, SUM(I.item_cantidad) AS Cantidad, SUM(I.item_precio * I.item_cantidad) AS Monto FROM Factura F
	JOIN Item_Factura I ON I.item_numero = F.fact_numero AND I.item_sucursal = F.fact_sucursal
	JOIN Producto P ON P.prod_codigo = I.item_producto
	JOIN Empleado E ON E.empl_codigo = f.fact_vendedor
	JOIN Departamento D ON D.depa_codigo = e.empl_departamento
	GROUP BY YEAR(F.fact_fecha), MONTH(F.fact_fecha), P.prod_familia, P.prod_rubro, F.fact_cliente, P.prod_codigo, D.depa_zona
END;
GO

/*
	Ejercicio 6

	Realizar un procedimiento que si en alguna factura se facturaron componentes
	que conforman un combo determinado (o sea que juntos componen otro
	producto de mayor nivel), en cuyo caso deberá reemplazar las filas
	correspondientes a dichos productos por una sola fila con el producto que
	componen con la cantidad de dicho producto que corresponda.
*/

USE [GD2015C1]
GO

CREATE PROCEDURE pr_ej6 () AS
BEGIN

	SELECT F.fact_numero, I.item_producto, C.comp_componente
	FROM Factura F
	JOIN Item_Factura I ON F.fact_numero = I.item_numero
	LEFt JOIN Composicion C ON C.comp_producto = I.item_producto
	GROUP BY F.fact_numero, I.item_producto, C.comp_componente

	select * from Composicion

	SELECT I.item_numero, I.item_producto
	FROM Factura F
	JOIN Item_Factura I ON F.fact_numero = I.item_numero
	GROUP BY I.item_numero, I.item_producto

END;
GO

/*
	Ejercicio 9

	Crear el/los objetos de base de datos que ante alguna modificación 
	de un ítem de factura de un artículo con composición realice el movimiento 
	de sus correspondientes componentes.
*/

CREATE TRIGGER tr_ej9
ON Item_Factura
AFTER UPDATE
AS
BEGIN

	UPDATE s
	SET s.stoc_cantidad = s.stoc_cantidad - ((i.item_cantidad - d.item_cantidad) * c.comp_cantidad)
	FROM STOCK s
	JOIN Composicion c ON c.comp_producto = s.stoc_producto
	JOIN inserted i ON c.comp_producto = i.item_producto
	JOIN deleted d ON c.comp_producto = d.item_producto

END;
GO