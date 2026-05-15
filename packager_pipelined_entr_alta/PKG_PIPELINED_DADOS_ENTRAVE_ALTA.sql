CREATE OR REPLACE package pkg_pipelined_dados_entrave_alta as

        w_nr_registro varchar2(100);
        w_nm_cliente varchar2(1000);
        w_dt_nasc date;
        w_nr_ficha number;
        w_ds_cid varchar2(1000);
        w_ds_prim_setor varchar2(1000);
        w_ds_setor_atual varchar2(1000);
        w_ds_clinica varchar2(500);
        w_qt_dias_inter number;
        w_qt_dias_prev_alta varchar2(100);
        w_ie_pedido_alta_med varchar2(100);
        w_ie_entrave_alta varchar2(100);
        w_ds_espec_med varchar2(1000);

    type type_paciente_internados_v is record (
        nr_registro varchar2(100),
        nm_cliente varchar2(1000),
        dt_nasc date,
        nr_ficha number,
        ds_cid varchar2(1000),
        ds_prim_setor varchar2(1000),
        ds_setor_atual varchar2(1000),
        ds_clinica varchar2(500),
        qt_dias_inter number,
        qt_dias_prev_alta varchar2(100),
        ie_pedido_alta_med varchar2(100),
        ie_entrave_alta varchar2(100),
        ds_espec_med varchar2(1000)
    );    

    type tp_cliente_internados_v is table of type_cliente_internados_v;

    function cliente_internados return tp_cliente_internados_v pipelined;
    
end;
/

