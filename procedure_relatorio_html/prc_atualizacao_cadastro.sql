create or replace procedure prc_atualizacao_cadastro
is

w_ds_log varchar2(4000);
w_nr_processamento number := icesp.icesp_prj044_tbl002_seq.nextval;

procedure gravar_log (ds_body_email_p varchar2, cd_pessoa_p varchar2, nr_processamento_p number)

is

begin

    insert into tbl_log(nr_processamento, cd_pessoa, id_ident_atual, ds_observacao)
    values(nr_processamento_p, cd_pessoa_p, 'N', ds_body_email_p);

    commit;

end;

procedure identifica_atualiza_cadastro(nr_processamento_p number)

is

cursor c_casos is
select
    pac.nr_cliente||pac.nr_cliente_dv cd_cliente,
    pac.cd_pessoa
from pessoa pac
where pac.nr_prontuario is not null
    and pac.dt_obito is null
    --AGENDAMENTO FUTURO - VIDEO
    and exists (select 1
                from agenda_cliente ac
                    inner join ag_classif acf
                        on ac.ie_classif_agenda = acf.cd_classificacao
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
                    values(nr_processamento_p, w_c_casos.cd_pessoa, 'N', 'IDENTIFICAÇÃO não encontrado no Ensemble.');
                    
                    commit;
                    
                end;

            end if;
        
    end loop;
    close c_casos;
    
end;

/*--RELATÓRIO ATUALIZAÇÃO*/
procedure relatorio_atualizacao(nr_processamento_p number)

is

cursor c_casos is
select
    reg.nr_sequencia, reg.dt_atualizacao, reg.nr_processamento, reg.cd_pessoa, reg.id_ident, id_ident_atual, reg.ds_observacao,
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

begin

w_ds_body :=  
'<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Execução Rotina Atualização IDENTIFICAÇÃO</title>
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
        nr_processamento_p||' - EXECUÇÃO ROTINA ATUALIZAÇÃO IDENTIFICAÇÃO<br>
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
                
                    w_cliente_atua := w_c_casos.nm_cliente||' - Dta. nasc.: '||to_char(w_c_casos.dt_nascimento, 'dd/mm/yyyy')||' - COD CLIENTE: '||w_c_casos.nr_cliente||'<br>';
                    
                else
                
                    w_cliente_nao_atua := w_c_casos.nm_cliente||' - Dta. nasc.: '||to_char(w_c_casos.dt_nascimento, 'dd/mm/yyyy')||' - COD CLIENTE: '||w_c_casos.nr_cliente||'<br>';
                
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

    /*--IDENTIFICAR CLIENTES SEM IDENTIFICAÇÃO E ATUALIZA O CADASTRO--*/
    identifica_atualiza_cadastro(w_nr_processamento);

    /*--RELATÓRIO DA ATUALIZAÇÃO*/
    relatorio_atualizacao(w_nr_processamento);

end;
/
