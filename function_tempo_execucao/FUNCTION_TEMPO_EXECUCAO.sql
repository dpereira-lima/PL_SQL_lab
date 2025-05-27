create or replace function function_tempo_execucao(nr_seq_agend_p number, cd_tp_agenda_p number)

return varchar is

w_ds_retorno varchar2(4000);

w_nr_seq_grupo_classif classif_agenda.nr_seq_grupo_classif%type;
w_cd_agenda cadastro_agenda.cd_agenda%type;
w_ds_consulta_distancia varchar2(4000) := 'Atendimento a distância, fique atento no período agendado.';
w_ds_comparecer varchar2(4000) := 'Comparecer no estabelcimento, ';
w_ds_consulta_presencial varchar2(4000) := 'É necessário chegar com antecedência de ';
w_nr_seq_quimio ag_tratamento.nr_sequencia%type;

function obter_tempo_atenc(cd_agenda_p number)

return varchar is

w_ds_agrupamento ag_assistencia.ds_agrupamento%type;

begin

    --Tempo de atencedência
    select
        max(ds_agrupamento) ds_agrupamento
    into
        w_ds_agrupamento
    from (select
            case 
                --agenda cirurgica
                when a.CD_TIPO_AGENDA = 1 then
                    case 
                        when cac.nr_sequencia = 4 then '10 minutos'
                        else lower(cac.ds_classificacao)
                    end
                --agenda Assistencia, Exame e Prestação Serviço
                else
                    case
                        when aa.nr_sequencia = 1 then '10 minutos'
                        else lower(aa.ds_agrupamento)
                    end 
            end ds_agrupamento
        from cadastro_agenda a
            left join ag_assistencia aa
                on a.nr_seq_agrupamento = aa.nr_sequencia
            left join agenda_cirurgica_classif cac
                on a.NR_SEQ_CLASSIF = cac.NR_SEQUENCIA
        where a.cd_agenda = cd_agenda_p);

    return w_ds_agrupamento;

end;

function obter_endereco(cd_agenda_p number, nr_seq_agendamento_p number)

return varchar2 is

w_ds_retorno varchar(4000);
w_ds_setor_atendimento setor_estabelecimento.ds_setor_atendimento%type;

begin

    --cadastro_agenda de quimioterapia
    if cd_agenda_p = 1 then

        select
            ql.ds_local
        into
            w_ds_setor_atendimento
        from ag_tratamento aq
            inner join sala_tratamento ql
                on aq.nr_seq_local = ql.nr_sequencia
        where aq.nr_sequencia = nr_seq_agendamento_p;
    
    --Demais agendas
    else
    
        select
            setor_excl.ds_setor_atendimento
        into
            w_ds_setor_atendimento
        from cadastro_agenda a
            left join setor_estabelecimento setor_excl
                on a.cd_setor_exclusivo = setor_excl.cd_setor_atendimento
        where cd_agenda = cd_agenda_p;
        
    end if;
    
    if upper(w_ds_setor_atendimento) like '%ORLANDO%' then
    
        w_ds_retorno := 'International Drive. ';
        
    elsif upper(w_ds_setor_atendimento) like '%TEXAS%' then
    
        w_ds_retorno := 'Sixth Street. ';
    
    elsif upper(w_ds_setor_atendimento) like '%NEW YORK%' then
    
        w_ds_retorno := 'Quita Avenida. ';
        
    else
    
        w_ds_retorno := 'Michigan Avenue. ';
        
    end if;
    
    return w_ds_retorno;

end;

begin

    --Agendas de Assistência e Prestação de Serviço
    if cd_tipo_agenda_p in (3, 5) then 

        select
            max(acf.nr_seq_grupo_classif),
            max(a.cd_agenda)
        into 
            w_nr_seq_grupo_classif,
            w_cd_agenda
        from cadastro_agenda a
            inner join ag_assistencia ac
                on a.cd_agenda = ac.cd_agenda
            left join classif_agenda acf
                on ac.ie_classif_agenda = acf.cd_classificacao
        where ac.nr_sequencia = nr_seq_agendamento_p;
        
        if nvl(w_nr_seq_grupo_classif, 0) in (2,3) then
        
            w_ds_retorno := w_ds_consulta_distancia;
            
        else
                
            w_ds_retorno := w_ds_comparecer||obter_endereco(w_cd_agenda, null)||w_ds_consulta_presencial||obter_tempo_atenc(w_cd_agenda)||'.';

        end if;
    
    --cadastro_agenda Cirurgica e Exame
    elsif cd_tipo_agenda_p in (1, 2) then 

        select
            max(a.cd_agenda)
        into 
            w_cd_agenda
        from cadastro_agenda a
            inner join ag_cliente ap
                on a.cd_agenda = ap.cd_agenda
        where ap.nr_sequencia = nr_seq_agendamento_p;

        w_ds_retorno := w_ds_comparecer||obter_endereco(w_cd_agenda, null)||w_ds_consulta_presencial||obter_tempo_atenc(w_cd_agenda)||'.';

    --cadastro_agenda de Tratamento
    elsif cd_tipo_agenda_p = (6) then
    
        select
            nr_sequencia
        into
            w_nr_seq_quimio
        from ag_tratamento
        where nr_sequencia = nr_seq_agendamento_p;

        w_ds_retorno := w_ds_comparecer||obter_endereco(1, w_nr_seq_quimio)||w_ds_consulta_presencial||'1 hora.';

    end if;

    return w_ds_retorno;
    
end;
/
