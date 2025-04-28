create or replace package body tasy.pkg_return_pipelined as

function agendamentos 

return tp_agendamento_qt pipelined

is

v_out type_agendamento_qt_itaci;

cursor c01 is
select 
    ql.nr_sequencia nr_seq_local,
    ql.ds_local,
    trunc(aq.dt_agenda) dt_agenda,
    case
        when aq.ie_status_agenda = 'F' then obter_descricao_status(1234, 'F')
        when aq.ie_status_agenda <> 'F' and aq.nr_atendimento is null and trunc(aq.dt_agenda) < trunc(sysdate) then obter_descricao_status(1234, 'F')
        when aq.ie_status_agenda = 'E' then obter_descricao_status(1234, 'E')
        when aq.ie_status_agenda <> 'E' and aq.nr_atendimento is not null and trunc(aq.dt_agenda) < trunc(sysdate) then obter_descricao_status(1234, 'E')
        else obter_descricao_status(1234, aq.ie_status_agenda) 
    end ds_status_agendamento,
    sum(aq.nr_minuto_duracao) nr_minuto_duracao
from agenda_qt aq
    inner join agenda_qt_local ql
        on aq.nr_seq_local = ql.nr_sequencia
    inner join (select max(nr_sequencia) nr_sequencia, nr_seq_local
                from agenda_qt_local_turno
                where nvl(dt_vigencia_final, sysdate + 1/24/60) > sysdate
                    and hr_inicial is not null
                group by nr_seq_local) base
        on ql.nr_sequencia = base.nr_seq_local
    inner join agenda_qt_local_turno qlt
        on base.nr_sequencia = qlt.nr_sequencia
    inner join cliente pf
        on aq.cd_pessoa_fisica = pf.cd_pessoa_fisica
where trunc(aq.dt_agenda) between '01/02/2024' and trunc(sysdate)
    and aq.ie_status_agenda not in ('C', 'S')
    and upper(ql.ds_local) like '%QT ITACI%'
group by ql.nr_sequencia,
    ql.ds_local,
    trunc(aq.dt_agenda),
    case
        when aq.ie_status_agenda = 'F' then obter_descricao_status(1234, 'F')
        when aq.ie_status_agenda <> 'F' and aq.nr_atendimento is null and trunc(aq.dt_agenda) < trunc(sysdate) then obter_descricao_status(1234, 'F')
        when aq.ie_status_agenda = 'E' then obter_descricao_status(1234, 'E')
        when aq.ie_status_agenda <> 'E' and aq.nr_atendimento is not null and trunc(aq.dt_agenda) < trunc(sysdate) then obter_descricao_status(1234, 'E')
        else obter_descricao_status(1234, aq.ie_status_agenda) 
    end
order by nr_seq_local, dt_agenda, ds_status_agendamento;

w_c01 c01%rowtype;

cursor c02 is
select
    nr_seq_local, ds_local, dt_agenda, hr_inicial, hr_final, sum(nr_tempo_total_min) nr_tempo_total_min
from(
select
    ql.nr_sequencia nr_seq_local, ql.ds_local, trunc(aq.dt_agenda) dt_agenda, qlt.hr_inicial, qlt.hr_final, aq.nr_minuto_duracao nr_tempo_total_min
from agenda_qt aq
    inner join agenda_qt_local ql
        on aq.nr_seq_local = ql.nr_sequencia
    inner join (select max(nr_sequencia) nr_sequencia, nr_seq_local
                from agenda_qt_local_turno
                where nvl(dt_vigencia_final, sysdate + 1/24/60) > sysdate
                    and hr_inicial is not null
                group by nr_seq_local) base
        on ql.nr_sequencia = base.nr_seq_local
    inner join agenda_qt_local_turno qlt
        on base.nr_sequencia = qlt.nr_sequencia
)
group by nr_seq_local, ds_local, dt_agenda, hr_inicial, hr_final
order by dt_agenda;

w_c02 c02%rowtype;

w_total_horario_turno number;
w_tempo_restante number;

w_tbl_base tp_agendamento_qt_itaci := tp_agendamento_qt_itaci();

begin

--Gerando horários, intervalo de 10 minutos, com base nos horários dos agendamentos
    open c01;
    loop
        fetch c01 into w_c01;
        exit when c01%notfound;
    
            v_out := type_agendamento_qt
            (
            w_c01.nr_seq_local,
            w_c01.ds_local,
            w_c01.dt_agenda,
            w_c01.ds_status_agendamento,
            w_c01.nr_minuto_duracao
            );

            pipe row(v_out); 

    end loop;
    close c01;

--Gerando horários, intervalo de 10 minutos, com base nos horários faltantes dos agendamentos
    open c02;
    loop
        fetch c02 into w_c02;
        exit when c02%notfound;
    
            w_total_horario_turno := obter_difenca_dt(w_c02.hr_inicial, w_c02.hr_final, 'TM');
            
            if w_total_horario_turno > w_c02.nr_tempo_total_min then
            
                w_tempo_restante := w_total_horario_turno - w_c02.nr_tempo_total_min;
                
                v_out := type_agendamento_qt
                (
                w_c02.nr_seq_local,
                w_c02.ds_local,
                w_c02.dt_agenda,
                'Horário vago',
                w_tempo_restante
                ); 

                pipe row(v_out);
            
            end if;
     
    end loop;
    close c02;
    
end;

end pkg_return_pipelined;
