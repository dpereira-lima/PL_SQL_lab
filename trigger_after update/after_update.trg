create or replace trigger disparo_email
after update on nm_tabela

for each row
declare

--cursor dos pedidos com equipamento de marcar reprovada
cursor c01 is
    select
        e.nr_pedido
    from mat_marca a
        inner join mat b
            on a.cd_equipamento = b.cd_equipamento
        inner join marca c
            on a.nr_sequencia = c.nr_sequencia
        left join oc_item d
            on b.cd_equipamento = d.cd_equipamento
        left join pedido e
            on d.nr_pedido = e.nr_pedido
    where a.nr_sequencia = :new.nr_sequencia
        and a.cd_equipamento = :new.cd_equipamento
        and e.dt_baixa is null
        and a.nr_sequencia = d.nr_seq_marca
        and exists (select 1
                    from oc_item_entrega f
                    where trunc(f.dt_prevista_entrega) > sysdate
                        and d.nr_pedido = f.nr_pedido
                        and d.nr_item_oci = f.nr_item_oci);

v_quant number(9);
v_nr_pedido pedido.nr_pedido%type;
v_nr_pedido2 varchar2(99);
v_contador number(9);
v_cd_equipamento mat.ds_equipamento%type;
v_ds_equipamento mat.ds_equipamento%type;
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
        inner join equipamento b
            on a.cd_equipamento = b.cd_equipamento
        inner join marca c
            on a.nr_sequencia = c.nr_sequencia
        left join oc_item d
            on b.cd_equipamento = d.cd_equipamento
        left join pedido e
            on d.nr_pedido = e.nr_pedido
    where a.nr_sequencia = :new.nr_sequencia
        and a.cd_equipamento = :new.cd_equipamento
        and e.dt_baixa is null
        and a.nr_sequencia = d.nr_seq_marca
        and exists (select 1
                    from oc_item_entrega f
                    where trunc(f.dt_prevista_entrega) > sysdate
                        and d.nr_pedido = f.nr_pedido
                        and d.nr_item_oci = f.nr_item_oci);

--verifica se há OC pendente de entrega
    if (v_quant > 0) then

--consulta informações do equipamento
        select
            distinct
            a.nr_sequencia,
            b.cd_equipamento,
            b.ds_equipamento,
            c.ds_marca,
            a.cd_referencia
        into
            v_nr_sequencia,
            v_cd_equipamento,
            v_ds_equipamento,
            v_ds_marca,
            v_cd_referencia
        from mat_marca a
            inner join equipamento b
                on a.cd_equipamento = b.cd_equipamento
            inner join marca c
                on a.nr_sequencia = c.nr_sequencia
            left join oc_item d
                on b.cd_equipamento = d.cd_equipamento
            left join pedido e
                on d.nr_pedido = e.nr_pedido
        where a.nr_sequencia = :new.nr_sequencia
            and a.cd_equipamento = :new.cd_equipamento
            and e.dt_baixa is null
            and a.nr_sequencia = d.nr_seq_marca
            and exists (select 1
                        from oc_item_entrega f
                        where trunc(f.dt_prevista_entrega) > sysdate
                            and d.nr_pedido = f.nr_pedido
                            and d.nr_item_oci = f.nr_item_oci);

--Armazenamento do número de todas as OCs na variavel
        open c01;
        loop
            fetch c01 into v_nr_pedido;
            exit when c01%notfound;

            if v_contador = 1 then
                v_nr_pedido2 := v_nr_pedido||' '||v_nr_pedido2;
            else
                v_nr_pedido2 := v_nr_pedido||'; '||v_nr_pedido2;
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
            ||' do equipamento: '||v_cd_equipamento||' - '||v_ds_equipamento
            ||chr(10)||' Há no sistema as seguintes OC(s) pendentes de entrega, para deste equipamento: '||v_nr_pedido2,
            null, null, null, null, null, null);

    end if;

end if;

end;
/
