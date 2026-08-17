Este diretório contém o script de uma trigger, em linguagem PL/SQL (linguagem procedural Oracle), esta realiza auditoria das operações executadas na tabela IDENT_VISITA_ESTABELECIMENTO. 

O objeto é acionado automaticamente após operações de INSERT, UPDATE ou DELETE, identificando o tipo de evento ocorrido.

E a cada acionamento, é registrado na tabela LOG_AUDITORIA_TBL a data e hora da operação, o evento realizado, o usuário responsável, o nome do objeto e o call stack (pilha de chamadas) da execução. 

Dessa forma, o trigger auxilia no rastreamento, auditoria e diagnóstico das alterações realizadas na tabela.

Também há neste diretório o script da tabela LOG_AUDITORIA_TBL.


---


This directory contains the script for a trigger, written in PL/SQL (Oracle procedural language), that audits operations performed on the IDENT_VISITA_ESTABELECIMENTO table.

The object is automatically triggered after INSERT, UPDATE, or DELETE operations, identifying the type of event that occurred.

Each time it is triggered, the data and time of the operation, the event performed, the responsible user, the object name, and the call stack of the execution are recorded in the LOG_AUDITORIA_TBL table.

In this way, the trigger assists in tracking, auditing, and diagnosing changes made to the table.

The script for the LOG_AUDITORIA_TBL table is also included in this directory.