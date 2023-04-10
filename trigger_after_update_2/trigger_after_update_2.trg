create or replace trigger cad_pessoa_trg
after update on cad_pessoa
for each row

/*************************************************************
-------------------------------------------------------------
Descricao: objeto criado disparar alerta de e-mail, apos
preenchido o campo data obito no cadastro do cliente.
------------------------------------------------------------
------------------------------------------------------------
--Obs.: trigger impedira do usuário registrar obito
(preenchendo campo obito do cadastro do cliente) se o 
usuário não estiver permissao.
-----------------------------------------------------------
--Criada por: Diego Lima - Data: 2017
-----------------------------------------------------------
**************************************************************/

disable

declare
    v_quant number(9);
    ds_msg_w varchar2(4000) := null;
    v_permissao_lib varchar2(1);

begin

    if (:new.dt_obito is not null and :old.dt_obito is null) then
        
            select
                nvl2(max(a.nr_sequencia),'S','N')
            into
                v_permissao_lib
            from tp_alerta_atend a
            where exists (select 1
                        from tp_alerta_atend_lib b
                        where a.nr_sequencia = b.nr_seq_tipo_alerta
                            and b.ie_cadastro = 'S'
                            and b.cd_perfil = obter_permissao_atual_func)
                and a.nr_sequencia = 12;
           
        if (v_permissao_lib = 'S') then
        
            select
                count(1) quant
            into
                v_quant
            from atendimento_cliente a
            where a.cd_pessoa = :new.cd_pessoa
                and a.dt_cancelamento is null
                and a.ie_tipo_atendimento = 1
                and a.dt_alta is null
                and exists (select 1
                            from atend_cliente_unidade b
                                inner join setor c
                                    on b.cd_setor = c.cd_setor
                                    and cd_classif_setor in (1,3)
                            where a.nr_atendimento = b.nr_atendimento);

            if v_quant = 0 then
            
                insert into alerta_cliente(nr_sequencia,
                    cd_und_estab,
                    cd_pessoa,
                    dt_alerta,
                    dt_atualizacao,
                    nm_usuario,
                    ie_situacao,
                    dt_liberacao,
                    ds_alerta,
                    cd_perfil_ativo,
                    nr_seq_tipo_alerta)
                values (alerta_paciente_seq.nextval,
                    wheb_usuario_pck.get_cd_und_estab,
                    :new.cd_pessoa,
                    sysdate,
                    sysdate,
                    :new.nm_usuario,
                    'A',
                    sysdate,
                    'Óbito ocorrido em: '||:new.dt_obito,
                    obter_permissao_atual_func,
                    12);

                    begin

                        envio_alerta_prc('Alerta: obito',chr(13)||'Foi atribuido obito para o cliente'||chr(13)||'RGHC: '||:new.nr_registro||chr(13)||'Paciente: '||:new.nm_pessoa||chr(13)||'Dta. de Nasc.: '||:new.dt_nascimento||chr(13),'usuario-alertado@servidor.com.br',null,'A',null);
                        
                        exception
                            when others then

                            null;

                    end;

            else

                raise_application_error(-509811, 'Cliente com ficha em aberto.');

            end if;
            
        else
            
            raise_application_error(-509811, 'Usuário sem permissão.');
    
        end if;
        
    end if;
    
end;
/
