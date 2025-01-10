create or replace trigger ALERTA_PREENCHIMENTO_AGENDA
before update on agenda_geral for each row

declare

cursor c01 is
select ds from 
(select 'BIOPSIA INCISIONAL DE LESAO SACRAL' ds from dual union all 
select 'BIOPSIA PRE-ESCALENICA' ds from dual union all 
select 'BIOPSIA RENAL' ds from dual union all 
select 'BIOPSIAS MULTIPLAS INTRA-ABDOMINAIS EM ONCOLOGIA' ds from dual);

w_c01 c01%rowtype;

w_sim varchar2(1) := 'N';
w_nao varchar2(1) := 'N';
w_msg varchar(4000) := 'Descrição não permitida, por favor, digite novamente uma das seguintes opções: '||chr(10);

begin

--validaçao somente agendas do tipo 'PROCEDIMENTO'
    if :new.ds_tipo_agenda = 'PROCEDIMENTO' then
    
    --não restringe se valor for nulo
        if nvl(:new.ds_curta_agenda, '0') <> '0' then
        
            open c01;
            loop
                fetch c01 into w_c01;
                exit when c01%notfound;
                
                --se valor for for igual a uma das opções variável W_SIM obtem 'S', se não variável W_NAO obtem valor 'S' 
                    if :new.ds_curta_agenda = w_c01.ds then
                    
                        w_sim := 'S';
                        
                    else
                    
                        w_nao := 'S';
                        
                    end if;

            end loop;
            close c01;
            
        --valida valor das variaveis
            if w_sim = 'N' and w_nao = 'S' then

            --edita mensagem com base nas opções
                open c01;
                loop
                    fetch c01 into w_c01;
                    exit when c01%notfound;
                    
                        w_msg := w_msg||w_c01.ds||chr(10);
                    
                end loop;
                close c01;

                raise_application_error(-20011, w_msg);

            end if;
            
        end if;
        
    end if;

end;
/