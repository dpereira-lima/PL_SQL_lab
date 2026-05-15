Este projeto reúne um conjunto de rotinas voltadas para a identificação, organização e tratamento de dados relacionados a pendências em atendimentos, com foco especial em exames e consultas pendentes. A proposta é consolidar informações dispersas por meio de um único SELECT:

\`\`\`SQL

select
    nr_registro,
    nm_cliente,
    dt_nasc,
    nr_ficha,
    ds_cid,
    ds_prim_setor,
    ds_setor_atual,
    ds_clinica,
    qt_dias_inter,
    qt_dias_prev_alta,
    ie_pedido_alta_med,
    ie_entrave_alta,
    ds_espec_med
from table(pkg_pipelined_dados_entrave_alta.cliente_internados);

\`\`\`

Ao centralizar e padronizar esses dados, a solução permite identificar entraves, atrasos e inconsistências de forma mais ágil, contribuindo para análises mais precisas e eficientes. Além disso, viabiliza a construção de dashboards a partir de uma única fonte de dados, simplificando o consumo das informações e apoiando a tomada de decisão.


---------------------------------------------------------------------------------------------------------


This project brings together a set of external routines for identifying, organizing, and processing data related to pending service requests, with a special focus on pending exams and consultations. The goal is to consolidate dispersed information through a single SELECT statement.

\`\`\`SQL

select
    nr_registro,
    nm_cliente,
    dt_nasc,
    nr_ficha,
    ds_cid,
    ds_prim_setor,
    ds_setor_atual,
    ds_clinica,
    qt_dias_inter,
    qt_dias_prev_alta,
    ie_pedido_alta_med,
    ie_entrave_alta,
    ds_espec_med
from table(pkg_pipelined_dados_entrave_alta.cliente_internados);

\`\`\`

By centralizing and standardizing this data, the solution allows for faster identification of obstacles, delays, and inconsistencies, contributing to more accurate and efficient analyses. Furthermore, it enables the creation of dashboards from a single data source, simplifying information consumption and supporting decision-making.