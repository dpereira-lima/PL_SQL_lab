create or replace function fnc_valida_tp_hemocomponente(ds_hemocomponente_p varchar2)

return varchar2 is

ds_retorno varchar2(1);

begin

    if to_number(instr(upper(ds_hemocomponente_p), 'PLAQUETA')) > 0 then
    
        ds_retorno := 'S';
        
    elsif to_number(instr(upper(ds_hemocomponente_p), 'HEMACIA')) > 0 then
    
        ds_retorno := 'S';
        
    else
    
        ds_retorno := 'N';
        
    end if;
    
    return ds_retorno;
    
end;