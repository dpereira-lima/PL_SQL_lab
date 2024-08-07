create or replace function obter_metodo_agendamento(nr_ficha_p number, ie_opcao_p varchar2)
RETURN varchar2 IS

w_ds_result varchar2(32767);
w_ds_proc_princ varchar2(32767);
w_ds_proc_adcional varchar2(32767);

/*------IE_OPCAO_P-------
P - método principal
A - métodos adicionais
T - todos
-----------------------*/

begin

    if (ie_opcao_p = 'P' or ie_opcao_p = 'T') then
    
        for i in (

            select 
                decode (substr (mi.ds_metodo, 1, 3),
                'TC ', 'TOMOGRAFIA COMPUTADORIZADA ',
                'RM ', 'RESSONÂNCIA MAGNÉTICA ',
                'RX ', 'RAIO-X ',
                'USG', 'ULTRASSONOGRAFIA',
                'MMG', 'MAMOGRAFIA',
                substr (mi.ds_metodo, 1, 3))
                || substr (mi.ds_proc_exame, 4, 300) ds_metodo_princ
            from agenda_cliente ac
            inner join metodo_interno mi
               on ac.nr_seq_proc_interno = mi.nr_sequencia
            where ac.nr_ficha = nr_ficha_p

        ) loop
        
            w_ds_proc_princ := w_ds_proc_princ||i.ds_metodo_princ||', ';
        
        end loop;

    elsif (ie_opcao_p = 'A' or ie_opcao_p = 'T') then
    
        for i in (

            select
                decode (substr (mi.ds_proc_exame, 1, 3),
                'TC ', 'TOMOGRAFIA COMPUTADORIZADA ',
                'RM ', 'RESSONÂNCIA MAGNÉTICA ',
                'RX ', 'RAIO-X ',
                'USG', 'ULTRASSONOGRAFIA',
                'MMG', 'MAMOGRAFIA',
                substr (mi.ds_proc_exame, 1, 3))
                || substr (mi.ds_proc_exame, 4, 300) ds_metodo_adcional
            from agenda_cliente ac
            left join agenda_cliente_proc acp
                on ac.nr_sequencia = acp.nr_sequencia
            inner join metodo_interno mi
                on acp.nr_seq_proc_interno = mi.nr_sequencia
            where ac.nr_ficha = nr_ficha_p
                                            
        ) loop
        
            w_ds_proc_adcional := w_ds_proc_adcional||i.ds_metodo_adcional||', ';
        
        end loop;
        
    elsif (ie_opcao_p = 'T') then
    
        w_ds_result := w_ds_proc_princ||w_ds_proc_adcional;
    
    else

        raise_application_error(-20001, 'Opção inválida!');

    end if;
    
    w_ds_result := w_ds_proc_princ||w_ds_proc_adcional;
    
    return w_ds_result;

end;
/
