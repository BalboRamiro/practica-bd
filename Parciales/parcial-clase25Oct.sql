/*
	Ejercicio de parcial 25oct-2025

	Se agregó recientemente un campo CUIT a la tabla de clientes. Debido a un
	error, se generaron múltiples registros de clientes con el mismo CUIT.
	Se deberá desarrollar un algoritmo de depuración de datos que identifique y corrija
	estos duplicados, manteniendo un único registro por CUIT. Será necesario definir un
	criterio de selección para determinar qué registro conservar y cuáles eliminar.
	
	Adicionalmente, se deberá implementar una restricción que impida la creación futura
	de registros con CUIT duplicado.
*/

SELECT *
INTO #ClienteTemporal
FROM Cliente

ALTER TABLE #ClienteTemporal
ADD clie_cuit INT

SELECT * FROM #ClienteTemporal

-- Rellenar con valores aleatorios (y posibles duplicados)
UPDATE #ClienteTemporal
SET clie_cuit = ABS(CHECKSUM(NEWID())) % 100000000;  -- genera un número aleatorio de hasta 8 cifra

UPDATE #ClienteTemporal
SET clie_cuit = 45479486
WHERE clie_codigo LIKE '00%'

CREATE PROCEDURE corregir_cuit_duplicados() AS
BEGIN
	DECLARE @cuit INT
	
	DECLARE cuit_repetidos CURSOR FOR
	SELECT clie_cuit, COUNT(*) AS cantidad
	FROM #ClienteTemporal
	GROUP BY clie_cuit
	HAVING COUNT(*) > 1

	OPEN cuit_repetidos;
	FETCH NEXT FROM cuit_repetidos INTO @cuit
	WHILE @@FETCH_STATUS = 0
	BEGIN

		DECLARE @primer_clie_que_cumple_criterio char(6)
		
		SELECT TOP 1  @primer_clie_que_cumple_criterio = clie_codigo
		FROM #ClienteTemporal
		WHERE clie_cuit = @cuit
		ORDER BY clie_limite_credito DESC; -- Este es el criterio, aunque se podríam hacer otros mas complejos

		UPDATE #ClienteTemporal SET clie_cuit = NULL 
		WHERE clie_codigo <> @primer_clie_que_cumple_criterio AND clie_cuit = @cuit

		FETCH NEXT FROM cuit_repetidos INTO @cuit
	END

END;
GO

CREATE TRIGGER insertar_no_repetido
ON #ClienteTemporal
INSTEAD OF INSERT
AS
BEGIN

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Cliente c ON i.clie_cuit = c.clie_cuit
    )
    BEGIN
        RAISERROR('El CUIT ya existe en la tabla Cliente', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.Cliente (clie_codigo, clie_cuit)
    SELECT clie_codigo, clie_cuit
    FROM inserted;

END;
GO

-- Prueba select

SELECT clie_cuit, COUNT(*) AS cantidad
FROM #ClienteTemporal
GROUP BY clie_cuit
HAVING COUNT(*) > 1

-- Prueba select

SELECT TOP 1 clie_codigo, clie_limite_credito
FROM #ClienteTemporal
WHERE clie_cuit = '45479486'
ORDER BY clie_limite_credito DESC;

-- Retorna 00220

-- Prueba update
UPDATE #ClienteTemporal SET clie_cuit = NULL 
WHERE clie_codigo <> '00220' AND clie_cuit = '45479486'