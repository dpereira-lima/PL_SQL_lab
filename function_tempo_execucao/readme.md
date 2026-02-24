Neste diretório contém o script de um objeto de banco de dados (function) escrito na linguagem PL/SQL. Linguagem procedural do SGBD Oracle.

Esta function é responsável por gerar mensagens descritivas sobre orientações de comparecimento e tempo de antecedência para diferentes tipos de agendamento. A lógica considera o tipo da agenda (Assistência, Prestação de Serviço, Cirúrgica, Exame ou Tratamento) e aplica regras específicas para determinar se o atendimento será presencial ou a distância.

A função consulta tabelas de cadastro e classificação para identificar o grupo do agendamento e, quando aplicável, define se o paciente deve apenas aguardar remotamente ou comparecer ao estabelecimento. Para atendimentos presenciais, o texto retornado é composto dinamicamente, incluindo endereço simplificado da unidade e o tempo de antecedência recomendado.

Em seu código possui mais duas funções que são criadas em tempo de execução: uma responsável por calcular o tempo de antecedência com base na classificação ou agrupamento da agenda, e outra que determina o endereço conforme o setor vinculado ao agendamento, tratando casos específicos como agendas de tratamento (ex.: quimioterapia).

O retorno é uma string formatada e pronta para exibição em sistemas, mensagens automáticas ou confirmações de agendamento, centralizando regras de negócio e padronizando a comunicação com o paciente.


-----------------------------------


This directory contains the script for a database object (function) written in PL/SQL, the procedural language of the Oracle DBMS.

This function is responsible for generating descriptive messages about attendance guidelines and advance arrival time for different types of appointments. The logic considers the appointment type (Assistance, Service Provision, Surgical, Examination, or Treatment) and applies specific rules to determine whether the appointment will be in person or remote.

The function queries registration and classification tables to identify the appointment group and, when applicable, determines whether the patient should only wait remotely or attend the facility. For in-person appointments, the returned text is dynamically composed, including a simplified address of the unit and the recommended advance arrival time.

Its code also includes two more functions that are created at runtime: one responsible for calculating the advance arrival time based on the appointment classification or grouping, and another that determines the address according to the sector linked to the appointment, handling specific cases such as treatment appointments (e.g., chemotherapy).

The response is a formatted string ready for display in systems, automated messages, or appointment confirmations, centralizing business rules and standardizing communication with the patient.
