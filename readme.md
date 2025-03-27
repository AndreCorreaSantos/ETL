## Requisitos do Projeto

- [X] 1 O projeto precisa ser feito em OCaml.
- [X] 2 Para calcular a saída, é necessário utilizar `map`, `reduce` e `filter`.
- [X] 3 O código deve conter funções para leitura e escrita de arquivos CSV. Isso gerará funções impuras.
- [X] 4 Separar as funções impuras das funções puras nos arquivos do projeto.
- [X] 5 A entrada precisa ser carregada em uma estrutura de lista de `Record`.
- [X] 6 É obrigatório o uso de `Helper Functions` para carregar os campos em um `Record`.
- [ ] 7 É necessário escrever um relatório do projeto, indicando como as etapas foram construídas. Isso é semelhante a um roteiro para alguém que iria refazer o projeto no futuro. Você deve declarar o uso ou não de IA Generativa nesse relatório.

## Requisitos Opcionais

- [X] 1 Ler os dados de entrada em um arquivo estático na internet (exposto via http).
- [X] 2 Salvar os dados de saída em um Banco de Dados SQLite.
- [X] 3 É possível fazer o tratamento das tabelas de entrada em separado. Mas é desejável realizar o tratamento dos dados conjuntamente via operação de `inner join`. Ou seja, juntar as tabelas antes de iniciar a etapa de `Transform`.
- [X] 4 Organizar o projeto ETL utilizando `dune`.
- [X] 5 Documentar todas as funções geradas via formato `docstring`.
- [ ] 6 Realizar uma saída adicional que contém a média de receita e impostos pagos agrupados por mês e ano. --> GROUP BY INT_RESULT USING MONTH-YEAR.
- [ ] 7 Gerar arquivos de testes completos para as funções puras.
