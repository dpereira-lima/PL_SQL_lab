create or replace trigger trg_cancel_consulta
after insert on tbl_cancel_consulta
for each row

declare

v_nr_seq_agendament_sis tbl_agendamento_consulta.nr_seq_agendament_sis%type;
v_nr_seq_agendament_sis2 tbl_transf_consulta.nr_seq_agendament_sis%type;

v_ds_stack varchar2(4000);

v_nr_motivo_cancel agendamento_consulta.cd_motivo_cancelamento%type;
v_nr_seq_ag agendamento_consulta.nr_sequencia%type := null;

procedure gravar_log (ds_fase_p varchar2, ds_stack_p varchar2)

is

begin

    insert into tbl_log_erro(id_age_consulta_hor, dt_agenda, hr_ini, cd_cliente, nm_cliente, dt_nasc, ds_fase, ds_observacao, ds_trigger)
    values(:new.id_age_consulta_hor, null, null, :new.cd_cliente, null, null, ds_fase_p, ds_stack_p, 'Cancelamento');

end;

begin

/*******************************************************************************
-------------------------CANCELAMENTO DA CONSULTA-------------------------------
*******************************************************************************/

    --DE-PARA motivo cancelamento
    v_nr_motivo_cancel := case
                            when :new.id_motivo = 1 then 957
                            when :new.id_motivo = 2 then 959
                            when :new.id_motivo = 3 then 960
                            when :new.id_motivo = 4 then 965
                            when :new.id_motivo = 5 then 959
                            when :new.id_motivo = 6 then 959
                            when :new.id_motivo = 7 then 959
                            when :new.id_motivo = 8 then 959
                            when :new.id_motivo = 9 then 959
                            when :new.id_motivo = 10 then 959
                            when :new.id_motivo = 11 then 959
                        end;

    --agendamento novo
    select
        max(agend_novo.nr_seq_agendament_sis)
    into
        v_nr_seq_agendament_tasy 
    from tbl_agendamento_consulta agend_novo
        inner join agendamento_consulta ac
            on agend_novo.nr_seq_agendament_sis = ac.nr_sequencia
    where agend_novo.id_age_consulta_hor = :new.id_age_consulta_hor
        and agend_novo.cd_cliente = :new.cd_cliente
        and ac.ie_status_agenda = 'N';
    
    --agendamento transferência
    select
        max(transf.nr_seq_agendament_tasy)
    into
        v_nr_seq_agendament_tasy2
    from tbl_transf_consulta transf
        inner join agendamento_consulta ac
            on transf.nr_seq_agendament_tasy = ac.nr_sequencia
    where transf.id_age_consulta_hor = :new.id_age_consulta_hor
        and transf.cd_cliente = :new.cd_cliente
        and ac.ie_status_agenda = 'N';
    
    if nvl(v_nr_seq_agendament_sis, 0) <> 0 then
        v_nr_seq_ag := v_nr_seq_agendament_sis;
    elsif nvl(v_nr_seq_agendament_sis2, 0) <> 0 then
        v_nr_seq_ag := v_nr_seq_agendament_sis2;
    end if;
    
    if nvl(v_nr_seq_ag, 0) <> 0 then
    
        begin

            update agendamento_consulta
            set ie_status_agenda = 'C',
                dt_atualizacao = sysdate,
                nm_usuario = 'Integr',
                cd_motivo_cancelamento = v_nr_motivo_cancel,
                ds_motivo_status = 'Integração',
                dt_status = sysdate,
                nm_usuario_status = 'Integr',
                nm_usuario_cancelamento = 'Integr',
                dt_cancelamento = sysdate,
                ds_observacao = 'Cancelamento executado pela integração.'||chr(13)||
                                    ' Unidade solicitante: '||:new.nome_unidade_solicitante||chr(13)||
                                    ' Usuário solicitante: '||:new.nome_usuario_solicitante||chr(13)||
                                    ' Data: '||:new.dt_ultima_atualiz
            where nr_sequencia = v_nr_seq_ag;

            exception
            when others then
                v_ds_stack :=
                       'error stack: '
                    || sys.dbms_utility.format_error_stack
                    || chr(13)
                    || 'error backtrace: '
                    || sys.dbms_utility.format_error_backtrace
                    || chr(13)
                    || 'call stack: '
                    || sys.dbms_utility.format_call_stack;
                gravar_log('Cancelamento do agendamento',
                        v_ds_stack);

        end;

    else
    
        gravar_log('Cancelamento do agendamento', 'Agendamento de origem não econtrado');
    
    end if;

end;
/


