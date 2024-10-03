--tabela cancelamento

create sequence tbl_cancel_consulta_seq nocache;

create table tbl_cancel_consulta
(
tp_consulta varchar2(100),
cd_unidade_executante number(11),
id_age_consulta_hor number(11),
cd_cliente number(11),
tp_evento varchar2(1),
id_motivo number(2),
cd_unidade_solicitante number(11),
nm_unidade_solicitante varchar2(200),
cnes_unidade_solicitante varchar2(100),
nm_usuario_solicitante varchar2(100),
dt_ultima_atualiz varchar2(20),
nr_sequencia number(30) default tbl_cancel_consulta_seq.nextval primary key,
dt_atualizacao date default sysdate
);