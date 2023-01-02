create or replace trigger trg_bloqueio_atualizacao_delete
before delete or update
on nm_tabela

begin

--se usuário tentar deletar ou alterar o registro, mensagem será apresentada e a ação não será efetivada
    if deleting or updating then
        
        raise_application_error(-20011, 'Não é possível deletar/alterar o registro! Caso necessário favor acionar a TI.');
        
    end if;

end;
/