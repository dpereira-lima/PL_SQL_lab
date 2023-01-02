create or replace function function_validacao (
    nr_seq_agenda_p agendacons.nr_sequencia%type,
    cd_agenda_p number,
    ie_tipo_agenda_p number)
    
/*=============================================================
Sobre: FUNCTION para validação assiduidade do cliente com 
relação ao horário da sua consulta, procedimento ou exame.
Retornando S para confirmado ou N para não confirmado. 
--------------------------------------------------------------
Parâmetros: 
    NR_SEQ_AGENDA_P: sequência do registro
    CD_AGENDA_P: código da agenda
    IE_TIPO_AGENDA_P: tipo da agenda
==============================================================*/

    return varchar2
    
is

    ds_retorno_v varchar2(1);
    dt_agenda_v agendacons.dt_agenda%type;
    dt_max_hor_v date;
    hr_inicio_v agendapac.hr_inicio%type;

    nr_tempo_antes_v regra_tempo.nr_tempo_antes%type;
    nr_tempo_depois_v regra_tempo.nr_tempo_depois%type;
    ie_ignorar_v regra_tempo.ie_ignorar%type;

    quant_v number(10);
    difer_v number(10);
    
begin    

    --obter se há regra para agenda
    select count (1)
    into quant_v
    from regra_tempo
    where cd_agenda = cd_agenda_p;

    --verificar se há regra de tempo para agenda
    if quant_v > 0 then
   
        --obter valores da tabela de regras
        select nr_tempo_antes, nr_tempo_depois, ie_ignorar
        into nr_tempo_antes_v, nr_tempo_depois_v, ie_ignorar_v
        from regra_tempo
        where cd_agenda = cd_agenda_p;

        --consistencia agendas AMB ou GERAIS
        if (ie_tipo_agenda_p in (1, 3)) then
        
            --obter quantidade de minutos da data atual com agenda
            select obter_min_entre_data (sysdate, dt_agenda, 1), dt_agenda
            into difer_v, dt_agenda_v
            from agendacons a
            where nr_sequencia = nr_seq_agenda_p;

            if difer_v > 0 then
            
                if difer_v <= nr_tempo_antes_v then
                    ds_retorno_v := 'S';
                else
                    ds_retorno_v := 'N';
                end if;
                
            elsif difer_v < 0 then
                --verificar se o campo "ignora último horário da agenda" esta checado e se o agendamento está no último horário da agenda
                
                    --obter horário max da agenda no dia do angedamento
                    select max (dt_agenda)
                    into dt_max_hor_v
                    from agendacons a
                    where cd_agenda = cd_agenda_p
                        and trunc (dt_agenda) = trunc (dt_agenda_v);
                           
                    if (obter_min_entre_data (dt_agenda_v, dt_max_hor_v, 1) <= 60 and ie_ignorar_v = 'S') then
                    
                        ds_retorno_v := 'N';
                    
                    elsif (obter_min_entre_data (dt_agenda_v, dt_max_hor_v, 1) <= 60 and ie_ignorar_v = 'N') then
                        
                            if (difer_v * -1) <= nr_tempo_depois_v then
                                ds_retorno_v := 'S';
                            else
                                ds_retorno_v := 'N';
                            end if;
                            
                    elsif (obter_min_entre_data (dt_agenda_v, dt_max_hor_v, 1) > 60) then 
                    
                            if (difer_v * -1) <= nr_tempo_depois_v then
                                ds_retorno_v := 'S';
                            else
                                ds_retorno_v := 'N';
                            end if;
                            
                end if;
                
            else
            
                ds_retorno_v := 'S';
                
            end if;
            
        --consistencia agendas PROCEDIMENTO
        elsif (ie_tipo_agenda_p = 2) then
        
            --obter quantidade de minutos da data atual com agenda
            select obter_min_entre_data (sysdate, hr_inicio, 1), hr_inicio
            into difer_v, hr_inicio_v
            from agendapac
            where nr_sequencia = nr_seq_agenda_p;

            if difer_v > 0 then
            
                if difer_v <= nr_tempo_antes_v then
                    ds_retorno_v := 'S';
                else
                    ds_retorno_v := 'N';
                end if;
                
            elsif difer_v < 0 then
            
                --verificar se o campo "ignora último horário da agenda" esta checado e se o agendamento está no último horário da agenda
                
                --obter horário max da agenda no dia do angedamento
                    select max (hr_inicio)
                    into dt_max_hor_v
                    from agendapac a
                    where cd_agenda = cd_agenda_p
                        and trunc (hr_inicio) = trunc (hr_inicio_v);
                           
                    if (obter_min_entre_data (hr_inicio_v, dt_max_hor_v, 1) <= 60 and ie_ignorar_v = 'S') then
                    
                        ds_retorno_v := 'N';
                    
                    elsif (obter_min_entre_data (hr_inicio_v, dt_max_hor_v, 1) <= 60 and ie_ignorar_v = 'N') then
                        
                            if (difer_v * -1) <= nr_tempo_depois_v then
                                ds_retorno_v := 'S';
                            else
                                ds_retorno_v := 'N';
                            end if;
                            
                    elsif (obter_min_entre_data (hr_inicio_v, dt_max_hor_v, 1) > 60) then 
                    
                            if (difer_v * -1) <= nr_tempo_depois_v then
                                ds_retorno_v := 'S';
                            else
                                ds_retorno_v := 'N';
                            end if;

                end if;
                
            else
            
                ds_retorno_v := 'S';
                
            end if;
            
        --consistencia agenda TRATAMENTO
        elsif (ie_tipo_agenda_p = 4) then
        
            --obter quantidade de minutos da data atual com agenda
            select obter_min_entre_data (sysdate, dt_agenda, 1)
            into difer_v
            from agenda_quimio
            where nr_sequencia = nr_seq_agenda_p;

            --obter valores da tabela de regras
            select nvl(max(nr_tempo_antes),0), nvl(max(nr_tempo_depois),0)
            into nr_tempo_antes_v, nr_tempo_depois_v
            from regra_tempo
            where cd_agenda = cd_agenda_p;

            if difer_v > 0 then
            
                if difer_v <= nr_tempo_antes_v then
                    ds_retorno_v := 'S';
                else
                    ds_retorno_v := 'N';
                end if;
                
            elsif difer_v < 0 then
            
                if (difer_v * -1) <= nr_tempo_depois_v then
                    ds_retorno_v := 'S';
                else
                    ds_retorno_v := 'N';
                end if;
                
            else
            
                ds_retorno_v := 'S';
                
            end if;
            
        end if;

    else
    
        --consistencia agendas AMB ou GERAIS
        if (ie_tipo_agenda_p in (1, 3)) then
        
            select dt_agenda
            into dt_agenda_v
            from agendacons a
            where nr_sequencia = nr_seq_agenda_p;

            if sysdate <= dt_agenda_v then
                ds_retorno_v := 'S';
            else
                ds_retorno_v := 'N';
            end if;
            
        --consistencia agendas PROCEDIMENTOS
        elsif (ie_tipo_agenda_p = 2) then
        
            select hr_inicio
            into hr_inicio_v
            from agendapac
            where nr_sequencia = nr_seq_agenda_p;

            if sysdate <= hr_inicio_v then
                ds_retorno_v := 'S';
            else
                ds_retorno_v := 'N';
            end if;
            
        --consistencia agenda TRATAMENTO
        elsif (ie_tipo_agenda_p = 4) then
        
            ds_retorno_v := 'S';
            
        end if;
        
    end if;

    return ds_retorno_v;
    
end;
/
