create or replace trigger trg_agendamento_consulta
before insert on tbl_agendamento_consulta
for each row

declare

v_nr_seq_loc            w_pessoa_loc.nr_sequencia%type;

v_cd_pessoa             pessoa.cd_pessoa%type;
v_nm_pessoa             pessoa.nm_pessoa%type;
v_dt_nasc               pessoa.dt_nasc%type;
v_qt_idade              varchar2(100);
v_nr_cpf                pessoa.nr_cpf%type;
v_nr_cpf2               pessoa.nr_cpf%type := regexp_replace(:new.cpf, '[^[:alnum:]]', '');
v_nm_social             pessoa.nm_social%type;
v_nr_cartao_nac_sus     pessoa.nr_cartao_nac_sus%type;
v_ie_sexo               pessoa.ie_sexo%type;
v_nr_identidade         pessoa.nr_identidade%type;
v_ie_estado_civil       pessoa.ie_estado_civil%type;
v_cd_nacionalidade      pessoa.cd_nacionalidade%type;
v_nm_mae                compl_pessoa.nm_contato%type;
v_nm_pai                compl_pessoa.nm_contato%type;
v_cd_cep                compl_pessoa.cd_cep%type;
v_ds_endereco           compl_pessoa.ds_endereco%type;
v_nr_endereco           compl_pessoa.nr_endereco%type;
v_ds_bairro             compl_pessoa.ds_bairro%type;
v_ds_municipio          compl_pessoa.ds_municipio%type;
v_sg_estado             compl_pessoa.sg_estado%type;
v_ds_email              compl_pessoa.ds_email%type;
v_nr_ddd_telefone       compl_pessoa.nr_ddd_telefone%type;
v_nr_telefone           compl_pessoa.nr_telefone%type;
v_nr_seq_pais           compl_pessoa.nr_seq_pais%type;
v_cd_tipo_logradouro    compl_pessoa.cd_tipo_logradouro%type;

v_nr_seq_agendamento    agendamento_consulta.nr_sequencia%type;

v_ds_stack              varchar2(4000);

v_msg                   varchar(32767);
v_id_dw                 pessoa.identificador_dw%type;


procedure gravar_log(ds_fase_p varchar2, ds_stack_p varchar2)

is

begin

    insert into tbl_log_erro(id_age_consulta_hor, dt_agenda, hr_ini, cd_cliente, nm_cliente, dt_nasc, ds_fase, ds_observacao, ds_trigger)
    values(:new.id_age_consulta_hor, :new.dt_agenda, :new.hr_ini, :new.cd_cliente, :new.nm_cliente, :new.dt_nasc, ds_fase_p, ds_stack_p, 'Agendamento');

end;

procedure incluir_classif(cd_pessoa_p varchar2)

is

begin

    insert into classif_cliente(nr_sequencia, dt_atualizacao, nm_usuario, nr_seq_classif, cd_pessoa, dt_inicio_vigencia, ds_observacao)
    values (classif_cliente_seq.nextval, sysdate, 'Integr', 668, cd_pessoa_p, sysdate, 'Integração');
    
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
        gravar_log('Vincular a classificação',
                v_ds_stack);

end;

begin

/*******************************************************************************
-----------------------------CADASTRO CLIENTE-----------------------------------
*******************************************************************************/

    --VERIFICANDO SE NO SISTEMA HÁ CADASTRADO DO CLIENTE
    select
        max(cd_pessoa)
    into
        v_cd_pessoa
    from pessoa pf
    where pf.nr_cpf = v_nr_cpf2;
    
    if nvl(v_cd_pessoa, '0') = '0' then
    
    --VERIFICANDO SE HÁ CADASTRADO DO CLIENTE
        --se cliente estiver, a tabela W_Pessoa_Loc será populada
        prc_localizar_cliente('Integr', v_nr_cpf2);
        
        select
            max(nr_sequencia)
        into
            v_nr_seq_loc
        from w_pessoa_loc
        where nr_cpf = v_nr_cpf2
            and nm_usuario = 'Integr';

        if nvl(v_nr_seq_loc, 0) <> 0 then
        
            begin
    
                --incluir cliente
                incluir_cliente('Integr', v_nr_seq_loc, v_cd_pessoa);
                
                --vincular a classificação
                incluir_classif(v_cd_pessoa);
                
                :new.cd_pessoa_sis := v_cd_pessoa;

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
                    gravar_log('1 - Incluir cliente',
                            v_ds_stack);

            end;

    --CLIENTE SEM CADASTRO
        else
        
            --incluir cliente
            begin
        
                v_cd_pessoa := pessoa_seq.nextval;

                insert into pessoa(cd_pessoa, ie_tipo_pessoa, nm_pessoa_fisica, dt_atualizacao, nm_usuario, dt_nascimento, ie_sexo, nr_cpf, nr_identidade, 
                                nr_cartao_nac_sus, identificador_dw, nr_prontuario, nr_pront_dv, cd_nacionalidade, ie_estado_civil, ds_observacao)
                values(v_cd_pessoa, 2, exclui_caract_especial(:new.nome_paciente), sysdate, 'Integr', to_date(:new.dt_nascimento, 'yyyy-mm-dd'), 
                        :new.sexo, :new.cpf, :new.rg, :new.num_cns, null, null, null, 10, 1,
                        'Cadastro realizado via integração. - Data: '||to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss'));

                --RESP 1
                insert into compl_pessoa(cd_pessoa, nr_sequencia, ie_tipo_complemento, nm_contato, dt_atualizacao, nm_usuario)
                values(v_cd_pessoa, 1, 5, exclui_caract_especial(:new.nome_mae), sysdate, 'Integr');

                --RESP 2
                insert into compl_pessoa(cd_pessoa, nr_sequencia, ie_tipo_complemento, nm_contato, dt_atualizacao, nm_usuario)
                values(v_cd_pessoa, 2, 4, exclui_caract_especial(:new.nome_pai), sysdate, 'Integr');

                --ENDEREÇO
                insert into compl_pessoa(cd_pessoa, nr_sequencia, ie_tipo_complemento, nm_contato, dt_atualizacao, nm_usuario, cd_cep, ds_endereco, nr_endereco, 
                                    ds_bairro, ds_municipio, sg_estado, nr_ddd_telefone, nr_telefone, ds_email, nr_seq_pais, cd_tipo_logradouro)
                values(v_cd_pessoa, 3, 1, exclui_caract_especial(:new.nome_mae), sysdate, 'Integr', 
                        regexp_replace(exclui_caract_especial(:new.cep), '[^[:digit:]]', ''), replace(regexp_replace(exclui_caract_especial(:new.endereco), '[[:digit:]]', ''),',',''), 
                        nvl(regexp_replace(exclui_caract_especial(:new.endereco_numero), '[^[:digit:]]', ''), regexp_replace(exclui_caract_especial(:new.endereco), '[^[:digit:]]', '')), 
                        exclui_caract_especial(:new.bairro), exclui_caract_especial(:new.municipio), :new.uf, nvl(:new.contato_tel_ddd, :new.tel_celular_ddd), nvl(:new.contato_tel, :new.tel_celular),
                        :new.email, 1, '081');

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
                    gravar_log('2 - Incluir cliente',
                            v_ds_stack);

            end;

            --incluir classificação
            begin

                --Vincular a classificação
                incluir_classif(v_cd_pessoa);
                
                :new.cd_pessoa_tasy := v_cd_pessoa;

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
                    gravar_log('3 - Incluir classificação',
                            v_ds_stack);

            end;

            --incluir cliente
            begin

                select
                    pac.nr_cpf, pac.nm_pessoa, pac.nm_social, pac.dt_nasc, pac.nr_cartao_nac_sus, pac.ie_sexo, pac.nr_identidade,
                    pac.ie_estado_civil, pac.cd_nacionalidade,
                    rep1.nm_contato nm_mae,  
                    rep2.nm_contato nm_pai,
                    ender.cd_cep, ender.ds_endereco, ender.nr_endereco, ender.ds_bairro, ender.ds_municipio, ender.sg_estado, 
                    ender.nr_ddd_telefone, ender.nr_telefone, ender.ds_email, ender.nr_seq_pais, ender.cd_tipo_logradouro
                into
                    v_nr_cpf, v_nm_pessoa, v_nm_social, v_dt_nasc, v_nr_cartao_nac_sus, v_ie_sexo, v_nr_identidade,
                    v_ie_estado_civil, v_cd_nacionalidade,
                    v_nm_mae,
                    v_nm_pai,
                    v_cd_cep, v_ds_endereco, v_nr_endereco, v_ds_bairro, v_ds_municipio, v_sg_estado, 
                    v_nr_ddd_telefone, v_nr_telefone, v_ds_email, v_nr_seq_pais, v_cd_tipo_logradouro
                from (select max(cd_pessoa) cd_pessoa
                        from pessoa
                        where cd_pessoa = v_cd_pessoa) base
                    inner join pessoa pac
                        on base.cd_pessoa = pac.cd_pessoa
                    left join compl_pessoa rep1
                        on pac.cd_pessoa = rep1.cd_pessoa
                        and rep1.ie_tipo_complemento = 5
                    left join compl_pessoa rep2
                        on pac.cd_pessoa = rep2.cd_pessoa
                        and rep2.ie_tipo_complemento = 4
                    left join compl_pessoa ender
                        on pac.cd_pessoa = ender.cd_pessoa
                        and ender.ie_tipo_complemento = 1;

                --Incluir paciente Ensemble
                cliente_http(v_cd_pessoa, v_nr_cpf, v_nm_pessoa, v_nm_social, v_dt_nasc, v_nm_mae, null, v_nm_pai,
                    null, v_nr_cartao_nac_sus, v_ie_sexo, 1, v_ie_estado_civil,  null, v_ds_municipio, 
                    v_sg_estado, v_cd_cep, v_ds_endereco, v_ds_municipio, v_nr_endereco, v_ds_bairro, v_sg_estado, null, to_char(v_cd_tipo_logradouro), 
                    null, v_cd_nacionalidade, v_nm_mae, null, null, v_nr_seq_pais, v_ds_email, v_nr_telefone, v_nr_telefone, v_nr_telefone, 
                    v_nr_identidade, null, null, null, 'C', 'Integr', v_msg, v_id_dw, null, null);

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
                    gravar_log('4 - Incluir paciente Ensemble',
                            v_ds_stack);

            end;
            
            begin
            
                update pessoa
                set identificador = v_id
                where cd_pessoa = v_cd_pessoa;

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
                    gravar_log('5 - Atualizar cadastro com ID',
                            v_ds_stack);

            end;
            
        end if;

    end if;

/*******************************************************************************
----------------------------AGENDAMENTO DO CLIENTE------------------------------
*******************************************************************************/

    if (nvl(v_cd_pessoa, '0') <> '0') then
    
        begin
        
            select
                cd_pessoa, nm_pessoa, dt_nasc, age_get(dt_nasc, sysdate, 'A') qt_idade
            into
                v_cd_pessoa, v_nm_pessoa, v_dt_nasc, v_qt_idade
            from pessoa
            where cd_pessoa = v_cd_pessoa;
            
            v_nr_seq_agendamento := agendamento_consulta_seq.nextval;
        
            insert into agendamento_consulta(nr_sequencia, cd_agenda, dt_agenda, nr_minuto_duracao, ie_status_agenda,
                                            ie_classif_agenda, dt_atualizacao, nm_login, cd_convenio, cd_pessoa, 
                                            nm_paciente, qt_idade_pac, nm_usuario_origem, nr_seq_sala, cd_categoria, 
                                            cd_tipo_acomodacao, dt_nascimento_pac, cd_turno, dt_agendamento, nr_seq_hora, 
                                            cd_setor_atendimento, nr_seq_turno, nr_seq_turno_esp, cd_convenio_turno,
                                            ds_observacao)
                                    values(v_nr_seq_agendamento, 29768, to_date(:new.dt_agenda||' '||:new.hr_ini, 'yyyy/mm/dd hh24:mi:ss'), 
                                            30, 'N', 'P77', sysdate, 'Integr', 1, v_cd_pessoa, v_nm_pessoa, v_qt_idade, 'Integr',
                                            249, 12, 4, v_dt_nasc, 0, sysdate, 1, 410, 0, 0, 1,
                                            'Agendamento criado via integração.'||chr(13)||
                                            ' Unidade solicitante: '||:new.nm_unidade_solicitante||chr(13)||
                                            ' Profissional: '||:new.nm_profissional||' '||nvl2(:new.doc_profissional, :new.origem||' '||:new.doc_profissional, ' ')||chr(13)||
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
                gravar_log('6 - Agendamento do cliente',
                        v_ds_stack);

        end;
    
    else
    
        gravar_log('Novo agendamento', 'Não localizado cadastro do cliente');
    
    end if;

end;
/


