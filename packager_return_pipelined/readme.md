Neste diretório contem o script de um objeto de banco de dados (packager) escrito na linguagem PL/SQL. Linguagem procedural do SGBD Oracle.

O pacote implementa uma função pipelined para retorno estruturado de informações de agendamentos. A função consolida dados por local e data, calculando dinamicamente o status do agendamento conforme regras de negócio (situação da agenda, existência de atendimento e comparação com a data atual), além de somar a duração total em minutos.

A implementação utiliza cursores para processar dois cenários: (1) horários efetivamente agendados, retornando duração consolidada por status, e (2) identificação de intervalos disponíveis, calculando o tempo restante do turno com base na diferença entre horário inicial e final menos o tempo já ocupado. Quando há saldo de tempo, o pacote retorna registros adicionais classificados como “Horário vago”.

O uso de função pipelined permite que os dados sejam consumidos diretamente em consultas SQL, oferecendo melhor integração com relatórios, views e ferramentas analíticas. A estrutura com tipos RECORD e TABLE garante organização, reutilização e performance no processamento de dados de agenda.


---------------------------------


This directory contains the script for a database object (packager) written in PL/SQL, the procedural language of the Oracle DBMS.

The package implements a pipelined function for structured return of scheduling information. The function consolidates data by location and date, dynamically calculating the scheduling status according to business rules (scheduled status, availability of appointments, and comparison with the current date), in addition to summing the total duration in minutes.

The implementation uses cursors to process two scenarios: (1) effectively scheduled times, returning consolidated duration by status, and (2) identification of available time slots, calculating the remaining shift time based on the difference between the start and end times minus the time already occupied. When there is a time balance, the package returns additional records classified as "Vacant Time".

The use of a pipelined function allows the data to be consumed directly in SQL queries, offering better integration with reports, views, and analytical tools. The structure using RECORD and TABLE data types ensures organization, reusability, and performance in processing calendar data.
