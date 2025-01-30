create or replace trigger tgr_import_info_sistema
after insert on tbl_intermediaria
for each row

declare
nr_seq_sup_w emprestimo_tbl.nr_registro_tbl%type;
nr_seq_hemo_w emprestimo_tbl.nr_registro_tbl%type;
nr_seq_derivado_w derivado_tbl.nr_registro_tbl%type;
qt_dias_validade_w derivado_tbl.qt_dias_validade%type;
nr_seq_reserva_w reserva_tbl.nr_registro_tbl%type;
nr_seq_reserva_temp_w reserva_tbl.nr_registro_tbl%type;
nr_seq_reserva_prod_w reserva_prod_tbl.nr_registro_tbl%type;
nr_seq_reserva_prod_2_w reserva_prod_tbl.nr_registro_tbl%type;
nr_ficha_atend_w prescricao_tbl.nr_ficha_atend%type;
cd_cliente_w prescricao_tbl.cd_cliente%type;
cd_medico_w prescricao_tbl.cd_medico%type;
ie_tipo_w prescr_solic_sangue_tbl.ie_tipo%type;
qt_procedimento_w cp_hemoterapia_tbl.qt_procedimento%type;
ie_status_reserv_w reserva_tbl.ie_status%type;
qt_solicitada_w reserva_item_tbl.qt_solicitada%type;
nr_seq_item_w reserva_item_tbl.nr_seq_item%type;
nr_prontuario_w varchar2(400);
ie_consit_nm_componente_w varchar2(1);
cd_bolsa_abo_w valor_atribuicao.vl_atribuicao%type;
cd_fator_rh_w valor_atribuicao.vl_atribuicao%type;

--variavel log exception
ds_stack_w varchar2(4000);
ie_barras_bolsa_reserv_w number;

procedure gravar_log_erro (ie_tipo_p varchar2, nr_seq_registro_p number, ds_stack_p varchar2)

is

begin

    --gravando o log na tabela
    insert into tbl_log_reg_erro(ie_tipo, nr_seq_registro, ds_stack)
    values(ie_tipo_p, nr_seq_registro_p, ds_stack_p);

end;

procedure gravar_log (nr_seq_registro_p number, 
    nr_seq_san_emprestimo_p number := null, nr_seq_san_producao_p number := null, nr_seq_san_reserva_1_p number := null,
    nr_seq_san_reserva_item_1_p number := null)

is

begin

    --gravando o log na tabela
    insert into tbl_log_reg_erro(ie_tipo, nr_seq_registro, nr_seq_san_emprestimo, nr_seq_san_producao, nr_seq_san_reserva_1, 
        nr_seq_san_reserva_item_1)
    values('R', nr_seq_registro_p, nr_seq_san_emprestimo_p, nr_seq_san_producao_p, nr_seq_san_reserva_1_p, nr_seq_san_reserva_item_1_p);

end;

begin

--Verificando se o número da Solicitacao não é nulo e númerico
    if (nvl(:new.nr_solicitacao, 0) <> 0) then

        begin
        
        --obtendo dados do pedido médico (Solicitacao)    
            select
                pm.nr_ficha_atend,
                pm.cd_cliente,
                pm.cd_medico,
                psbs.ie_tipo,
                ch.qt_procedimento,
                pf.nr_prontuario
            into
                nr_ficha_atend_w,
                cd_cliente_w,
                cd_medico_w,
                ie_tipo_w,
                qt_procedimento_w,
                nr_prontuario_w
            from prescricao_tbl pm
                inner join cliente pf
                    on pm.cd_cliente = pf.cd_cliente
                inner join (select max(nr_registro_tbl) nr_registro_tbl, nr_solicitacao
                            from prescr_solic_sangue_tbl
                            group by nr_solicitacao) base
                    on pm.nr_solicitacao = base.nr_solicitacao
                inner join prescr_solic_sangue_tbl psbs
                    on base.nr_registro_tbl = psbs.nr_registro_tbl
                inner join cp_hemoterapia_tbl ch
                    on psbs.nr_seq_hemo_cpoe = ch.nr_registro_tbl
            where pm.nr_solicitacao = :new.nr_solicitacao;

            exception
            when others then
                ds_stack_w := 'Obtendo dados do pedido médico (Solicitacao)'||chr(13)||
                       'error stack: '
                    ||sys.dbms_utility.format_error_stack
                    ||chr(13)
                    ||'error backtrace: '
                    ||sys.dbms_utility.format_error_backtrace
                    ||chr(13)
                    ||'call stack: '
                    ||sys.dbms_utility.format_call_stack;
                gravar_log_erro('I', :new.nr_registro_tbl, ds_stack_w);

            return;

        end;

        begin
        
        --Consulta cadastro hemocomponente
            select
                nr_registro_tbl,
                qt_dias_validade,
                fnc_valida_tp_hemocomponente(ds_derivado) ie_consit_nm_componente
            into
                nr_seq_derivado_w,
                qt_dias_validade_w,
                ie_consit_nm_componente_w
            from derivado_tbl
            where sg_sigla = substr(upper(:new.cd_produto),1,instr(upper(:new.cd_produto), 'V') -1)
                and ie_situacao = 'A';

            exception
            when others then
                ds_stack_w := 'Consulta cadastro hemocomponente'||chr(13)||
                       'error stack: '
                    ||sys.dbms_utility.format_error_stack
                    ||chr(13)
                    ||'error backtrace: '
                    ||sys.dbms_utility.format_error_backtrace
                    ||chr(13)
                    ||'call stack: '
                    ||sys.dbms_utility.format_call_stack;
                gravar_log_erro('I', :new.nr_registro_tbl, ds_stack_w);
                        
            return;

        end;

    --obtendo dados do registro da reserva gerado através do pedido médico pelo sistema
        if ie_consit_nm_componente_w = 'N' then /*Tipo de hemocomomente: Crio e Plama*/
        
            begin
        
                select
                    sr.nr_registro_tbl,
                    sr.ie_status,
                    sri.qt_solicitada,
                    sri.nr_seq_item,
                    srp.nr_registro_tbl
                into
                    nr_seq_reserva_w,
                    ie_status_reserv_w,
                    qt_solicitada_w,
                    nr_seq_item_w,
                    nr_seq_reserva_prod_2_w
                from (select min(a.nr_registro_tbl) nr_registro_tbl, a.nr_solicitacao
                        from reserva_tbl a
                        where nr_solicitacao = :new.nr_solicitacao
                        group by a.nr_solicitacao) base1
                    inner join reserva_tbl sr
                        on base1.nr_registro_tbl = sr.nr_registro_tbl
                    inner join reserva_item_tbl sri
                        on sr.nr_registro_tbl = sri.nr_seq_reserva
                    left join (select max(nr_registro_tbl) nr_registro_tbl, nr_seq_reserva
                                from reserva_prod_tbl
                                group by nr_seq_reserva) base2
                        on sr.nr_registro_tbl = base2.nr_seq_reserva
                    left join reserva_prod_tbl srp
                        on base2.nr_registro_tbl = srp.nr_registro_tbl;

                exception
                when others then
                    ds_stack_w := 'Obtendo dados do registro da reserva gerado através do pedido médico pelo sistema. 1'||chr(13)||
                           'error stack: '
                        ||sys.dbms_utility.format_error_stack
                        ||chr(13)
                        ||'error backtrace: '
                        ||sys.dbms_utility.format_error_backtrace
                        ||chr(13)
                        ||'call stack: '
                        ||sys.dbms_utility.format_call_stack;
                    gravar_log_erro('I', :new.nr_registro_tbl, ds_stack_w);

                return;
            
            end;

        else

            begin
            
                select
                    sr.nr_registro_tbl,
                    sr.ie_status,
                    sri.qt_solicitada,
                    sri.nr_seq_item,
                    srp.nr_registro_tbl
                into
                    nr_seq_reserva_w,
                    ie_status_reserv_w,
                    qt_solicitada_w,
                    nr_seq_item_w,
                    nr_seq_reserva_prod_2_w
                from (select min(a.nr_registro_tbl) nr_registro_tbl, a.nr_solicitacao
                        from reserva_tbl a
                        where nr_solicitacao = :new.nr_solicitacao
                                and ie_status = 'R'
                        group by a.nr_solicitacao) base1
                    inner join reserva_tbl sr
                        on base1.nr_registro_tbl = sr.nr_registro_tbl
                    inner join reserva_item_tbl sri
                        on sr.nr_registro_tbl = sri.nr_seq_reserva
                    left join (select max(nr_registro_tbl) nr_registro_tbl, nr_seq_reserva
                                from reserva_prod_tbl
                                group by nr_seq_reserva) base2
                        on sr.nr_registro_tbl = base2.nr_seq_reserva
                    left join reserva_prod_tbl srp
                        on base2.nr_registro_tbl = srp.nr_registro_tbl;

                exception
                when others then
                    ds_stack_w := 'Obtendo dados do registro da reserva gerado através do pedido médico pelo sistema. 2'||chr(13)||
                           'error stack: '
                        ||sys.dbms_utility.format_error_stack
                        ||chr(13)
                        ||'error backtrace: '
                        ||sys.dbms_utility.format_error_backtrace
                        ||chr(13)
                        ||'call stack: '
                        ||sys.dbms_utility.format_call_stack;
                    gravar_log_erro('I', :new.nr_registro_tbl, ds_stack_w);

                return;

            end;
            
        end if;

        begin
        
        --Consulta tipo sanguíneo (A, B, AB e O) da bolsa
            select
                max(vl_atribuicao)
            into
                cd_bolsa_abo_w
            from valor_atribuicao
            where cd_dominio = 1173
                and trim(vl_atribuicao) = trim(upper(:new.cd_bolsa_abo));

            exception
            when others then
                ds_stack_w := 'Consulta tipo sanguíneo (A, B, AB e O) da bolsa'||chr(13)||
                       'error stack: '
                    ||sys.dbms_utility.format_error_stack
                    ||chr(13)
                    ||'error backtrace: '
                    ||sys.dbms_utility.format_error_backtrace
                    ||chr(13)
                    ||'call stack: '
                    ||sys.dbms_utility.format_call_stack;
                gravar_log_erro('I', :new.nr_registro_tbl, ds_stack_w);
                        
            return;

        end;

        begin
        
        --Consulta Fator RH (+ ou -) da bolsa
            select
                max(vl_atribuicao)
            into
                cd_fator_rh_w
            from valor_atribuicao
            where cd_dominio = 1174
                and trim(vl_atribuicao) = case
                                        when trim(lower(:new.cd_fator_rh)) = 'negativo' then '-'
                                        when trim(lower(:new.cd_fator_rh)) = 'positivo' then '+'
                                    end;

            exception
            when others then
                ds_stack_w := 'Consulta Fator RH (+ ou -) da bolsa'||chr(13)||
                       'error stack: '
                    ||sys.dbms_utility.format_error_stack
                    ||chr(13)
                    ||'error backtrace: '
                    ||sys.dbms_utility.format_error_backtrace
                    ||chr(13)
                    ||'call stack: '
                    ||sys.dbms_utility.format_call_stack;
                gravar_log_erro('I', :new.nr_registro_tbl, ds_stack_w);
                        
            return;

        end;

        begin
        
            select
                count(*)
            into
                ie_barras_bolsa_reserv_w
            from producao_tbl
            where (upper(nr_sangue) like '%'||upper(:new.cd_bolsa)||'%'
                    or upper(cd_barras) like '%'||upper(:new.cd_bolsa)||'%');

        end;

    --Verificando se a reserva já tem uma bolsa vinculada ou tipo hemocomponente permite vincular mais de uma bolsa na reserva 
        if (ie_barras_bolsa_reserv_w = 0) then

        --verificando se a Solicitacao esta vinculada ao paciente
            if (nr_prontuario_w = regexp_replace(:new.nr_registro_paciente, '[^[:digit:]]', '')) then

                --REGISTROS DA FUNÇÃO HEMOTERAPIA - ABA ENTRADA DOS HEMOCOMPONENTES
                --criação regitro cabeçalho hemocomponente
                    nr_seq_sup_w := emprestimo_seq.nextval;

                    begin

                        insert into emprestimo_tbl(nr_registro_tbl, nr_seq_entidade, dt_registro, nm_login, ie_entrada_saida, dt_emprestimo, cd_pf_realizou, cd_estabelecimento)
                        values (nr_seq_sup_w, 11, sysdate, 'Integracao', 'E', sysdate, '12345', 1);

                        exception
                        when others then
                            ds_stack_w := 'Criação regitro cabeçalho hemocomponente'||chr(13)||
                                   'error stack: '
                                ||sys.dbms_utility.format_error_stack
                                ||chr(13)
                                ||'error backtrace: '
                                ||sys.dbms_utility.format_error_backtrace
                                ||chr(13)
                                ||'call stack: '
                                ||sys.dbms_utility.format_call_stack;
                            gravar_log_erro('I', :new.nr_registro_tbl, ds_stack_w);
                                    
                        return;

                    end;

                --CRIAÇÃO REGITRO HEMOCOMPONENTE    
                    nr_seq_hemo_w := producao_seq.nextval;
                    
                    begin

                        insert into producao_tbl(nr_registro_tbl, nr_seq_derivado, dt_producao, cd_pf_realizou, dt_registro, nm_login, dt_vencimento, nr_sangue, nr_seq_emp_ent, 
                             ie_irradiado, ie_lavado, ie_aliquotado, cd_barras, ie_aferese, ie_pai_reproduzido, ie_reproduzido, ie_realiza_nat, 
                            cd_estabelecimento, ie_pool, ie_tipo_bloqueio, ie_em_reproducao, qt_unidade, ie_filtrado, dt_liberacao, nm_usuario_lib, ie_tipo_sangue, ie_fator_rh)
                        values(nr_seq_hemo_w, nr_seq_derivado_w , sysdate, '12345', sysdate, 'Integracao', trunc(sysdate) + qt_dias_validade_w, :new.cd_bolsa, nr_seq_sup_w, 
                            'N', 'N', 'N', :new.cd_bolsa, 'N', 'N', 'N', 'N', 1, 'N', 'N', 'N', 1, 'N', sysdate, 'Integracao', cd_bolsa_abo_w, cd_fator_rh_w);

                        update emprestimo_tbl
                        set dt_fechamento = sysdate
                        where nr_registro_tbl = nr_seq_sup_w;
                    
                        exception
                        when others then
                            ds_stack_w := 'Criação regitro hemocomponente'||chr(13)||
                                   'error stack: '
                                ||sys.dbms_utility.format_error_stack
                                ||chr(13)
                                ||'error backtrace: '
                                ||sys.dbms_utility.format_error_backtrace
                                ||chr(13)
                                ||'call stack: '
                                ||sys.dbms_utility.format_call_stack;
                            gravar_log_erro('I', :new.nr_registro_tbl, ds_stack_w);
                                    
                        return;
                    
                    end;
     
                --tratamento para solicições de mais de 1 bolsa de sangue
                    -- e tipo componente diferente de Crio ou Plasma
                    if (qt_solicitada_w > 1) and (ie_consit_nm_componente_w = 'S') then
                    
                        begin
                        
                            nr_seq_reserva_temp_w := nr_seq_reserva_w;
                    
                            update reserva_item_tbl
                            set qt_solicitada = qt_solicitada - 1
                            where nr_seq_reserva = nr_seq_reserva_w
                                and nr_seq_item = nr_seq_item_w;
                        
                            nr_seq_reserva_w := reserva_seq.nextval;
                            
                            insert into reserva_tbl(nr_registro_tbl, cd_cliente, cd_estabelecimento, dt_cirurgia, dt_registro, nm_login, 
                                dt_reserva, cd_pf_realizou, cd_medico_requisitante, cd_convenio, ie_status, nr_ficha_atend, nr_solicitacao,
                                cd_medico_cirurgiao, cd_setor_atendimento)
                            select
                                nr_seq_reserva_w, cd_cliente, cd_estabelecimento, dt_cirurgia, dt_registro, nm_login, 
                                dt_reserva, cd_pf_realizou, cd_medico_requisitante, cd_convenio, 'R', nr_ficha_atend, nr_solicitacao,
                                cd_medico_cirurgiao, cd_setor_atendimento
                            from reserva_tbl
                            where nr_registro_tbl = nr_seq_reserva_temp_w;

                            insert into reserva_item_tbl(nr_seq_reserva, nr_seq_item, nr_seq_derivado, qt_solicitada, dt_registro, nm_login)
                            select
                                nr_seq_reserva_w, nr_seq_item, nr_seq_derivado, 1, dt_registro, nm_login
                            from reserva_item_tbl
                            where nr_seq_reserva = nr_seq_reserva_temp_w;

                            exception
                            when others then
                                ds_stack_w := 'Tratamento para solicições de mais de 1 bolsa de sangue'||chr(13)||
                                       'error stack: '
                                    ||sys.dbms_utility.format_error_stack
                                    ||chr(13)
                                    ||'error backtrace: '
                                    ||sys.dbms_utility.format_error_backtrace
                                    ||chr(13)
                                    ||'call stack: '
                                    ||sys.dbms_utility.format_call_stack;
                                gravar_log_erro('I', :new.nr_registro_tbl, ds_stack_w);
                                    
                            return;
                            
                            end;
                        
                    end if;
                    
                --Atualização status da reserva hemocomponente
                    begin
                
                        nr_seq_reserva_prod_w := reserva_prod_seq.nextval;
                    
                        insert into reserva_prod_tbl(nr_registro_tbl, nr_seq_reserva, nr_seq_producao, ie_status, dt_registro, nm_login)
                        values(nr_seq_reserva_prod_w, nr_seq_reserva_w, nr_seq_hemo_w, 'R', sysdate, 'Integracao');
                        
                        update reserva_tbl
                        set dt_liberacao_solicitacao = sysdate,
                            ie_status = 'L'
                        where nr_registro_tbl = nr_seq_reserva_w;
                        
                        exception
                        when others then
                            ds_stack_w := 'Atualização status da reserva hemocomponente'||chr(13)||
                                   'error stack: '
                                ||sys.dbms_utility.format_error_stack
                                ||chr(13)
                                ||'error backtrace: '
                                ||sys.dbms_utility.format_error_backtrace
                                ||chr(13)
                                ||'call stack: '
                                ||sys.dbms_utility.format_call_stack;
                            gravar_log_erro('I', :new.nr_registro_tbl, ds_stack_w);
                                
                        return;
                    
                    end;

                gravar_log(:new.nr_registro_tbl, nr_seq_sup_w, nr_seq_hemo_w, nvl(nr_seq_reserva_temp_w, nr_seq_reserva_w), nr_seq_item_w, null, null, null, null, null, null, nr_seq_reserva_prod_w);

            else
            
                gravar_log_erro('P', :new.nr_registro_tbl, 'Solicitacao nao vinculada ao paciente.');

            end if;

        else
        
            gravar_log_erro('P', :new.nr_registro_tbl, 'Codigo de bolsa lancado manualmente ou Pedido de reserva do medico ja atendido.');
        
        end if;

    else
    
        gravar_log_erro('P', :new.nr_registro_tbl, 'Informacao do campo solicitacao e nula ou nao e numerica.');
    
    end if;

end;
/