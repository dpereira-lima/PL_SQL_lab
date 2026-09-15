create or replace procedure prc_rel_sint_integracao
as

--cadastro de exames e complementos - vinculos de complemento
cursor c_novo_cadastro is
select
    ie_tipo_registro,
    case 
        nm_tbl_registro
        when 'LAB_MATERIAL' then 'Materiais'
        when 'LAB_METODO' then 'Métodos'
        when 'LAB_FORMAT' then 'Formatos - micro'
        when 'LAB_FORMAT_ITEM' then 'Formatos - micro'
        when 'LAB_VALOR' then 'Valores - micro'
        when 'LAB_SETOR' then 'Setores - micro'
        when 'LABORATORIO' then 'Exames'
        when 'MATERIAL_LAB' then 'Materiais'
        when 'LAB_UM' then 'UM'
        when 'METODO_LAB' then 'Métodos'
        when 'CIH_MICRO' then 'Micro'
        when 'CIH_MEDIC' then 'Antibióticos'
    end tp_importacao,
    count(*) qt_quantidade
from tbl019_intermediaria
where trunc(dt_atualizacao) = trunc(sysdate) - 1 --dia anterior
group by 
    ie_tipo_registro,
    case nm_tbl_registro
        when 'LAB_MATERIAL' then 'Materiais'
        when 'LAB_METODO' then 'Métodos'
        when 'LAB_FORMAT' then 'Formatos - micro'
        when 'LAB_FORMAT_ITEM' then 'Formatos - micro'
        when 'LAB_VALOR' then 'Valores - micro'
        when 'LAB_SETOR' then 'Setores - micro'
        when 'LABORATORIO' then 'Exames'
        when 'MATERIAL_LAB' then 'Materiais'
        when 'LAB_UM' then 'UM'
        when 'METODO_LAB' then 'Métodos'
        when 'CIH_MICRO' then 'Micro'
        when 'CIH_MEDIC' then 'Antibióticos'
    end
order by 1, 2;

w_c_novo_cadastro c_novo_cadastro%rowtype;

cursor c_exames_pendentes is
select
    nm_cliente,
    id_cliente,
    id_pedido,
    qt_exame
from(select
        obter_iniciais(pf.cd_cliente, null) nm_cliente,
        pf.id_cliente,
        a.id_pedido,
        count(*) qt_exame
    from tbl013_intermediaria a
        left join cad_cliente pf
            on a.id_externo = pf.identificador_externo
    where trunc(a.dt_atualizacao) = trunc(sysdate) - 1 --dia anterior
        and nvl(a.ie_importado, 'N') = 'N'
    group by obter_iniciais(pf.cd_cliente, null), pf.id_cliente, a.id_pedido
    order by 2, 3);

w_c_exames_pendentes c_exames_pendentes%rowtype;

w_rel_final clob;
w_rel_novo_cadastro clob;
w_rel_novo_vinculo clob;

w_qt_reg_cadastrado number;
w_qt_reg_vinculado number;
w_qt_exame_pendente number;
w_total_exame number;
w_exame_importado number;

w_grafico_svg clob;

function fn_gerar_grafico_svg
return clob
is

    type t_hora_rec is record (
        v_periodo   number,
        v_externo   number,
        v_interno   number
    );
    type t_dados_tab is table of t_hora_rec index by pls_integer; -- índice 0..23

    v_dados         t_dados_tab;
    v_hora_idx      pls_integer;

    -- dimensões do gráfico
    c_largura       constant pls_integer := 820;
    c_altura        constant pls_integer := 240;
    c_pad_esq       constant pls_integer := 35;   -- espaço p/ rótulos do eixo Y
    c_pad_dir       constant pls_integer := 15;
    c_pad_topo      constant pls_integer := 15;
    c_pad_base      constant pls_integer := 35;   -- espaço p/ rótulos do eixo X

    c_area_larg     constant pls_integer := c_largura - c_pad_esq - c_pad_dir;
    c_area_alt      constant pls_integer := c_altura  - c_pad_topo - c_pad_base;

    -- escala fixa do eixo Y
    c_eixo_y_max    constant pls_integer := 10;

    v_x_step        number;
    v_y_scale       number;

    v_pts_periodo   varchar2(4000) := '';
    v_pts_externo   varchar2(4000) := '';
    v_pts_interno   varchar2(4000) := '';

    v_marcadores    clob := '';
    v_grade         clob := '';
    v_eixo_x        clob := '';

    v_svg           clob;

    v_x             number;
    v_y_periodo     number;
    v_y_externo     number;
    v_y_interno     number;

    -- cores das séries
    c_cor_periodo   constant varchar2(10) := '#4472C4'; -- azul
    c_cor_externo   constant varchar2(10) := '#C0392B'; -- vermelho
    c_cor_interno   constant varchar2(10) := '#8DB255'; -- verde

    function fmt(p_num number) return varchar2 is
    begin
        return to_char(round(p_num, 2), 'FM999990.00', 'NLS_NUMERIC_CHARACTERS = ''.,''');
    end;

begin

    --inicializa as 24 horas com zero
    for i in 0..23 loop
        v_dados(i).v_periodo := 0;
        v_dados(i).v_externo := 0;
        v_dados(i).v_interno := 0;
    end loop;

    --cursor com a consulta original
    for r in (
        select
            to_char(to_date(steps.dt_inicio, 'dd/mm/yyyy hh24:mi:ss'), 'hh24') || ':00' hr_execucao,
            median(to_number(obter_dif_data(
                to_date(steps.dt_inicio, 'dd/mm/yyyy hh24:mi:ss'),
                to_date(steps.dt_fim,    'dd/mm/yyyy hh24:mi:ss'),
                'TM'))) min_param,
            median(obter_dif_data(steps.dt_atualizacao, carregar_id_cliente.dt_atualizacao, 'TM')
                 + obter_dif_data(buscaresultado.dt_atualizacao, gr_resul_proces.dt_atualizacao, 'tm')) min_proc_extern,
            median(obter_dif_data(carregar_id_cliente.dt_atualizacao, buscaresultado.dt_atualizacao, 'tm')
                 + obter_dif_data(gr_resul_proces.dt_atualizacao, ord_exame.dt_atualizacao, 'tm')) min_proc_inter
        from (
            select nr_processamento, dt_inicio, dt_fim, dt_atualizacao
            from tbl010_intermediaria
            where ds_step = 'listaresultados'
              and nvl(ds_rotina, '0') <> 'prc002_integracao'
              and trunc(to_date(dt_inicio, 'dd/mm/yyyy hh24:mi:ss')) = trunc(sysdate) - 1
        ) steps
        left join tbl010_intermediaria buscaresultado
               on steps.nr_processamento = buscaresultado.nr_processamento
              and buscaresultado.ds_step = 'buscaresultado'
              and nvl(buscaresultado.ds_rotina, '0') <> 'prc002_integracao'
        left join tbl010_intermediaria carregar_id_cliente
               on steps.nr_processamento = carregar_id_cliente.nr_processamento
              and carregar_id_cliente.ds_step = 'carregar_id_cliente'
              and nvl(carregar_id_cliente.ds_rotina, '0') <> 'prc002_integracao'
        left join tbl010_intermediaria gr_resul_proces
               on steps.nr_processamento = gr_resul_proces.nr_processamento
              and gr_resul_proces.ds_step = 'gerar_resultado_processamento'
              and nvl(gr_resul_proces.ds_rotina, '0') <> 'prc002_integracao'
        left join tbl010_intermediaria ord_exame
               on steps.nr_processamento = ord_exame.nr_processamento
              and ord_exame.ds_step = 'ordenacao_exame'
              and nvl(ord_exame.ds_rotina, '0') <> 'prc002_integracao'
        group by to_char(to_date(steps.dt_inicio, 'dd/mm/yyyy hh24:mi:ss'), 'hh24') || ':00'
        order by 1
    )
    loop
        v_hora_idx := to_number(substr(r.hr_execucao, 1, 2));

        v_dados(v_hora_idx).v_periodo := nvl(r.min_param, 0);
        v_dados(v_hora_idx).v_externo := nvl(r.min_proc_extern, 0);
        v_dados(v_hora_idx).v_interno := nvl(r.min_proc_inter, 0);
    end loop;

    --calculo da escalas
    v_x_step  := c_area_larg / 23;
    v_y_scale := c_area_alt  / c_eixo_y_max;

    for i in 0..23 loop
        v_x         := c_pad_esq + (i * v_x_step);
        v_y_periodo := c_pad_topo + c_area_alt - (least(v_dados(i).v_periodo, c_eixo_y_max) * v_y_scale);
        v_y_externo := c_pad_topo + c_area_alt - (least(v_dados(i).v_externo, c_eixo_y_max) * v_y_scale);
        v_y_interno := c_pad_topo + c_area_alt - (least(v_dados(i).v_interno, c_eixo_y_max) * v_y_scale);

        v_pts_periodo := v_pts_periodo || fmt(v_x) || ',' || fmt(v_y_periodo) || ' ';
        v_pts_externo := v_pts_externo || fmt(v_x) || ',' || fmt(v_y_externo) || ' ';
        v_pts_interno := v_pts_interno || fmt(v_x) || ',' || fmt(v_y_interno) || ' ';

        --marcadores (círculos) de cada série neste ponto
        v_marcadores := v_marcadores
            || '<circle cx="' || fmt(v_x) || '" cy="' || fmt(v_y_periodo) || '" r="3" fill="' || c_cor_periodo || '"/>'
            || '<circle cx="' || fmt(v_x) || '" cy="' || fmt(v_y_externo) || '" r="3" fill="' || c_cor_externo || '"/>'
            || '<circle cx="' || fmt(v_x) || '" cy="' || fmt(v_y_interno) || '" r="3" fill="' || c_cor_interno || '"/>';

        --rótulo do eixo x (hora), rotacionado levemente para não sobrepor
        v_eixo_x := v_eixo_x
            || '<text x="' || fmt(v_x) || '" y="' || fmt(c_pad_topo + c_area_alt + 16)
            || '" font-size="9" fill="#666666" text-anchor="middle" font-family="segoe ui, arial, sans-serif">'
            || lpad(i, 2, '0') || ':00</text>';
    end loop;

    --grade horizontal (0,2,4,6,8,10) com rótulos do eixo y
    for nivel in 0..c_eixo_y_max/2 loop
        v_y_periodo := c_pad_topo + c_area_alt - (nivel * 2 * v_y_scale);

        v_grade := v_grade
            || '<line x1="' || fmt(c_pad_esq) || '" y1="' || fmt(v_y_periodo)
            || '" x2="' || fmt(c_pad_esq + c_area_larg) || '" y2="' || fmt(v_y_periodo)
            || '" stroke="#e6e6e6" stroke-width="1"/>'
            || '<text x="' || fmt(c_pad_esq - 8) || '" y="' || fmt(v_y_periodo + 3)
            || '" font-size="10" fill="#999999" text-anchor="end" font-family="segoe ui, arial, sans-serif">'
            || (nivel * 2) || '</text>';
    end loop;

    --monta o svg final (grade -> linhas -> marcadores -> eixo x -> legenda)
    v_svg :=
        '<svg viewbox="0 0 ' || c_largura || ' ' || (c_altura + 30)
        || '" width="' || c_largura || '" height="' || (c_altura + 30)
        || '" xmlns="http://www.w3.org/2000/svg">'
        || v_grade
        || '<polyline points="' || v_pts_periodo || '" fill="none" stroke="' || c_cor_periodo || '" stroke-width="2"/>'
        || '<polyline points="' || v_pts_externo || '" fill="none" stroke="' || c_cor_externo || '" stroke-width="2"/>'
        || '<polyline points="' || v_pts_interno || '" fill="none" stroke="' || c_cor_interno || '" stroke-width="2"/>'
        || v_marcadores
        || v_eixo_x
        -- legenda
        || '<circle cx="20"  cy="' || (c_altura + 15) || '" r="4" fill="' || c_cor_periodo || '"/>'
        || '<text x="30" y="' || (c_altura + 19) || '" font-size="11" fill="#333333" font-family="segoe ui, arial, sans-serif">período de busca</text>'
        || '<circle cx="180" cy="' || (c_altura + 15) || '" r="4" fill="' || c_cor_externo || '"/>'
        || '<text x="190" y="' || (c_altura + 19) || '" font-size="11" fill="#333333" font-family="segoe ui, arial, sans-serif">min processamento externo</text>'
        || '<circle cx="420" cy="' || (c_altura + 15) || '" r="4" fill="' || c_cor_interno || '"/>'
        || '<text x="430" y="' || (c_altura + 19) || '" font-size="11" fill="#333333" font-family="segoe ui, arial, sans-serif">min processamento interno</text>'
        || '</svg>';

    return v_svg;

end;

begin

--cabeçalho do e-mail
    w_rel_final := '<!doctype html>
                    <html>

                    <head>
                    <meta charset="utf-8">
                    <title>relatório de integração laboratório</title>
                    </head>

                    <body style="margin:0;padding:20px;background:#f4f6f8;font-family:''segoe ui'',arial,sans-serif;">

                    <table width="900" align="center" cellpadding="0" cellspacing="0" border="0" style="background:#ffffff;border-collapse:collapse;border:1px solid #e1e6eb;">

                        <tr>
                            <td style="background:#0f5e8c;color:#ffffff;padding:24px 30px;">
                                <div style="font-size:26px;font-weight:bold;font-family:''segoe ui'',arial,sans-serif;">
                                    integração de exames laboratoriais
                                </div>
                                <div style="margin-top:6px;font-size:14px;color:#d9e7f5;font-family:''segoe ui'',arial,sans-serif;">
                                    relatório sintético da integração
                                </div>
                                <div style="margin-top:14px;font-size:12px;color:#d9e7f5;font-family:''segoe ui'',arial,sans-serif;">
                                    dados processados em: <strong style="color:#ffffff;">'||to_char(sysdate - 1, 'dd/mm/yyyy')||'</strong>
                                </div>
                            </td>
                        </tr>';

--card's
    select
        count(*)
    into
        w_total_exame
    from tbl013_intermediaria
    where trunc(dt_atualizacao) = trunc(sysdate) - 1;
        
    select
        count(*)
    into
        w_exame_importado
    from tbl013_intermediaria
    where trunc(dt_atualizacao) = trunc(sysdate) - 1
        and nvl(ie_importado, 'n') = 's';

    w_rel_final := w_rel_final||
    '<tr>
        <td style="padding:24px 30px 8px 30px;">
            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                    <td width="33%" align="center" style="padding-right:8px;">
                        <table width="100%" cellpadding="16" cellspacing="0" border="0"
                               style="background:#e8f3fe;border:1px solid #c7dcef;border-radius:4px;">
                            <tr>
                                <td align="center">
                                    <div style="font-size:36px;color:#0d5e8d;font-weight:bold;font-family:''segoe ui'',arial,sans-serif;">'||to_char(w_total_exame, '999g999g999g999')||'</div>
                                    <div style="margin-top:4px;font-size:13px;color:#3d5a73;font-family:''segoe ui'',arial,sans-serif;">exames recebidos</div>
                                </td>
                            </tr>
                        </table>
                    </td>
                    <td width="33%" align="center" style="padding:0 4px;">
                        <table width="100%" cellpadding="16" cellspacing="0" border="0"
                               style="background:#edf8ee;border:1px solid #c9e7cd;border-radius:4px;">
                            <tr>
                                <td align="center">
                                    <div style="font-size:36px;color:#14823e;font-weight:bold;font-family:''segoe ui'',arial,sans-serif;">'||to_char(w_exame_importado, '999g999g999g999')||'</div>
                                    <div style="margin-top:4px;font-size:13px;color:#2e5e3b;font-family:''segoe ui'',arial,sans-serif;">importados</div>
                                </td>
                            </tr>
                        </table>
                    </td>
                    <td width="33%" align="center" style="padding-left:8px;">
                        <table width="100%" cellpadding="16" cellspacing="0" border="0"
                               style="background:#fceeee;border:1px solid #f0c6c2;border-radius:4px;">
                            <tr>
                                <td align="center">
                                    <div style="font-size:36px;color:#c0392b;font-weight:bold;font-family:''segoe ui'',arial,sans-serif;">'||to_char(w_total_exame - w_exame_importado, '999g999g999g999')||'</div>
                                    <div style="margin-top:4px;font-size:13px;color:#7b342a;font-family:''segoe ui'',arial,sans-serif;">pendentes</div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </td>
    </tr>';

--média de tempos
    w_grafico_svg := fn_gerar_grafico_svg;
    
    w_rel_final := w_rel_final||
        '<tr>
            <td style="padding:24px 30px 0 30px;">
                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td style="background:#0f5e8c;color:#ffffff;font-size:16px;font-weight:bold;padding:10px 14px;font-family:''segoe ui'',arial,sans-serif;border-left:5px solid #0a3d5c;">
                            média de tempos
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td align="center" style="padding:20px 30px 30px 30px;">'||w_grafico_svg||
            '</td>
        </tr>';

--se houver casos de cadastro ou vinculo
    select
        count(*)
    into
        w_qt_reg_cadastrado
    from tbl019_intermediaria
    where trunc(dt_atualizacao) = trunc(sysdate) - 1
        and ie_tipo_registro = 'cadastro';
        
    select
        count(*)
    into
        w_qt_reg_vinculado
    from tbl019_intermediaria
    where trunc(dt_atualizacao) = trunc(sysdate) - 1
        and ie_tipo_registro = 'vinculo';

    if (w_qt_reg_cadastrado > 0 or w_qt_reg_vinculado > 0) then
        
        w_rel_final := w_rel_final||
                        '<tr>
                            <td style="padding:24px 30px 0 30px;">
                                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                    <tr>
                                        <td style="background:#0f5e8c;color:#ffffff;font-size:16px;font-weight:bold;padding:10px 14px;font-family:''segoe ui'',arial,sans-serif;border-left:5px solid #0a3d5c;">
                                            revisar
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>';
        
    end if;

--montagem do relatório de novos cadastro de exames e complementos    
    if w_qt_reg_cadastrado > 0 then
    
        w_rel_novo_cadastro := 
                    '<tr>
                        <td style="padding:12px 30px 0 30px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0" style="border:1px solid #e1e6eb;border-collapse:collapse;">
                                <tr>
                                    <td colspan="2" style="background:#d9e7f5;color:#0f5e8c;font-weight:bold;font-size:13px;padding:8px 10px;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #c7dcef;">
                                        cadastro de novos exames e complementos
                                    </td>
                                </tr>';
    
        open c_novo_cadastro;
        loop
            fetch c_novo_cadastro into w_c_novo_cadastro;
            exit when c_novo_cadastro%notfound;
            
                begin
                
                    if w_c_novo_cadastro.ie_tipo_registro = 'cadastro' then
                
                        w_rel_novo_cadastro := w_rel_novo_cadastro||
                                '<tr>
                                    <td style="padding:8px 10px;font-size:13px;color:#333333;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #f0f2f4;">'||w_c_novo_cadastro.tp_importacao||'</td>
                                    <td align="right" style="padding:8px 10px;font-size:13px;color:#333333;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #f0f2f4;">'||w_c_novo_cadastro.qt_quantidade||'</td>
                                </tr>';
                            
                    end if;
                
                end;
            
        end loop;
        close c_novo_cadastro;
        
        w_rel_novo_cadastro := w_rel_novo_cadastro||'</table></td></tr>';
        
        w_rel_final := w_rel_final||w_rel_novo_cadastro;

    end if;
    
--montagem do relatório de novos vinculos no cadastro de exames
    if w_qt_reg_vinculado > 0 then
    
        w_rel_novo_vinculo := 
                    '<tr>
                        <td style="padding:16px 30px 0 30px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0" style="border:1px solid #e1e6eb;border-collapse:collapse;">
                                <tr>
                                    <td colspan="2" style="background:#d9e7f5;color:#0f5e8c;font-weight:bold;font-size:13px;padding:8px 10px;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #c7dcef;">
                                        vínculos novos de complementos
                                    </td>
                                </tr>';
    
        open c_novo_cadastro;
        loop
            fetch c_novo_cadastro into w_c_novo_cadastro;
            exit when c_novo_cadastro%notfound;
            
                    if w_c_novo_cadastro.ie_tipo_registro = 'vinculo' then
                
                        w_rel_novo_vinculo := w_rel_novo_vinculo||
                                '<tr>
                                    <td style="padding:8px 10px;font-size:13px;color:#333333;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #f0f2f4;">'||w_c_novo_cadastro.tp_importacao||'</td>
                                    <td align="right" style="padding:8px 10px;font-size:13px;color:#333333;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #f0f2f4;">'||w_c_novo_cadastro.qt_quantidade||'</td>
                                </tr>';
                            
                    end if;
            
        end loop;
        close c_novo_cadastro;
        
        w_rel_novo_vinculo := w_rel_novo_vinculo||'</table></td></tr>';
        
        w_rel_final := w_rel_final||w_rel_novo_vinculo;

    end if;

--analisar
    select
        count(*)
    into
        w_qt_exame_pendente
    from tbl013_intermediaria a
        left join cad_cliente pf
            on a.iddw = pf.identificador_dw
    where trunc(a.dt_atualizacao) = trunc(sysdate) - 1
        and nvl(a.ie_importado, 'n') = 'n';

    if w_qt_exame_pendente > 0 then
    
        w_rel_final := w_rel_final||
                    '<tr>
                        <td style="padding:24px 30px 0 30px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                    <td style="background:#0f5e8c;color:#ffffff;font-size:16px;font-weight:bold;padding:10px 14px;font-family:''segoe ui'',arial,sans-serif;border-left:5px solid #0a3d5c;">
                                        analisar
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding:12px 30px 0 30px;">
                            <table width="100%" cellpadding="0" cellspacing="0" border="0" style="border:1px solid #e1e6eb;border-collapse:collapse;">
                                <tr>
                                    <td colspan="4" style="background:#d9e7f5;color:#0f5e8c;font-weight:bold;font-size:13px;padding:8px 10px;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #c7dcef;">
                                        paciente com exames não importados
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:6px 10px;font-size:12px;color:#5a5a5a;font-weight:bold;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #e1e6eb;">cliente</td>
                                    <td style="padding:6px 10px;font-size:12px;color:#5a5a5a;font-weight:bold;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #e1e6eb;">id cliente</td>
                                    <td style="padding:6px 10px;font-size:12px;color:#5a5a5a;font-weight:bold;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #e1e6eb;">pedido</td>
                                    <td align="center" style="padding:6px 10px;font-size:12px;color:#5a5a5a;font-weight:bold;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #e1e6eb;">qt. exames</td>
                                </tr>';

        open c_exames_pendentes;
        loop
            fetch c_exames_pendentes into w_c_exames_pendentes;
            exit when c_exames_pendentes%notfound;
            
                w_rel_final := w_rel_final||
                    '<tr>
                        <td style="padding:8px 10px;font-size:13px;color:#333333;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #f0f2f4;">'||w_c_exames_pendentes.nm_cliente||'</td>
                        <td style="padding:8px 10px;font-size:13px;color:#333333;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #f0f2f4;">'||w_c_exames_pendentes.id_cliente||'</td>
                        <td style="padding:8px 10px;font-size:13px;color:#333333;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #f0f2f4;">'||to_char(w_c_exames_pendentes.id_pedido)||'</td>
                        <td align="center" style="padding:8px 10px;font-size:13px;color:#333333;font-family:''segoe ui'',arial,sans-serif;border-bottom:1px solid #f0f2f4;">'||to_char(w_c_exames_pendentes.qt_exame)||'</td>
                    </tr>';
            
        end loop;
        close c_exames_pendentes;
        
        w_rel_final := w_rel_final||'</table></td></tr>';

    end if;
	
--rodapé
    w_rel_final := w_rel_final||'<tr>
        <td style="background:#eef3f7;color:#8a94a0;text-align:center;padding:16px;font-size:11px;font-family:''segoe ui'',arial,sans-serif;border-top:1px solid #e1e6eb;">
            relatório sintético integração laboratório - não responder este e-mail.
        </td>
    </tr>';
    
    prc001_envia_email(sysdate, 'relatório sintético integração lab - '||to_char(sysdate - 1, 'dd/mm/yyyy'), 'remetente', 'email@email.com.br', w_rel_final, sysdate, null, null);
    
    commit;

end;