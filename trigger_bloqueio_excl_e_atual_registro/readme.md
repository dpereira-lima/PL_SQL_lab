Este diretório contém o script (código) de uma trigger (gatilho), em linguagem PL/SQL (linguagem procedural Oracle que estende a linguagem SQL).

A trigger é um objeto de banco de dados Oracle que executa uma ação quando é aplicado um comando DML (INSERT, DELETE ou UPDATE) sobre um registro de uma tabela.

No caso da trigger deste diretório, esta será acionada antes de aplicar o comando DELETE ou UPDATE nos registros da tabela NM_TABELA.

Se for aplicado um destes comandos a operação será abortada e a procedure do Oracle RAISE_APPLICATION_ERROR apresentará uma mensagem para o usuário.


---------------------------------------------------------------------------------------------------------


This directory contains the script (code) of a trigger, in PL/SQL language (Oracle procedural language that extends the SQL language).

A trigger is an Oracle database object that performs an action when a DML command (INSERT, DELETE or UPDATE) is applied to a record in a table.

In the case of the trigger for this directory, it will be activated before applying the DELETE or UPDATE command to the records in the NM_TABELA table.

If one of these commands is applied, the operation will be aborted and the Oracle RAISE_APPLICATION_ERROR procedure will present a message to the user.
