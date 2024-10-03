--tabela transferência

create sequence tbl_transf_consulta_seq nocache;

create table tbl_transf_consulta
(
tp_consulta varchar2(100),
cd_unidade_executante number(11),
id_age_consulta_hor_origem number(11),
id_age_consulta_hor number(11),
id_age_consulta number(11),
id_especialidade number(11),
nm_especialidade varchar2(50),
cd_dia number(11),
dt_agenda varchar2(12),
hr_ini varchar2(10),
hr_fim varchar2(10),
cd_cliente number(11),
tp_evento varchar2(1),
id_motivo number(3),
id_protocolo number(11),
id_profissional number(11),
doc_profissional varchar2(45),
origem varchar2(45),
nm_profissional varchar2(60),
cd_unidade_solicitante number(11),
nm_unidade_solicitante varchar2(100),
nm_usuario_solicitante varchar2(100),
dt_ultima_atualiz varchar2(20),
nr_sequencia number(30) default tbl_transf_consulta_seq.nextval primary key,
dt_atualizacao date default sysdate,
nr_seq_agendament_tasy number(10)
);

