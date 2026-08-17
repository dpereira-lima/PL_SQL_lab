create or replace trigger AUDITORIA_REG_TRG
after insert or update or delete on ident_visita_estabelecimento

declare

    w_evento varchar2(10);
    
begin

    if inserting then
    
        w_evento := 'INSERT';
        
    elsif updating then
    
        w_evento := 'UPDATE';
        
    elsif deleting then
    
        w_evento := 'DELETE';
        
    end if;

    insert into log_auditoria_tbl (
        dt_atualizacao,
        ds_evento,
        nm_session_user,
        ds_objeto,
        ds_call_stack
    )
    values (
        sysdate,
        w_evento,
        user,
        ora_dict_obj_name,
        dbms_utility.format_call_stack
    );

end;
/