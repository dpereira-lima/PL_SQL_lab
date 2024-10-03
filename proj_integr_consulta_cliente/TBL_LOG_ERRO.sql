--tabela logs de erros e comportamento

create sequence tbl_log_erro_seq nocache;

create table tbl_log_erro
(
id_age_consulta_hor number(11),
dt_agenda varchar2(10),
hr_ini varchar2(8),
cd_cliente number(11),
nm_cliente varchar2(60),
dt_nasc varchar2(10),
--obs
ds_fase varchar2(4000),
ds_observacao varchar2(4000),
ds_trigger varchar2(4000),
--controle interno
nr_sequencia number(30) default tbl_log_erro_seq.nextval primary key,
dt_atualizacao date default sysdate
);

