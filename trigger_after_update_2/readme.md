## Explicação em Português

Este diretório contém o script (código) de uma trigger (gatilho), em linguagem PL/SQL (linguagem procedural Oracle que estende a linguagem SQL.

Trigger é um objeto do banco de dados Oracle que executa uma ação quando se executada um comando DML (SELEC, INSERT ou UPDATE) sobre o registro de alguma tabela.

No caso da trigger deste diretório, esta será acionada após a aplicação de um UPDATE sobre um registro da tabela CAD_PESSOA.

  No corpo da trigger verifico se o campo DT_OBITO foi preenchido;
  Depois realizo algumas validações, como se o cliente não possui ficha de atendimento aberta e se o usuário tem permissão de registrar a data de óbito;
  Se uma desta duas validações forem falsas apresento uma mensagem para o usuário. E a aplicação do UPDATE será desfeito;
  Mas se forem verdadeiras executo um INSERT outra tabela e faço a execução de uma PROCEDURE.



## Explanation in English

This directory contains the script (code) of a trigger, in PL/SQL language (Oracle procedural language that extends the SQL language.

Trigger is an Oracle database object that performs an action when a DML command (SELEC, INSERT or UPDATE) is executed on a record in a table.

In the case of the trigger for this directory, it will be activated after applying an UPDATE to a record in the CAD_PESSOA table.

 In the body of the trigger, I check whether the DT_OBITO field has been filled in;
 Then I carry out some validations, such as whether the client does not have an open service record and whether the user is allowed to record the date of death;
 If one of these two validations is false, I will display a message to the user. And the UPDATE application will be undone;
 But if they are true, I execute an INSERT on another table and execute a PROCEDURE.
