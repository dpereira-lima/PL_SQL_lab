create or replace package body pkg_pipelined_dados_entrave_alta as

v_ds_stack varchar2(4000);

function fnc_exame_lab_pendente(nr_registro_p varchar2) return varchar2 is

w_ds_retorno varchar2(1);

begin

    begin

        select
            decode(count(1),0,'N','S')
        into
            w_ds_retorno
        from icesp.vw_painel_ps lp
            inner join tasy.exame_lab el
                on upper(lp.ds_exame) like upper(el.nm_exame)||'%'
        where lp.rghc = nr_rghc_p
            and el.nr_seq_grupo_imp in (3, 1, 29, 23, 9)
            and el.nr_seq_exame not in ('2912K','2913S','2917D','2924K','2909A','2910W','3016S','3068C','3018A','3019E',
                                        '3021L','3022R','3023V','3024F','3025W','3026A','3027A','2487D','3028E','3029N',
                                        '3030M','3031O','3032E','3033S','3034D','3035B','3036Y','3037F','3038R','3039T')
            and lp.dt_aprovacao is null;

        exception
        when others then
            v_ds_stack :=
                   'error stack: '
                || sys.dbms_utility.format_error_stack
                || chr(13)
                || 'error backtrace: '
                || sys.dbms_utility.format_error_backtrace
                || chr(13)
                || 'call stack: '
                || sys.dbms_utility.format_call_stack;
        
    end;
        
    return w_ds_retorno;

end;

function fnc_exame_img_pendente(nr_ficha_p number) return varchar2 is

w_ds_retorno varchar2(1);

begin

    begin

        select
            decode(count(1),0,'N','S')
        into
            w_ds_retorno
        from tasy.prescr_med pm
            inner join tasy.prescr_proced pp
                on pm.nr_prescricao = pp.nr_prescricao
            inner join tasy.proc_int pi
                on pp.nr_seq_proc_interno = pi.nr_sequencia
            inner join tasy.proc_int_classif pic
                on pi.nr_seq_classif = pic.nr_sequencia
        where pm.nr_ficha = nr_ficha_p
            and pp.ie_status_execucao <> 20
            and pp.dt_cancelamento is null
            and pp.dt_suspensao is null
            and upper(ds_classif) like 'IMG_SYSTEM%';
          
        exception
        when others then
            v_ds_stack :=
                   'error stack: '
                || sys.dbms_utility.format_error_stack
                || chr(13)
                || 'error backtrace: '
                || sys.dbms_utility.format_error_backtrace
                || chr(13)
                || 'call stack: '
                || sys.dbms_utility.format_call_stack;
        
    end;
        
    return w_ds_retorno;

end;

function fnc_consiste_atend_pendente(nr_ficha_p number) return varchar2 is

w_ds_retorno varchar2(1);

begin

    begin

        select
            decode(count(1),0,'N','S')
        into
            w_ds_retorno
        from atend_medico_req pmr
        where pmr.nr_ficha = nr_ficha_p
            and pmr.dt_aprovacao is not null
            and pmr.dt_inativacao is null
            and not exists (select 1
                            from atend_medico pm
                            where pmr.nr_parecer = pm.nr_parecer
                                and pm.dt_aprovacao is not null
                                and pm.dt_inativacao is null);

        exception
        when others then
            v_ds_stack :=
                   'error stack: '
                || sys.dbms_utility.format_error_stack
                || chr(13)
                || 'error backtrace: '
                || sys.dbms_utility.format_error_backtrace
                || chr(13)
                || 'call stack: '
                || sys.dbms_utility.format_call_stack;
        
    end;
        
    return w_ds_retorno;

end;
  
function cliente_internados return tp_cliente_internados_v pipelined
as

v_out_v type_cliente_internados_v;

cursor c_cliente is
select
    pf.nr_registro,
    fnc_iniciais_nome(pf.cd_cadastro_pf, null) nm_cliente,
    pf.dt_nasc,
    ap.nr_ficha,
    nvl2(clr.cd_doenca_cid, clr.cd_doenca_cid || ' - '|| fnc_desc_cid(clr.cd_doenca_cid), 'NI') ds_cid,
    fnc_unidade_atendimento(ap.nr_ficha, 'PI', 'S') ds_prim_setor,
    fnc_unidade_atendimento(ap.nr_ficha, 'IA', 'S') ds_setor_atual,
    fnc_valor_dominio(17, ap.ie_clinica) ds_clinica,
    trunc(sysdate) - trunc(ap.dt_entrada) qt_dias_internacao,
    case
        when apa.nr_sequencia is null then 'NI'
        else to_char(trunc(apa.dt_previsto_alta) - trunc(sysdate))
    end qt_dias_previsao_alta,
    nvl2(base_pedido_alta_medico.qt_pedido_alta_medico, 'SIM', 'NÃO') ie_pedido_alta_medica
from cadastro_pf pf
    inner join atend_cliente ap
        on pf.cd_cadastro_pf = ap.cd_cadastro_pf
    left join (select count(pmr.nr_parecer) qt_parecer_pendente, pmr.nr_ficha
                from atend_medico_req pmr
                where pmr.dt_aprovacao is not null
                    and pmr.dt_inativacao is null
                    and not exists (select 1
                                    from atend_medico pm
                                    where pmr.nr_parecer = pm.nr_parecer
                                        and pm.dt_aprovacao is not null
                                        and pm.dt_inativacao is null)
                group by pmr.nr_ficha) base_parecer
        on ap.nr_ficha = base_parecer.nr_ficha
    left join (select count(a.nr_sequencia) qt_pedido_alta_medico, a.nr_ficha
                from form_registro a
                    left join form_reg_template b
                        on a.nr_sequencia = b.nr_seq_reg
                where a.dt_aprovacao is not null
                    and a.dt_inativacao is null
                    and a.nr_seq_item_pront = 153
                    and b.nr_seq_template = 100273
                group by a.nr_ficha) base_pedido_alta_medico
        on ap.nr_ficha = base_pedido_alta_medico.nr_ficha
    left join (select max(nr_sequencia) nr_sequencia, nr_ficha
                from atend_prev_alta
                where dt_aprovacao is not null
                    and dt_inativacao is null
                    and trunc(dt_previsto_alta) >= trunc(sysdate)
                group by nr_ficha) base_previsao_alta
        on ap.nr_ficha = base_previsao_alta.nr_ficha
    left join atend_prev_alta apa
        on base_previsao_alta.nr_sequencia = apa.nr_sequencia
    left join (select max(nr_sequencia) nr_sequencia, cd_pessoa_fisica
                from can_loco_reg
                where dt_aprovacao is not null
                    and dt_inativacao is null
                group by cd_pessoa_fisica) base_cid
        on pf.cd_pessoa_fisica = base_cid.cd_pessoa_fisica
    left join can_loco_reg clr
        on base_cid.nr_sequencia = clr.nr_sequencia
where ap.dt_alta is null
    and ap.dt_cancelamento is null
    and ap.ie_tipo_atendimento in (1)
    and exists (select 1
                from unidade_atend ua
                where ap.nr_ficha = ua.nr_ficha)
    and (fnc_unidade_atendimento(ap.nr_ficha, 'IA', 'S') not like '%PS%'
        and fnc_unidade_atendimento(ap.nr_ficha, 'IA', 'S') not like '%INFANT%'
        and upper(fnc_unidade_atendimento(ap.nr_ficha, 'IA', 'S')) not like '%HD%'
        and fnc_unidade_atendimento(ap.nr_ficha, 'IA', 'S') not like '%PROC%');

w_c_cliente c_cliente%rowtype;

cursor c_atend_med is
select
    pmr.nr_atendimento,
    nvl(substr(fnc_desc_espec_profissional(cd_especialidade_dest_prof),1,100),substr(fnc_desc_espec_medica(cd_especialidade_dest),1,100)) ds_especialidade
from atend_medico_req pmr
where pmr.nr_ficha = w_nr_ficha
    and pmr.dt_aprovacao is not null
    and pmr.dt_inativacao is null
    and not exists (select 1
                    from atend_medico pm
                    where pmr.nr_atendimento = pm.nr_atendimento
                        and pm.dt_aprovacao is not null
                        and pm.dt_inativacao is null);

w_c_atend_med c_atend_med%rowtype;

begin

    open c_cliente;
    loop
        fetch c_cliente into w_nr_registro, w_nm_cliente, w_dt_nasc, w_nr_ficha, w_ds_cid, w_ds_prim_setor, w_ds_setor_atual,
                        w_ds_clinica, w_qt_dias_inter, w_qt_dias_prev_alta, w_ie_pedido_alta_med;
        exit when c_cliente%notfound;

        if fnc_exame_lab_pendente(w_nr_registro) = 'S' then

            v_out_v := type_cliente_internados_v
            (
            w_nr_registro,
            w_nm_cliente,
            w_dt_nasc,
            w_nr_ficha,
            w_ds_cid,
            w_ds_prim_setor,
            w_ds_setor_atual,
            w_ds_clinica,
            w_qt_dias_inter,
            w_qt_dias_prev_alta,
            w_ie_pedido_alta_med,
            'LAB',
            w_ds_espec_med
            ); 
            
            begin

                pipe row(v_out_v);

                exception
                when others then
                v_ds_stack :=
                'error stack: '
                || sys.dbms_utility.format_error_stack
                || chr(13)
                || 'error backtrace: '
                || sys.dbms_utility.format_error_backtrace
                || chr(13)
                || 'call stack: '
                || sys.dbms_utility.format_call_stack;

            end;

        end if;
        
        if fnc_exame_img_pendente(w_nr_ficha) = 'S' then
        
            v_out_v := type_cliente_internados_v
            (
            w_nr_registro,
            w_nm_cliente,
            w_dt_nasc,
            w_nr_ficha,
            w_ds_cid,
            w_ds_prim_setor,
            w_ds_setor_atual,
            w_ds_clinica,
            w_qt_dias_inter,
            w_qt_dias_prev_alta,
            w_ie_pedido_alta_med,
            'IMG',
            w_ds_espec_med
            );

            begin

                pipe row(v_out_v);

                exception
                when others then
                v_ds_stack :=
                'error stack: '
                || sys.dbms_utility.format_error_stack
                || chr(13)
                || 'error backtrace: '
                || sys.dbms_utility.format_error_backtrace
                || chr(13)
                || 'call stack: '
                || sys.dbms_utility.format_call_stack;

            end;

        end if; 

        if fnc_consiste_atend_pendente(w_nr_ficha) = 'S' then
        
            open c_atend_med;
            loop
                fetch c_atend_med into w_c_atend_med;
                exit when c_atend_med%notfound;
                
                    v_out_v := type_cliente_internados_v
                    (
                    w_nr_registro,
                    w_nm_cliente,
                    w_dt_nasc,
                    w_nr_ficha,
                    w_ds_cid,
                    w_ds_prim_setor,
                    w_ds_setor_atual,
                    w_ds_clinica,
                    w_qt_dias_inter,
                    w_qt_dias_prev_alta,
                    w_ie_pedido_alta_med,
                    'ATEND',
                    w_ds_espec_med
                    );

                    begin

                        pipe row(v_out_v);

                        exception
                        when others then
                        v_ds_stack :=
                        'error stack: '
                        || sys.dbms_utility.format_error_stack
                        || chr(13)
                        || 'error backtrace: '
                        || sys.dbms_utility.format_error_backtrace
                        || chr(13)
                        || 'call stack: '
                        || sys.dbms_utility.format_call_stack;

                    end;
                
            end loop;
            close c_atend_med;

        end if;
            
        if fnc_exame_lab_pendente(w_nr_registro) = 'N' and fnc_exame_img_pendente(w_nr_ficha) = 'N' and fnc_consiste_atend_pendente(w_nr_ficha) = 'N' then

            v_out_v := type_cliente_internados_v
            (
            w_nr_registro,
            w_nm_cliente,
            w_dt_nasc,
            w_nr_ficha,
            w_ds_cid,
            w_ds_prim_setor,
            w_ds_setor_atual,
            w_ds_clinica,
            w_qt_dias_inter,
            w_qt_dias_prev_alta,
            w_ie_pedido_alta_med,
            'SEM ENTRAVE',
            w_ds_espec_med
            ); 

            begin

                pipe row(v_out_v);

                exception
                when others then
                v_ds_stack :=
                'error stack: '
                || sys.dbms_utility.format_error_stack
                || chr(13)
                || 'error backtrace: '
                || sys.dbms_utility.format_error_backtrace
                || chr(13)
                || 'call stack: '
                || sys.dbms_utility.format_call_stack;

            end;

        end if;
        
    end loop;
    close c_cliente;
    
end;

end;
