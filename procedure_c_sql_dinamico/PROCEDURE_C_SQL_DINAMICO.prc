create or replace procedure PROCEDURE_C_SQL_DINAMICO (
    ds_body_email_p clob,
    nr_seq_projeto_p number)
as

/*************************************************************************
-----------------------PROCEDURE_C_SQL_DINAMICO---------------------------
Sobre: Este objeto tem por objetivo localizar o cadastro destinado ao envio 
de mensagem, do projeto informado por parâmetro e gravar na tabela temporaria 
o meio de envio (e-mail ou mensagem SMS).
Para o envio da mensagem também informada por parâmetro.
------------------------------------------------------
*Parametros: 
    DS_BODY_EMAIL_P: corpo da e-mail/mensagem
    NR_SEQ_PROJETO_P: código de cadastro do projeto
**************************************************************************/ 

cursor c01 is
select
    ds_email_destino, ds_titulo, ds_nome_remetente, nr_celular
from temp_regras_pp;

w_c01 c01%rowtype;

cursor c02 is
select column_value ds_email_destino 
from table (split(w_c01.ds_email_destino,';'));

w_c02 c02%rowtype;

nm_tabela_w varchar2(4000);
ds_email_w varchar2(80);
nr_celular_w varchar2(40);

begin

--Verificando se o projeto tem cadastro destinado a envio de mensagem 
----e por qual meio será encaminhado (EMAIL ou CELULAR) a mensagem

        select
            a.nm_tabela_regra,
            (select b.column_name
                        from all_tab_columns b
                        where upper(b.column_name) = 'DS_EMAIL'
                            and upper(a.nm_tabela_regra) = upper(b.table_name)) ds_email,
            (select b.column_name
                        from all_tab_columns b
                        where upper(b.column_name) = 'NR_CELULAR'
                            and upper(a.nm_tabela_regra) = upper(b.table_name)) nr_celular
        into
            nm_tabela_w,
            ds_email_w,
            nr_celular_w
        from projeto_regras a
        where a.nr_seq_projetos = nr_seq_projeto_p;

--limpando a tabela temporaria e populando novamente com os dados encontrados do projeto
    if nm_tabela_w is not null then
    
        execute immediate 'delete from temp_regras_pp';

        if ds_email_w is not null and nr_celular_w is not null then

            execute immediate 'insert into temp_regras_pp (ds_email_destino, ds_titulo, ds_nome_remetente, nr_celular)
                                select ds_email, ds_titulo, ds_nome_remetente, nr_celular from '||nm_tabela_w;
                                
        elsif ds_email_w is null and nr_celular_w is not null then
        
            execute immediate 'insert into temp_regras_pp (ds_titulo, ds_nome_remetente, nr_celular)
                                select ds_titulo, ds_nome_remetente, nr_celular from '||nm_tabela_w;
                                
        elsif ds_email_w is not null and nr_celular_w is null then
        
            execute immediate 'insert into temp_regras_pp (ds_email_destino, ds_titulo, ds_nome_remetente)
                                select ds_email, ds_titulo, ds_nome_remetente from '||nm_tabela_w;
                                
        end if;

            open c01;
            loop
                fetch c01 into w_c01;
                exit when c01%notfound;
                
				--Envio por e-mail, SMS e WhatsApp
                    if (w_c01.nr_celular is not null and w_c01.ds_email_destino is not null) then
                    
                        OPEN C02;
                        LOOP
                            FETCH C02 INTO w_c02;
                            EXIT WHEN C02%NOTFOUND;

								insert into email_mensagem (nr_sequencia, dt_registro, ds_titulo, ds_nome_remetente, 
									ds_email_destino, ds_body_email, dt_agendamento, nr_atendimento, cd_pessoa_fisica)
								values (email_mensagem_seq.nextval, sysdate, w_c01.ds_titulo, w_c01.ds_nome_remetente,
									w_c01.ds_email_destino, ds_body_email_p, sysdate, nr_atendimento_p, cd_pessoa_fisica_p);
                            
                        END LOOP;
                        CLOSE C02;

						insert into sms_mensagem (nr_sequencia,dt_registro, nr_telefone, ds_mensagem,dt_agendamento, cd_pessoa_fisica, nr_seq_envio, cd_tipo_agenda, nr_seq_agenda) 
						values (sms_mensagem_seq.nextval, sysdate, w_c01.nr_celular, ds_body_email_p, sysdate, cd_pessoa_fisica_p, 1,3, null);
                    
						insert into whatsapp_mensagem(nr_sequencia, nr_seq_processo, ds_mensagem, nr_telefone, dt_registro, ds_processo, nr_seq_whatsapp_templ, id_message)
						values (whatsapp_mensagem_seq.nextval, 1, ds_body_email_p, w_c01.nr_celular, sysdate, null, null, null);
            
                --Envio por e-mail 
                    elsif (w_c01.nr_celular is null and w_c01.ds_email_destino is not null) then
                    
                        OPEN C02;
                        LOOP
                            FETCH C02 INTO w_c02;
                            EXIT WHEN C02%NOTFOUND;
                    
								insert into email_mensagem (nr_sequencia, dt_registro, ds_titulo, ds_nome_remetente, 
									ds_email_destino, ds_body_email, dt_agendamento, nr_atendimento, cd_pessoa_fisica)
								values (email_mensagem_seq.nextval, sysdate, w_c01.ds_titulo, w_c01.ds_nome_remetente,
									w_c01.ds_email_destino, ds_body_email_p, sysdate, nr_atendimento_p, cd_pessoa_fisica_p);
                            
                        END LOOP;
                        CLOSE C02;

				--Envio por SMS e WhatsApp
                    elsif (w_c01.nr_celular is not null and w_c01.ds_email_destino is null) then
                    
						insert into sms_mensagem (nr_sequencia,dt_registro, nr_telefone, ds_mensagem,dt_agendamento, cd_pessoa_fisica, nr_seq_envio, cd_tipo_agenda, nr_seq_agenda) 
						values (sms_agendamento_seq.nextval, sysdate, w_c01.nr_celular, ds_body_email_p, sysdate, cd_pessoa_fisica_p, 1,3, null); 
                
						insert into whatsapp_mensagem(nr_sequencia, nr_seq_processo, ds_mensagem, nr_telefone, dt_registro, ds_processo, nr_seq_whatsapp_templ, id_message)
						values (whatsapp_mensagem_seq.nextval, 1, ds_body_email_p, w_c01.nr_celular, sysdate, null, null, null);

                    end if;
                
            end loop;
            close c01;
            
        end if;

    end if;
    
end;
