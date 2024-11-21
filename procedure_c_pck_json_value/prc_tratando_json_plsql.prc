create or replace procedure prc_tratando_json_plsql(ds_telefone_p varchar2) as

cursor c01 is
select
    json_value(ds_json, '$.entry[0].changes[0].value.messages[0].text.body') ds_texto_msg,
    to_date('1970-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') + 
        (json_value(ds_json, '$.entry[0].changes[0].value.messages[0].timestamp') / 86400) dt_mensagem,
    json_value(ds_json, '$.entry[0].changes[0].value.contacts[0].wa_id') nr_telefone,
    id_message
from tbl_msg_log
where ds_json like '%55'||ds_telefone_p||'%'
    and substr(ds_json, 1, 10) = '{"object":';

w_c01 c01%rowtype;

w_ds_texto_msg varchar(200);
w_nr_telefone varchar(200);
w_dt_mensagem date;
w_nr_seq_retorno tbl_msg_log.nr_sequencia%type;

begin

    delete from tbl_relatorio;
    
    commit;

    open c01;
    loop
        fetch c01 into w_c01;
        exit when c01%notfound;
        
            begin
            
                insert into tbl_relatorio(nr_telefone, dt_msg, ds_mensagem)
                values(w_c01.nr_telefone, w_c01.dt_mensagem, substr(w_c01.ds_texto_msg,1,4000));

                select
                    max(nr_sequencia) nr_seq_retorno
                into
                    w_nr_seq_retorno
                from tbl_msg_log retorno
                where retorno.ie_envio_retorno = 'E'
                    and retorno.id_message = w_c01.id_message;

                if nvl(w_nr_seq_retorno, 0) <> 0 then
                
                    select
                        json_value(ds_json, '$.body.entry[0].changes[0].value.messages[0].button.payload') as ds_texto_msg,
                        json_value(ds_json, '$.body.entry[0].changes[0].value.contacts[0].wa_id') as nr_telefone,
                        to_date('1970-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') + 
                            (json_value(ds_json, '$.body.entry[0].changes[0].value.messages[0].timestamp') / 86400) as dt_mensagem
                    into
                        w_ds_texto_msg,
                        w_nr_telefone,
                        w_dt_mensagem
                    from tbl_msg_log retorno
                    where ie_envio_retorno = 'R'
                        and id_message = w_c01.id_message;

                    insert into tbl_relatorio(nr_telefone, dt_msg, ds_mensagem)
                    values(w_nr_telefone, w_dt_mensagem, w_ds_texto_msg);

                end if;
                
                commit;
            
            end;
            
    end loop;
    close c01;
    
end;


