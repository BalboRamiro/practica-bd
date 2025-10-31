/*
	Ejercicio de parcial 25oct-2025 resuelto por Lacquaniti

	Se agregó recientemente un campo CUIT a la tabla de clientes. Debido a un
	error, se generaron múltiples registros de clientes con el mismo CUIT.
	Se deberá desarrollar un algoritmo de depuración de datos que identifique y corrija
	estos duplicados, manteniendo un único registro por CUIT. Será necesario definir un criterio 
	de selección para determinar qué registro conservar y cuáles eliminar.
	
	Adicionalmente, se deberá implementar una restricción que impida la creación futura
	de registros con CUIT duplicado.
*/

-- Primera parte del enunciado
alter table cliente add clie_cuit char(10)

update cliente set clie_cuit = '1'
where clie_codigo in ('00000', '00001', '00002')

create table cliente_auxiliar ( cod char(6), cuit char(10) )

insert into cliente_auxiliar
select
	min(clie_codigo),
	clie_cuit
from cliente
group by clie_cuit

update cliente set clie_cuit = null
update cliente set clie_cuit = (select cuit from cliente_auxiliar where cod = clie_codigo)

-- Segunda parte dle enunciado
alter table cliente add constraint unica unique(cliet_cuit)