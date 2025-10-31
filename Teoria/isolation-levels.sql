-- Prueba niveles de ISOLATIO

-- EJECUTAR EN OTRO SCRIPT EN APRALELO ESTAS SENTENCIAS

BEGIN TRAN;
UPDATE Producto SET prod_detalle = 'CAMBIO NO CONFIRMADO'
WHERE prod_codigo = '00000030';
-- No hacer COMMIT ni ROLLBACK todavía

-- Ejcutar despues
ROLLBACK

--------------------------------------------------------------------------

--========================================================================
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT prod_detalle FROM Producto WHERE prod_codigo = '00000030';
--========================================================================

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT prod_detalle FROM Producto WHERE prod_codigo = '00000030';
-- No termina de ejecutar, porque la transacción no hizo COMMIT o ROLLBACK

--========================================================================

SET TRANSACTION ISOLATION LEVEL REPEATABLE;
BEGIN TRAN;
SELECT prod_detalle FROM Producto WHERE prod_codigo = '00000030';
-- Evita lecturas no repetibles (el valor no puede cambiar mientras la transacción sigue abierta).

--=========================================================================

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRAN;
SELECT * FROM Producto WHERE prod_codigo BETWEEN '00000000' AND '00000099';
-- Este bloquea todo el rango de búsqueda.
-- Si la otra ventana intenta insertar o modificar algo dentro de ese rango (00000030, por ejemplo), queda bloqueada.
-- Máxima consistencia, pero más lentitud.

--==========================================================================

-- Primero activá el modo snapshot en la base (solo una vez)
ALTER DATABASE GD2015C1 SET ALLOW_SNAPSHOT_ISOLATION ON;

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRAN;
SELECT prod_detalle FROM Producto WHERE prod_codigo = '00000030';
-- Te trae la version anterior confirmada, sin bloquearse ni mostrar el cambio pendiente.