create sequence seq_log_reg_erro nocache;

create table tbl_log_reg_erro 
(
nr_registro number default seq_log_reg_erro.nextval primary key,
dt_log date default sysdate,
ie_tipo varchar2(1),
nr_seq_registro number(35),
ds_stack varchar2(4000),
nr_seq_emprestimo number,
nr_seq_producao number,
nr_seq_reserva number,
nr_seq_reserva_item number
);

