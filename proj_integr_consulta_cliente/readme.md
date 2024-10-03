# Explicação em Português

Este diretório contém objetos de banco de dados, desenvolvidos em SQL e PL/SQL (linguagem procedural do Oracle que estende a linguagem SQL).

Os objetos são responsáveis pelo tratamento de dados da integração de sistemas (Agendamento e Sistema de Informação Hospitalar).

O funcionamento desta integração e relativamente simples. Uma API inseri nas tabelas intermediarias ("TRG_TRANSF_CONSULTA", "TBL_CANCEL_CONSULTA", e "TBL_TRANSF_CONSULTA") as informações do sistema de origem. E as triggers tratam e imputam as informações para as tabelas do sistema de destino.

Os códigos estão todos comentados e ordenados.

---

# Explanation in English

This directory contains database objects, developed in SQL and PL/SQL (Oracle's procedural language that extends the SQL language).

The objects are responsible for processing data from the system integration (Scheduling and Hospital Information System).

The operation of this integration is relatively simple. An API inserts the information from the source system into the intermediate tables ("TRG_TRANSF_CONSULTA", "TBL_CANCEL_CONSULTA", and "TBL_TRANSF_CONSULTA"). And the triggers process and input the information to the tables of the target system.

The codes are all commented and ordered.
