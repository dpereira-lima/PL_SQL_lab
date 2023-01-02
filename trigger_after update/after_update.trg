create or replace trigger disparo_email
after update on nm_tabela

for each row
declare

--cursor das OCs com material de marcar reprovada
cursor c01 is
    select
        e.nr_ordem_compra
    from mat_marca a
        inner join mat b
            on a.cd_material = b.cd_material
        inner join marca c
            on a.nr_sequencia = c.nr_sequencia
        left join oc_item d
            on b.cd_material = d.cd_material
        left join ord_compra e
            on d.nr_ordem_compra = e.nr_ordem_compra
    where a.nr_sequencia = :new.nr_sequencia
        and a.cd_material = :new.cd_material
        and e.dt_baixa is null
        and a.nr_sequencia = d.nr_seq_marca
        and exists (select 1
                    from oc_item_entrega f
                    where trunc(f.dt_prevista_entrega) > sysdate
                        and d.nr_ordem_compra = f.nr_ordem_compra
                        and d.nr_item_oci = f.nr_item_oci);

v_quant number(9);
v_nr_ordem_compra ord_compra.nr_ordem_compra%type;
v_nr_ordem_compra2 varchar2(99);
v_contador number(9);
v_cd_material mat.ds_material%type;
v_ds_material mat.ds_material%type;
v_ds_marca marca.ds_marca%type;
v_cd_referencia mat_marca.cd_referencia%type;
v_nr_sequencia mat_marca.nr_sequencia%type;

pragma autonomous_transaction;

begin

--verificando se o novo status da marca é Reprovada
if (:new.nr_seq_status_aval = 2) then

    v_contador := 1;

    select
        count(1)
    into
        v_quant
    from mat_marca a
        inner join material b
            on a.cd_material = b.cd_material
        inner join marca c
            on a.nr_sequencia = c.nr_sequencia
        left join oc_item d
            on b.cd_material = d.cd_material
        left join ord_compra e
            on d.nr_ordem_compra = e.nr_ordem_compra
    where a.nr_sequencia = :new.nr_sequencia
        and a.cd_material = :new.cd_material
        and e.dt_baixa is null
        and a.nr_sequencia = d.nr_seq_marca
        and exists (select 1
                    from oc_item_entrega f
                    where trunc(f.dt_prevista_entrega) > sysdate
                        and d.nr_ordem_compra = f.nr_ordem_compra
                        and d.nr_item_oci = f.nr_item_oci);

--verifica se há OC pendente de entrega
    if (v_quant > 0) then

--consulta informações do material
        select
            distinct
            a.nr_sequencia,
            b.cd_material,
            b.ds_material,
            c.ds_marca,
            a.cd_referencia
        into
            v_nr_sequencia,
            v_cd_material,
            v_ds_material,
            v_ds_marca,
            v_cd_referencia
        from mat_marca a
            inner join material b
                on a.cd_material = b.cd_material
            inner join marca c
                on a.nr_sequencia = c.nr_sequencia
            left join oc_item d
                on b.cd_material = d.cd_material
            left join ord_compra e
                on d.nr_ordem_compra = e.nr_ordem_compra
        where a.nr_sequencia = :new.nr_sequencia
            and a.cd_material = :new.cd_material
            and e.dt_baixa is null
            and a.nr_sequencia = d.nr_seq_marca
            and exists (select 1
                        from oc_item_entrega f
                        where trunc(f.dt_prevista_entrega) > sysdate
                            and d.nr_ordem_compra = f.nr_ordem_compra
                            and d.nr_item_oci = f.nr_item_oci);

--Armazenamento do número de todas as OCs na variavel
        open c01;
        loop
            fetch c01 into v_nr_ordem_compra;
            exit when c01%notfound;

            if v_contador = 1 then
                v_nr_ordem_compra2 := v_nr_ordem_compra||' '||v_nr_ordem_compra2;
            else
                v_nr_ordem_compra2 := v_nr_ordem_compra||'; '||v_nr_ordem_compra2;
            end if;

            v_contador := v_contador + 1;

        end loop;
        close c01;

--registro do compilado das informações para disparo do e-mail
        insert into registro_email(nr_sequencia, dt_registro, ds_titulo, ds_nome_remetente, ds_email_destino, 
                ds_body_email, dt_agendamento, dt_envio, nr_atendimento, ie_erro_envio, ds_erro_envio, cd_pessoa_fisica)
        values(registro_email_seq.nextval, sysdate, 'Alerta: MARCA REPROVADA!',
            'Remetente', 'nome_destinatario@dominio.com.br',
            chr(10)||'Prezados!'
            ||chr(10)||' Foi REPROVADA a marca: '||v_ds_marca||' (referência: '||v_cd_referencia||') '
            ||' do material: '||v_cd_material||' - '||v_ds_material
            ||chr(10)||' Há no sistema as seguintes OC(s) pendentes de entrega, para deste material: '||v_nr_ordem_compra2,
            null, null, null, null, null, null);

    end if;

end if;

end;
/
