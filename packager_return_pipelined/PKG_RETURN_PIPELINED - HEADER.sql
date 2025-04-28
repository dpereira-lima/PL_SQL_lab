create or replace package pkg_return_pipelined as

    w_nr_seq_local number;
    w_ds_local varchar2(4000);
    w_dt_agenda date;
    w_ds_status_agendamento varchar2(4000);
    w_nr_minuto_duracao number;

    type type_agendamento_qt is record (
    
        nr_seq_local number,
        ds_local varchar2(4000),
        dt_agenda date,
        ds_status_agendamento varchar2(4000),
        nr_minuto_duracao number
        
    );
    
    type tp_agendamento_qt is table of type_agendamento_qt;
    
    function agendamentos return tp_agendamento_qt pipelined;
    
end pkg_return_pipelined;
/