create or replace trigger trg_transf_consulta
before insert on tbl_transf_consulta
for each row

declare

v_nr_seq_agendament_sis     tbl_agendamento_consulta.nr_seq_agendament_sis%type;
v_cd_pessoa_sis             tbl_agendamento_consulta.cd_pessoa_sis%type;
v_nr_sequencia              tbl_agendamento_consulta.nr_sequencia%type;

v_nr_seq_agendamento        agendamento_consulta.nr_sequencia%type;
v_nr_motivo_transf          agendamento_consulta.nr_seq_motivo_transf%type;

v_cd_pessoa_fisica          pessoa.cd_pessoa%type;
v_nm_pessoa_fisica          pessoa.nm_pessoa%type;
v_dt_nascimento             pessoa.dt_nasc%type;
v_qt_idade                  varchar2(100);

v_ds_stack                  varchar2(4000);

procedure gravar_log(ds_fase_p varchar2, ds_stack_p varchar2)

is

begin

    insert into tbl_log_erro(id_age_consulta_hor, dt_agenda, hr_ini, cd_cliente, nm_paciente, dt_nascimento, ds_fase, ds_observacao, ds_trigger)
    values(:new.id_age_consulta_hor, null, null, :new.cd_cliente, null, null, ds_fase_p, ds_stack_p, 'Transferência');

end;

begin

/*******************************************************************************
--------------------------TRANSFERÊNCIA DA CONSULTA-----------------------------
*******************************************************************************/

    --DE-PARA do motivo de transferência
    v_nr_motivo_transf := case
                            when :new.id_motivo = 1 then 35
                            when :new.id_motivo = 2 then 35
                            when :new.id_motivo = 3 then 33
                            when :new.id_motivo = 4 then 34
                            when :new.id_motivo = 5 then 33
                            when :new.id_motivo = 6 then 33
                            when :new.id_motivo = 7 then 35
                        end;

--Consulta dados cliente e agendamento origem
    select
        max(nr_sequencia)
    into
        v_nr_sequencia
    from tbl_agendamento_consulta
    where id_age_consulta_hor = :new.id_age_consulta_hor_origem
        and cd_cliente = :new.cd_cliente;
    
    if nvl(v_nr_sequencia, 0) <> 0 then

        select
            pf.cd_pessoam, pf.nm_pessoa, pf.dt_nasc, idade_get(pf.dt_nasc, sysdate, 'A') qt_idade, ag.nr_seq_agendament_sis, ag.cd_pessoa_sis
        into
            v_cd_pessoa, v_nm_pessoa, v_dt_nasc, v_qt_idade, v_nr_seq_agendament_sis, v_cd_pessoa_fisica_sis
        from pessoa pf
            inner join tbl_agendamento_consulta ag
                on pf.nr_cpf = ag.cpf
        where ag.nr_sequencia = v_nr_sequencia;

        --Cancelamento agendamento origem
        begin

            update agendamento_consulta
            set ie_status_agenda = 'C',
                dt_atualizacao = sysdate,
                cd_motivo_cancelamento = 33,
                ds_motivo_copia_trans = 'Integração',
                nm_usuario = 'Integr',
                ds_observacao = 'Motivo cancelamento: transferência do agendamento pela integração.'||chr(13)||
                                    ' Nova data: '||to_date(:new.data_agenda||' '||:new.hor_ini, 'yyyy/mm/dd hh24:mi:ss')
            where nr_sequencia = v_nr_seq_agendament_sis
                and cd_pessoa = v_cd_pessoa_sis;

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
                gravar_log('Cancelamento do agendamento origem - para transferência',
                        v_ds_stack);

        end;
        
        --Insert novo agendamento - transferência
        begin
            
            v_nr_seq_agendamento := agendamento_consulta_seq.nextval;
        
            insert into agendamento_consulta(nr_sequencia, cd_agenda, dt_agenda, nr_minuto_duracao, ie_status_agenda,
                                            ie_classif_agenda, dt_atualizacao, nm_usuario, cd_convenio, cd_pessoa, 
                                            nm_cliente, qt_idade_pac, nm_login_origem, nr_seq_sala, cd_categoria, 
                                            cd_tipo_acomodacao, dt_nasc_cli, cd_turno, dt_agendamento, nr_seq_hora, 
                                            cd_setor_atendimento, nr_seq_turno, nr_seq_turno_esp, cd_convenio_turno,
                                            cd_motivo_cancelamento, ds_motivo_copia_trans, nm_usuario_copia_trans,
                                            dt_copia_trans, nr_seq_motivo_transf, ie_transferido, ds_observacao)
                                    values(v_nr_seq_agendamento, 29768, to_date(:new.dt_agenda||' '||:new.hr_ini, 'yyyy/mm/dd hh24:mi:ss'), 
                                            30, 'N', 'P77', sysdate, 'Integr', 1, v_cd_pessoa, v_nm_pessoa, v_qt_idade, 'Integr',
                                            249, 12, 4, v_dt_nasc, 0, sysdate, 1, 410, 0, 0, 1,
                                            33, 'Integração', 'Integr', sysdate, v_nr_motivo_transf, 'S',
                                            'Agendamento transferido pela integração.'||chr(13)||
                                                ' Unidade solicitante: '||:new.nm_unidade_solicitante||chr(13)||
                                                ' Usuário solicitante: '||:new.nm_usuario_solicitante||chr(13)||
                                                ' Data: '||:new.dt_ultima_atualiz);
                                            
            :new.nr_seq_agendament_sis := v_nr_seq_agendamento;

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
                gravar_log('Insert novo agendamento - transferência',
                        v_ds_stack);

        end;

    else
    
        gravar_log('Transferência do agendamento', 'Agendamento de origem não econtrado');
    
    end if;

end;
/


