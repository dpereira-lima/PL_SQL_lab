create or replace trigger TRG_COM_TRATAMENTO_EXCECOES
after insert on registro_reserva_tb
for each row

declare
nr_seq_sup_w emprestimo.nr_sequencia%type;
nr_seq_hemo_w emprestimo.nr_sequencia%type;
nr_seq_derivado_w derivado.nr_sequencia%type;
qt_dias_validade_w derivado.qt_dias_validade%type;
nr_seq_reserva_w reserva.nr_sequencia%type;
nr_seq_reserva_temp_w reserva.nr_sequencia%type;
nr_seq_reserva_prod_w reserva_prod.nr_sequencia%type;
nr_seq_transfusao_w transfusao.nr_sequencia%type;
nr_atendimento_w prescr_medica.nr_atendimento%type;
cd_pessoa_w prescr_medica.cd_pessoa%type;
cd_prescritor_w prescr_medica.cd_prescritor%type;
ie_tipo_w prescr_solic_bco_sangue.ie_tipo%type;
qt_procedimento_w hemoterapia.qt_procedimento%type;
ie_status_reserv_w reserva.ie_status%type;
qt_solicitada_w reserva_item.qt_solicitada%type;
nr_seq_item_w reserva_item.nr_seq_item%type;
nr_prontuario_w varchar2(400);
ie_consit_nm_componente_w varchar2(1);

--variavel log exception
ds_erro_w varchar2(4000);

procedure gravar_log (ie_tipo_p varchar2,
    nr_seq_registro_p number, 
    ds_erro_p varchar2)

is

begin

    --gravando o log na tabela
    insert into registro_log_erro_tb
    (
    ie_tipo,
    nr_seq_registro,
    ds_stack
    )
    values 
    (
    ie_tipo_p,
    nr_seq_registro_p,
    ds_erro_p
    );

end;

begin

--Verificando se o número da prescrição não é nulo
    if (nvl(:new.nr_prescricao, 0) <> 0) then

        begin

        --obtendo dados do pedido médico (prescrição)    
            select
                pm.nr_atendimento,
                pm.cd_pessoa,
                pm.cd_prescritor,
                psbs.ie_tipo,
                ch.qt_procedimento,
                pf.nr_prontuario
            into
                nr_atendimento_w,
                cd_pessoa_w,
                cd_prescritor_w,
                ie_tipo_w,
                qt_procedimento_w,
                nr_prontuario_w
            from prescr_medica pm
                inner join paciente pa
                    on pm.cd_pessoa = pa.cd_pessoa
                inner join (select max(nr_sequencia) nr_sequencia, nr_prescricao
                            from prescr_solic_bco
                            group by nr_prescricao) base
                    on pm.nr_prescricao = base.nr_prescricao
                inner join prescr_solic_bco psbs
                    on base.nr_sequencia = psbs.nr_sequencia
                inner join hemoterapia ch
                    on psbs.nr_seq_hemo_cpoe = ch.nr_sequencia
            where pm.nr_prescricao = :new.nr_prescricao;

            exception
            when others then
                ds_erro_w :=
                       'error stack: '
                    ||sys.dbms_utility.format_error_stack
                    ||chr(13)
                    ||'error backtrace: '
                    ||sys.dbms_utility.format_error_backtrace
                    ||chr(13)
                    ||'call stack: '
                    ||sys.dbms_utility.format_call_stack;
                gravar_log('I', :new.NR_SEQUENCIA, ds_erro_w);
                        
            return;

        end;

        begin

        --obtendo dados do registro da reserva gerado através do pedido médico
            select
                sr.nr_sequencia,
                sr.ie_status,
                sri.qt_solicitada,
                sri.nr_seq_item
            into
                nr_seq_reserva_w,
                ie_status_reserv_w,
                qt_solicitada_w,
                nr_seq_item_w
            from (select min(nr_sequencia) nr_sequencia, nr_prescricao
                    from reserva
                    where nr_prescricao = :new.nr_prescricao
                    group by nr_prescricao) base1
                inner join reserva sr
                    on base1.nr_sequencia = sr.nr_sequencia
                inner join reserva_item sri
                    on sr.nr_sequencia = sri.nr_seq_reserva;

            exception
            when others then
                ds_erro_w :=
                       'error stack: '
                    ||sys.dbms_utility.format_error_stack
                    ||chr(13)
                    ||'error backtrace: '
                    ||sys.dbms_utility.format_error_backtrace
                    ||chr(13)
                    ||'call stack: '
                    ||sys.dbms_utility.format_call_stack;
                gravar_log('I', :new.NR_SEQUENCIA, ds_erro_w);
                        
            return;

        end;

    --verificando se a prescrição esta vinculada ao paciente
        if (nr_prontuario_w = REGEXP_REPLACE(:new.NR_REGISTRO_PACIENTE, '[^[:digit:]]', '')) then

        --verificando se o registro de reserva primário (gerado pelo sistema) está com status diferente de Liberado
            if (ie_status_reserv_w <> 'L') then

            --criação registro cabeçalho hemocomponente
                nr_seq_sup_w := san_emprestimo_seq.nextval;

                begin

                    insert into emprestimo(nr_sequencia, nr_seq_entidade, dt_alteracao, nm_acesso, ie_entrada_saida, dt_emprestimo, cd_pf_realizou, cd_empresa)
                    values (nr_seq_sup_w, 11, sysdate, 'USUARIO', 'E', sysdate, '1769656'/*a verificar*/, 1);

                    exception
                    when others then
                        ds_erro_w :=
                               'error stack: '
                            ||sys.dbms_utility.format_error_stack
                            ||chr(13)
                            ||'error backtrace: '
                            ||sys.dbms_utility.format_error_backtrace
                            ||chr(13)
                            ||'call stack: '
                            ||sys.dbms_utility.format_call_stack;
                        gravar_log('I', :new.NR_SEQUENCIA, ds_erro_w);
                                
                    return;

                end;

            --criação registro hemocomponente    
                nr_seq_hemo_w := san_producao_seq.nextval;
                
                select
                    nr_sequencia,
                    qt_dias_validade,
                    obter_consistencia_nm_comp_func(DS_DERIVADO) ie_consit_nm_componente
                into
                    nr_seq_derivado_w,
                    qt_dias_validade_w,
                    ie_consit_nm_componente_W
                from derivado
                where sg_sigla = substr(upper(:new.CD_PRODUTO),1,instr(upper(:new.CD_PRODUTO), 'V') -1)
                    and ie_situacao = 'A';
                
                begin

                    insert into producao(nr_sequencia, nr_seq_derivado, dt_producao, cd_pf_realizou, dt_alteracao, nm_acesso, dt_vencimento, nr_sangue, nr_seq_emp_ent, 
                         ie_irradiado, ie_lavado, ie_aliquotado, cd_barras, ie_aferese, ie_pai_reproduzido, ie_reproduzido, ie_realiza_nat, 
                        cd_empresa, ie_pool, ie_tipo_bloqueio, ie_em_reproducao, qt_unidade, ie_filtrado, dt_liberacao, nm_acesso_lib)
                    values(nr_seq_hemo_w, nr_seq_derivado_w , sysdate, '1769656', sysdate, 'USUARIO', trunc(sysdate) + qt_dias_validade_w, :new.cd_bolsa, nr_seq_sup_w, 
                        'N', 'N', 'N', :new.cd_bolsa, 'N', 'N', 'N', 'N', 1, 'N', 'N', 'N', 1, 'N', sysdate, 'USUARIO');

                    update emprestimo
                    set dt_fechamento = sysdate
                    where nr_sequencia = nr_seq_sup_w;
                
                    exception
                    when others then
                        ds_erro_w :=
                               'error stack: '
                            ||sys.dbms_utility.format_error_stack
                            ||chr(13)
                            ||'error backtrace: '
                            ||sys.dbms_utility.format_error_backtrace
                            ||chr(13)
                            ||'call stack: '
                            ||sys.dbms_utility.format_call_stack;
                        gravar_log('I', :new.NR_SEQUENCIA, ds_erro_w);
                                
                    return;
                
                end;
                
                if (ie_consit_nm_componente_W = 'S') then
                    
                --gerando registro de reserva de bolsa de sangue                
                    nr_seq_reserva_temp_w := nr_seq_reserva_w;
                    
                --tratamento para solicições de mais de 1 bolsa de sangue
                    if (qt_solicitada_w > 1) then
                    
                        begin
                    
                            update reserva_item
                            set qt_solicitada = qt_solicitada - 1
                            where nr_seq_reserva = nr_seq_reserva_temp_w
                                and nr_seq_item = nr_seq_item_w;
                        
                            nr_seq_reserva_w := reserva_seq.nextval;
                            
                            insert into reserva(nr_sequencia, cd_pessoa, cd_empresa, dt_cirurgia, dt_alteracao, nm_acesso, 
                                dt_reserva, cd_pf_realizou, cd_medico_requisitante, cd_convenio, ie_status, nr_atendimento, nr_prescricao,
                                cd_medico_cirurgiao, cd_setor_atendimento)
                            select
                                nr_seq_reserva_w, cd_pessoa, cd_empresa, dt_cirurgia, dt_alteracao, nm_acesso, 
                                dt_reserva, cd_pf_realizou, cd_medico_requisitante, cd_convenio, 'R', nr_atendimento, nr_prescricao,
                                cd_medico_cirurgiao, cd_setor_atendimento
                            from reserva
                            where nr_sequencia = nr_seq_reserva_temp_w;

                            insert into reserva_item(nr_seq_reserva, nr_seq_item, nr_seq_derivado, qt_solicitada, dt_alteracao, nm_acesso)
                            select
                                nr_seq_reserva_w, nr_seq_item, nr_seq_derivado, 1, dt_alteracao, nm_acesso
                            from reserva_item
                            where nr_seq_reserva = nr_seq_reserva_temp_w;
                            
                            exception
                            when others then
                                ds_erro_w :=
                                       'error stack: '
                                    ||sys.dbms_utility.format_error_stack
                                    ||chr(13)
                                    ||'error backtrace: '
                                    ||sys.dbms_utility.format_error_backtrace
                                    ||chr(13)
                                    ||'call stack: '
                                    ||sys.dbms_utility.format_call_stack;
                                gravar_log('I', :new.NR_SEQUENCIA, ds_erro_w);
                                    
                        return;
                        
                        end;
                        
                    end if;
                    
                end if;
                
                begin
            
                    nr_seq_reserva_prod_w := reserva_prod_seq.nextval;
                
                    insert into reserva_prod(nr_sequencia, nr_seq_reserva, nr_seq_producao, ie_status, dt_alteracao, nm_acesso)
                    values(nr_seq_reserva_prod_w, nr_seq_reserva_w, nr_seq_hemo_w, 'R', sysdate, 'USUARIO');
                    
                    update reserva
                    set dt_liberacao_solicitacao = sysdate,
                        ie_status = 'L'
                    where nr_sequencia = nr_seq_reserva_w;
                    
                    exception
                    when others then
                        ds_erro_w :=
                               'error stack: '
                            ||sys.dbms_utility.format_error_stack
                            ||chr(13)
                            ||'error backtrace: '
                            ||sys.dbms_utility.format_error_backtrace
                            ||chr(13)
                            ||'call stack: '
                            ||sys.dbms_utility.format_call_stack;
                        gravar_log('I', :new.NR_SEQUENCIA, ds_erro_w);
                            
                    return;
                
                end;

            else

                gravar_log('P', :new.NR_SEQUENCIA, 'Reserva já liberada.');

            end if;

        else
        
            gravar_log('P', :new.NR_SEQUENCIA, 'Pedido não vinculado ao paciente.');

        end if;

    else
    
        gravar_log('P', :new.NR_SEQUENCIA, 'Número do pedido nulo.');
    
    end if;

end;
/