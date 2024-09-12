create or replace procedure prc_atualizacao_cadastro
is

w_ds_log varchar2(4000);
w_nr_processamento number := nr_processamento_seq.nextval;

procedure gravar_log (ds_body_email_p varchar2, cd_pessoa_p varchar2, nr_processamento_p number)

is

begin

    insert into tbl_log(nr_processamento, cd_pessoa, id_ident_atual, ds_observacao, ie_atualizacao_sistema)
    values(nr_processamento_p, cd_pessoa_p, 'N', ds_body_email_p, 'E');

    commit;

end;

procedure identifica_atualiza_cadastro(nr_processamento_p number)

is

cursor c_casos is
select
    nvl(pac.nr_cliente||pac.nr_cliente_dv,'0') cd_cliente,
    pac.cd_pessoa
from pessoa pac
where pac.nr_prontuario is not null
    and pac.dt_obito is null
    --AGENDAMENTO FUTURO
    and exists (select 1
                from agenda_cliente ac
                where pac.cd_pessoa = ac.cd_pessoa
                    and ac.ie_status_agenda = 'N'
                    and ac.dt_agenda >= sysdate) 
    and (pac.identificador_dw is null or pac.identificador_dw = 0);

w_c_casos c_casos%rowtype;
w_id_ident pessoa.identificador_dw%type;

begin

    open c_casos;
    loop
        fetch c_casos into w_c_casos;
        exit when c_casos%notfound;

            if (w_c01.cd_cliente <> '0') then
        
            w_id_ident := get_identificacao(w_c_casos.cd_cliente, null, null, null);
            
            if nvl(w_id_ident, 0) <> 0 then
            
                begin
            
                    update pessoa 
                    set identificador_dw = w_id_ident
                    where cd_pessoa = w_c_casos.cd_pessoa;
                    
                    insert into tbl_log(nr_processamento, cd_pessoa, id_ident, id_ident_atual)
                    values(nr_processamento_p, w_c_casos.cd_pessoa, w_id_ident, 'S');
                    
                    commit;
                    
                    exception
                        when others then
                            w_ds_log :=
                                   'error stack: '
                                || sys.dbms_utility.format_error_stack
                                || chr(13)
                                || 'error backtrace: '
                                || sys.dbms_utility.format_error_backtrace
                                || chr(13)
                                || 'call stack: '
                                || sys.dbms_utility.format_call_stack;
                            gravar_log(w_ds_log,
                                    w_c_casos.cd_pessoa,
                                    nr_processamento_p);
                                                    
                end;
            
            else
            
                begin
                
                    insert into tbl_log(nr_processamento, cd_pessoa, id_ident_atual, ds_observacao)
                    values(nr_processamento_p, w_c_casos.cd_pessoa, 'N', 'IDENTIFICACAO nao encontrada na base.');
                    
                    commit;
                    
                end;

            end if;

            else
            
                begin
                
                    insert into tbl_log(nr_processamento, cd_pessoa, id_ident_atual, ds_observacao)
                    values(nr_processamento_p, w_c01.cd_pessoa, 'N', 'Paciente sem COD_IDENT no sistema');
                    
                    commit;
                    
                end;
                
            end if;

    end loop;
    close c_casos;
    
end;

/*--RELATORIO ATUALIZACAO*/
procedure relatorio_atualizacao(nr_processamento_p number)

is

cursor c_casos is
select
    reg.nr_sequencia, reg.dt_atualizacao, reg.nr_processamento, reg.cd_pessoa, reg.id_ident, id_ident_atual, reg.ds_observacao, reg.ie_atualizacao_sistema,
    pf.nm_pessoa nm_cliente, pf.dt_nascimento, pf.nr_prontuario||pf.nr_pront_dv nr_cliente
from tbl_log reg
    inner join pessoa pf
        on reg.cd_pessoa = pf.cd_pessoa
where nr_processamento = nr_processamento_p;

w_c_casos c_casos%rowtype;

w_ds_body clob :=  null;
w_dt_atualizacao tbl_log.dt_atualizacao%type;
w_cliente_atua varchar2(32767) :=  null;
w_cliente_nao_atua varchar2(32767) :=  null;
w_ds_observacao icesp.icesp_prj044_tbl001.ds_observacao%type;

begin

w_ds_body :=  
'<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Execução Rotina Atualização IDENTIFICACAO</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            line-height: 1.6;
        }
        .section {
            border-top: 2px solid #000;
            padding-top: 10px;
            margin-top: 10px;
        }
        .header, .footer {
            text-align: center;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="header">
        <hr>'||
        nr_processamento_p||' - EXECUÇÃO ROTINA ATUALIZACAO IDENTIFICACAO<br>
        Data: '||to_char(trunc(sysdate), 'dd/mm/yyyy')||'<br>
        <hr>
    </div>

    <div>';
    
    open c_casos;
    loop
        fetch c_casos into w_c_casos;
        exit when c_casos%notfound;
        
            begin
            
                if w_c_casos.id_ident_atual = 'S' then
                
                    w_cliente_atua := w_c_casos.nm_cliente||' - Dta. nasc.: '||to_char(w_c_casos.dt_nascimento, 'dd/mm/yyyy')||' - COD CLIENTE: '||w_c_casos.nr_cliente||'<br>'
                                    ||w_cliente_atua;
                    
                else

                    if w_c01.ie_atualizacao_sistema = 'E' then
                    
                        w_ds_observacao := 'Erro Oracle - TI observar logs.';
                    
                    else
                    
                        w_ds_observacao := w_c01.ds_observacao;
                    
                    end if;
                
                    w_cliente_nao_atua := w_c_casos.nm_cliente||' - Dta. nasc.: '||to_char(w_c_casos.dt_nascimento, 'dd/mm/yyyy')||' - COD CLIENTE: '||w_c_casos.nr_cliente||'<br>'
                                            'Motivo: <i>'||w_ds_observacao||'</i><br>'||                
                                            ||w_cliente_nao_atua;
                
                end if;

            end;
        
    end loop;
    close c_casos;
    
    if nvl(w_cliente_atua, '0') <> '0' then
    
        w_ds_body := w_ds_body||'<div><p><b>Pacientes atualizados:</b></p><p>'||w_cliente_atua||'</p></div>';
        
    end if;
    
    if nvl(w_cliente_nao_atua, '0') <> '0' then
    
        w_ds_body := w_ds_body||'<div><p><b>Pacientes não atualizados:</b></p><p>'||w_cliente_nao_atua||'</p></div>';
        
    end if;
    
    if (nvl(w_cliente_atua, '0') = '0' and nvl(w_cliente_nao_atua, '0') = '0') then
    
        w_ds_body := w_ds_body||'<div><p><b>Sem atualizações</b></p></div>';
        
    end if;
    
    w_ds_body := w_ds_body||'<div class="footer"><hr></div></body></html>';

    /*--ENVIO DE E-MAIL--*/
    prc_envio_email(w_ds_body, 99);

    commit;

end;

begin

    /*--IDENTIFICAR CLIENTES SEM IDENTIFICACAO E ATUALIZA O CADASTRO--*/
    identifica_atualiza_cadastro(w_nr_processamento);

    /*--RELATÓRIO DA ATUALIZACAO*/
    relatorio_atualizacao(w_nr_processamento);

end;
/
