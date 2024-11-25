create or replace procedure prc_tratando_json_plsql(ds_telefone_p varchar2) as

cursor c01 is
select
    --obtem info da mensagem, se msg for enviada para o cliente (E) retorna o texto padrão
    case
        when ie_envio_retorno = 'R' and nr_seq_whatsapp is null then 
                nvl(json_value(ds_json, '$.entry[0].changes[0].value.messages[0].text.body'),
                    json_value(ds_json, '$.body.entry[0].changes[0].value.messages[0].button.payload')) 
        when ie_envio_retorno = 'E' and nr_seq_whatsapp is not null then
            'Confirmação do atendimento' 
        else 
            'Resposta automática'
        end ds_mensagem,
    --obtem data e hora da msg
    nvl(to_date('1970-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') + 
        (json_value(ds_json, '$.entry[0].changes[0].value.messages[0].timestamp') / 86400), dt_registro) dt_msg,
    --obter número de tel, se for mensagem enviada palo o cliente (E) retornar número de tel padrão
    case
        when ie_envio_retorno = 'E' then '551112341234'
        else nvl(json_value(ds_json, '$.entry[0].changes[0].value.contacts[0].wa_id'),
                json_value(ds_json, '$.body.entry[0].changes[0].value.contacts[0].wa_id'))
    end nr_telefone
from tbl_whatsapp_log a
where ds_json like '%'||ds_telefone_p||'%'
order by dt_registro;

w_c01 c01%rowtype;

begin

    --limpa tabela temporaria
    delete from tbl_historico_whatsapp;
    
    commit;

    --inserir novos registros na tabela temporaria de acordo com informações
    ----retornadas do select do cursor.
    open c01;
    loop
        fetch c01 into w_c01;
        exit when c01%notfound;
        
            insert into tbl_historico_whatsapp(nr_telefone, dt_msg, ds_mensagem)
            values(w_c01.nr_telefone, w_c01.dt_msg, w_c01.ds_mensagem);
            
            commit;
        
    end loop;
    close c01;
    
end;
