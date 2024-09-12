create table tbl_log
(
nr_sequencia number(10) default tbl_log_seq primary key,
dt_atualizacao date default sysdate,
nr_processamento number(10),
cd_pessoa varchar2(255),
id_ident number(10),
id_ident_atual varchar2(1),
ds_observacao clob,
ie_atualizacao_sistema varchar2(1)
);
