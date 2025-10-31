BEGIN
	DECLARE @var int
	DECLARE @var2 char(100)
	DECLARE @var3 datetime
	DECLARE @cod char(6)
	DECLARE @nombre char(100)

	SET @cod = '00000'

	SELECT
		@nombre = CLIE_RAZON_SOCIAL
	FROM dbo.Cliente
	WHERE
		CLIE_CODIGO = @cod

	PRINT @nombre

	IF not (SELECT COUNT(*) FROM Cliente WHERE clie_razon_social = @nombre ) > 1
	begin
		print ' no hay mas de 1 cliente con el mismo nombre que el clie 00000'
	end

END


-- A - Atomicidad: "O se ejcuta todo o no se ejecuta ninguno"
-- C - Consistencia
-- I - Isolation (Aislamiento)
-- D - Durabilidad

BEGIN TRANSACTION

	DECLARE @nombre2 char(100)

	UPDATE Producto SET
		prod_detalle = 'CAMBIADO POR TRX 2 '
	WHERE
		prod_codigo = '00000030'

	select @nombre2 = p.prod_detalle from Producto p where prod_codigo = '00000030'
	print @nombre2

COMMIT