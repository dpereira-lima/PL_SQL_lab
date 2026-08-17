create table LOG_AUDITORIA_TBL
(
    dt_atualizacao date,
    ds_evento varchar2(200),
    nm_session_user varchar2(200),
    ds_objeto varchar2(200),
    ds_call_stack clob
);