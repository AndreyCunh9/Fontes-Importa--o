# Fontes Importação — Integração Fiscal Grupo Ginseng x Grupo Boticário

Conjunto de fontes em **AdvPL/TLPP**, customizações do ERP TOTVS Protheus, responsáveis pela integração automática de documentos fiscais (NF-e e NFC-e) entre a plataforma do Grupo Boticário e o Protheus do Grupo Ginseng, com posterior geração de Pedido de Venda/Orçamento, faturamento e baixa financeira.

## Fluxo geral

1. **[ULOJE003.tlpp](ULOJE003.tlpp)** solicita à API do Boticário a geração de um pacote ZIP com os XMLs fiscais do período, aguarda o processamento (*polling*) e extrai os arquivos em `\fiscal_xmls\<data>\`.
2. **[ULOJE001.tlpp](ULOJE001.tlpp)** consulta a API do Boticário (NF-e e NFC-e), localiza o XML correspondente em disco, enriquece com dados financeiros (via ULOJE004) e grava/atualiza o registro na tabela customizada `ZKD`.
3. **[ULOJE004.tlpp](ULOJE004.tlpp)** busca em cascata, em APIs internas do Grupo Ginseng, os dados financeiros (parcelas, vencimento, descontos) associados ao pagamento da venda.
4. **[ULOJE002.tlpp](ULOJE002.tlpp)** processa os registros pendentes da tabela `ZKD`, montando Pedido de Venda (NF-e) ou Orçamento de PDV (NFC-e) no Protheus.
5. **[M410STTS.prw](M410STTS.prw)** é acionado após a gravação do pedido, gera a Nota Fiscal automaticamente, atualiza o vencimento do título e realiza a baixa financeira.
6. **[ULOJA001.prw](ULOJA001.prw)** fornece a tela de manutenção (browse/CRUD) da tabela `ZKD`, para acompanhamento e correção manual dos registros de integração.

## Descrição dos arquivos

### [M410STTS.prw](M410STTS.prw)
Ponto de entrada do módulo de Faturamento (MATA410), executado após a gravação de um pedido de venda.
- Verifica se o pedido veio de um job de integração automática (`U_PROCESSAINTEGRACAO`) e se está liberado (`C5_LIBEROK`).
- Dispara o job assíncrono `JFatAuto`, que localiza os itens liberados (SC9), gera a Nota Fiscal via `MaPvlNfs` e, em caso de sucesso, atualiza o vencimento do título a receber (`JVencto`) e realiza a baixa automática (`JBaxAuto`).
- Atualiza o status do registro em `ZKD` para `P` (Processado) ao final.

### [ULOJA001.prw](ULOJA001.prw)
Tela de manutenção MVC da tabela `ZKD` ("Integração NFE e NFCe Protheus"), com opções de Visualizar e Alterar e legendas por status:
- `R` (amarelo) — Recebido
- `E` (vermelho) — Erro
- `P` (verde) — Processado

### [ULOJE001.tlpp](ULOJE001.tlpp)
Consulta a API do Grupo Boticário (endpoints de NF-e e NFC-e), autentica-se via OAuth *client credentials* e grava os documentos retornados na tabela `ZKD`.
- `GETTOKENBOT` — obtém o token JWT de autenticação.
- `GravaZKD` — grava/atualiza o registro, localizando o XML em disco, o CNPJ/CPF do destinatário e campos complementares do documento: `ZKD_STXML` (status), `ZKD_CANAL` (canal de venda) e `ZKD_FPAG` (forma de pagamento) — com origem diferente no JSON conforme o tipo do documento:
  - **NFC-e**: `invoiceXMLStatus`, `channelDescription` e `paymentMethodDescription` (primeira ocorrência do array `payments`).
  - **NF-e**: `situation`, `importType` e `paymentCondition` (payload de `invoices` não possui os campos acima).
- `retXml` — localiza o XML da chave em disco, procurando nas subpastas `saida` (NFC-e) e `importacao` (NF-e) dentro da pasta do CNPJ/data.
- `retView` — busca a view financeira do documento via `ULOJE004`, priorizando a identificação de vendas do canal site (`ExtraiIdSite`, que extrai o identificador do OMNI embutido no campo `observation` da NF-e, ex. `"...Pedido Site 157128693BOT-F1..."`) antes de cair no fluxo padrão de busca por `orderNumber`.
- `filDestino` — mapeia o `storeId` da API para a filial correspondente no Protheus (via tabela auxiliar SX5/ZX).
- `GravaSX5ZX` — carga inicial da tabela de correlação loja ↔ CNPJ (lojas ativas e baixadas nos estados de Alagoas, Sergipe e Bahia).
- `JLOJE001` — job que percorre um intervalo de datas retroativo até a data atual.

### [ULOJE002.tlpp](ULOJE002.tlpp)
Processa os registros pendentes ("Recebido") da tabela `ZKD`, interpretando o JSON/XML armazenado.
- **NF-e**: monta cabeçalho e itens de Pedido de Venda (SC5/SC6) e dispara `MSExecAuto` da rotina MATA410.
- **NFC-e**: monta itens, forma de pagamento e cabeçalho de Orçamento de PDV (SL1/SL2/SL4), gravado via `Lj7GrvOrc`.
- Identifica forma de pagamento e administradora financeira (tabelas SZE/SAE) e calcula descontos.
- Atualiza o status do registro (`P` processado ou `E` erro, com histórico detalhado).

### [ULOJE003.tlpp](ULOJE003.tlpp)
Solicita a geração e realiza o download dos XMLs fiscais junto à API do Boticário.
- `ReqDocZip` — solicita (POST) a geração do pacote ZIP para um intervalo de datas.
- `ChkDocZip` — realiza *polling* de status por até 2 horas (a resposta da API varia de 15 min a 2h), aguardando o status `FINISHED`.
- `ProcDocZip` — baixa o ZIP e extrai os XMLs em `\fiscal_xmls\<data>\` via `FUnZip`.
- `JLOJE003` — job que percorre um intervalo de datas retroativo até a data atual.

### [ULOJE004.tlpp](ULOJE004.tlpp)
Busca em cascata, em diferentes APIs internas do Grupo Ginseng (`api.grupoginseng.com.br`), os dados financeiros do pagamento associado a um pedido/autorização.
- Percorre os endpoints Pedidos, Rede, Mooz, Mulvipay, Omni e Pagarme até localizar o dado correspondente.
- `NormalizarData` — converte o formato específico de cada API em um objeto JSON único, com parcelas, vencimento e percentual de desconto. **Atenção:** apenas as origens Pedidos, Mooz e Omni possuem normalização implementada; Rede, Mulvipay e Pagarme ainda não têm tratamento (ver observação técnica abaixo).

## Observação técnica — Origens de pagamento sem normalização implementada

Na busca em cascata do [ULOJE004.tlpp](ULOJE004.tlpp), as origens **REDE**, **MULVIPAY** e **PAGARME** não possuem tratamento implementado em `NormalizarData` (apenas comentários `// Implementar lógica`). Quando a venda foi processada por uma dessas administradoras, a função retorna um objeto financeiro com valores zerados/vazios, sem sinalizar erro — o que pode gerar inconsistência silenciosa na condição de pagamento e forma de pagamento geradas pelo [ULOJE002.tlpp](ULOJE002.tlpp). Recomenda-se priorizar a implementação dessas três origens.

## Observação técnica — Credenciais expostas

Os arquivos [ULOJE001.tlpp:139-140](ULOJE001.tlpp#L139-L140) e [ULOJE004.tlpp:11](ULOJE004.tlpp#L11) contêm credenciais sensíveis diretamente no código-fonte (client_id, client_secret e token JWT), utilizadas como valores *default* de `SuperGetMv`. Recomenda-se:
- Mover esses valores para os parâmetros de configuração (SX6), sem valor default no código;
- Revogar e rotacionar as credenciais expostas, caso este código já tenha sido versionado em repositório compartilhado.
