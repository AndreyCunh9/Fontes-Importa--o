#Include 'Protheus.ch'

/*/{Protheus.doc} M410STTS
Ponto de entrada após gravação do pedido.
/*/
User Function M410STTS()
    Local lJobUNFE := IsInCallStack("U_PROCESSAINTEGRACAO")
    Local aParms   := {}
    Local _nOper := PARAMIXB[1]

    // Valida se veio da medição e se o pedido está liberado (C5_LIBEROK)
    If lJobUNFE .And. _nOper == 3
        
        // Passamos Empresa, Filial e Número do Pedido para o Job
        aParms := { cEmpAnt, cFilAnt, SC5->C5_NUM, cHVF2DOC, cHVF2SERIE, nRecnoZKD }
        
        StartJob("U_JFatAuto", GetEnvServer(), .F., aParms)
        
        ConOut("[M410STTS] Job de faturamento disparado para o pedido: " + SC5->C5_NUM)
    EndIf
Return

/*/{Protheus.doc} JFatAuto
Função de background baseada no exemplo oficial TOTVS (MaPvlNfs).
/*/
User Function JFatAuto(aParms)
    Local cEmpJob    := aParms[1]
    Local cFilJob    := aParms[2]
    Local cC5Num     := aParms[3]
    Local cDoc       := aParms[4]
    Local cSerie     := aParms[5]
    Local nRecnoZKD  := aParms[6]
    Local aPvlDocS   := {}
    Local nPrcVen    := 0
    Local cEmbExp    := ""
    Local lMostraCtb
	Local lAglutCtb
	Local lCtbOnLine
	Local lCtbCusto
	Local lReajuste
    
    // 1. Prepara o ambiente para a Thread (Conforme RpcSetEnv para Jobs)
    RpcSetEnv(cEmpJob, cFilJob)

    SetFunName("MATA460") 
    
    ConOut("[M410STTS] Iniciando processamento MaPvlNfs para o pedido: " + cC5Num)

    // Posiciona no Cabeçalho do Pedido
    If PosicionaPedido(cFilJob,cC5Num)

        // É necessário carregar o grupo de perguntas MT460A (Padrão TOTVS)
        Pergunte("MT460A", .F.)

        // Posiciona no pedido
        SC5->(dbSetOrder(1))
        SC5->(MsSeek(cFilJob + cC5Num))
       
        // Posiciona nos itens
        SC6->(dbSetOrder(1))
        SC6->(MsSeek(cFilJob + cC5Num))

        dbSelectArea("SE4")
        SE4->(DbSetOrder(1))

        dbSelectArea("SB1")
        SB1->(DbSetOrder(1))

        dbSelectArea("SB2")
        SB2->(DbSetOrder(1))

        dbSelectArea("SF4")
        SF4->(DbSetOrder(1))
        // Posiciona no Json processado para atualizar o status do título
        ZKD->(DbGoTo(nRecnoZKD))

        // 2. Coleta os itens liberados (SC9) para compor a nota
        While !SC6->(Eof()) .And. SC6->C6_FILIAL == cFilJob .And. SC6->C6_NUM == cC5Num

            SC9->(DbSetOrder(1))
            // Busca liberação por Filial + Pedido + Item
            If SC9->(MsSeek(cFilJob + SC6->C6_NUM + SC6->C6_ITEM))
                
                While !SC9->(Eof()) .And. SC9->C9_FILIAL == cFilJob .And. SC9->C9_PEDIDO == SC6->C6_NUM .And. SC9->C9_ITEM == SC6->C6_ITEM
                    SE4->(DbSeek(xFilial("SE4")+SC5->C5_CONDPAG))               //CONDICAO DE PGTO
					SB1->(DbSeek(xFilial("SB1")+SC6->C6_PRODUTO))               //FILIAL+PRODUTO
					SB2->(DbSeek(xFilial("SB2")+SC6->C6_PRODUTO+SC6->C6_LOCAL)) //FILIAL+PRODUTO+LOCAL
					SF4->(DbSeek(xFilial("SF4")+SC6->C6_TES))                   //FILIAL+CODIGO
                    // Verifica se o item não está bloqueado por estoque ou crédito
                    If Empty(SC9->C9_BLEST) .And. Empty(SC9->C9_BLCRED)
                        
                        nPrcVen := SC9->C9_PRCVEN
                        If SC5->C5_MOEDA <> 1
                            nPrcVen := xMoeda(nPrcVen, SC5->C5_MOEDA, 1, dDataBase)
                        EndIf

                        // Alimenta o array conforme o exemplo da TOTVS
                        AAdd(aPvlDocS, { SC9->C9_PEDIDO,;
                                        SC9->C9_ITEM,;
                                        SC9->C9_SEQUEN,;
                                        SC9->C9_QTDLIB,;
                                        nPrcVen,;
                                        SC9->C9_PRODUTO,;
                                        .F.,;
                                        SC9->(RecNo()),;
                                        SC5->(RecNo()),;
                                        SC6->(RecNo()),;
                                        SE4->(RecNo()),; // SE4 Recno (Pode buscar se necessário)
                                        SB1->(RecNo()),; // SB1 Recno
                                        SB2->(RecNo()),; // SB2 Recno
                                        SF4->(RecNo()) }) // SF4 Recno
                        // Nota: MaPvlNfs aceita os RecNos. Se passar 0 ele tenta posicionar internamente.
                    EndIf
                    SC9->(DbSkip())
                EndDo
            EndIf
            SC6->(DbSkip())
        EndDo
        // Ajusta a numeracao da nota
        If FwPutSx5(,"01",cSerie,cDoc,cDoc,cDoc)
            // 3. Execução da MaPvlNfs (Geração da Nota)
            If !Empty(aPvlDocS)
                SetFunName("MATA461")
                // Reseta o cDoc para receber o número gerado pela função e assim saber que gerou a nota
                cDoc := ""
                // Teste para forçar a geração de título
                Pergunte("MT460A",.F.)
                MV_PAR01 := 2           // Mostra Lan‡.Contab ?  Sim/Nao
                MV_PAR02 := 2           // Aglut. Lan‡amentos ?  Sim/Nao
                MV_PAR03 := 2           // Lan‡.Contab.On-Line?  Sim/Nao
                MV_PAR04 := 2           // Contb.Custo On-Line?  Sim/Nao
                MV_PAR05 := 2           // Reaj. na mesma N.F.?  Sim/Nao
                MV_PAR06 := 0           // Taxa deflacao ICMS ?  Numerico
                MV_PAR07 := 3           // Metodo calc.acr.fin?  Taxa defl/Dif.lista/% Acrs.ped
                MV_PAR08 := 3           // Arred.prc unit vist?  Sempre/Nunca/Consumid.final
                MV_PAR09 := Space(04)   // Agreg. liberac. de ?  Caracter
                MV_PAR10 := Space(04)   // Agreg. liberac. ate?  Caracter
                MV_PAR11 := 2           // Aglut.Ped. Iguais  ?  Sim/Nao
                MV_PAR12 := 0           // Valor Minimo p/fatu?
                MV_PAR13 := Space(06)   // Transportadora de  ?
                MV_PAR14 := "ZZZZZZ"    // Transportadora ate ?
                MV_PAR15 := 2           // Atualiza Cli.X Prod?  Sim/Nao
                MV_PAR16 := 1           // Emitir             ?  Nota/Cupom Fiscal
                MV_PAR17 := 1
                MV_PAR18 := 2
                MV_PAR19 := 2		//GERA TITULO ICMS PROPRIO
                MV_PAR20 := 2
                MV_PAR21 := dDatabase
                MV_PAR22 := 2
                MV_PAR23 := 2
                MV_PAR24 := 1		//GERA PARA O DESTINO
                MV_PAR25 := 1		//GERA FECOEP

                lMostraCtb  := MV_PAR01 == 1
                lAglutCtb   := MV_PAR02 == 1
                lCtbOnLine  := MV_PAR03 == 1
                lCtbCusto   := MV_PAR04 == 1
                lReajuste   := MV_PAR05 == 1

                cDoc := MaPvlNfs( aPvlDocS,;    // 01 - Itens
                                cSerie,;      // 02 - Serie
                                lMostraCtb,;         // 03 - Mostra Contabilização
                                lAglutCtb,;         // 04 - Aglutina Contab
                                lCtbOnLine,;         // 05 - Contab On-line
                                lCtbCusto,;         // 06 - Contab Custo
                                lReajuste,;         // 07 - Reajuste
                                0,;           // 08 - Acrescimo
                                0,;           // 09 - Arredondamento
                                .F.,;         // 10 - Atu SA7
                                .F.,;         // 11 - ECF
                                cEmbExp,;     // 12 - Embarque
                                {||},;        // 13 - bAtuFin
                                {||},;        // 14 - bAtuPGerNF
                                {||},;        // 15 - bAtuPvl
                                {|| .T. },;   // 16 - bFatSE1
                                dDatabase,;   // 17 - Data Moeda
                                .F.,)         // 18 - Aglutina Pedidos

                If !Empty(cDoc)
                    ConOut("[M410STTS] SUCESSO: NF " + cDoc + " gerada. Aguardando persistencia no banco...")                    
                    // Tenta localizar a nota por até 5 segundos antes de transmitir
                    If ValidaGravacao(cDoc, cSerie)
                        ConOut("[M410STTS] NF " + cDoc + " localizada.")
                        If ZKD->(Recno()) == nRecnoZKD
                            // Atualiza o vencimento do título a receber para a data atual
                            U_JVencto()
                            // Realizando a baixa do título a receber
                            U_JBaxAuto()
                            If RecLock('ZKD',.F.)
                                ZKD->ZKD_STATUS := "P"
                                ZKD->ZKD_HIST := AllTrim(ZKD->ZKD_HIST)  +Chr(13) + Chr(10)+"--------"+DTOC(Date())+" "+SubStr(Time(),1,8)+"--------"+Chr(13) + Chr(10)+" NF: " + SC5->C5_NOTA + " SERIE: " + cSerie + " integrado com sucesso."+Chr(13) + Chr(10)
                                ZKD->(MsUnlock())
                            EndIf
                        EndIf
                    Else
                        ConOut("[M410STTS] ERRO: NF " + cDoc + " gerada mas nao encontrada no banco apos 5s.")
                    EndIf
                Else
                    ConOut("[M410STTS] FALHA: A funcao MaPvlNfs nao retornou numero de documento.")
                EndIf
            Else
                ConOut("[M410STTS] NADA A FATURAR: Pedido " + cC5Num + " nao possui itens liberados/sem bloqueio.")
            EndIf
        EndIf
    EndIf

Return

/*/{Protheus.doc} ValidaGravacao
Verifica se o pedido foi criado
/*/
Static Function PosicionaPedido(cFilJob,cC5Num)
    Local nTentativa    := 0
    Local nMax          := 15 // Limite de 5 segundos
    Local lRet          := .F.

    SC5->(DbSetOrder(1))

    While nTentativa < nMax

        If SC5->(MsSeek(cFilJob + cC5Num))
            ConOut("[M410STTS] Pedido encontrado: " + cC5Num)
            lRet := .T.
            exit
        EndIf

        nTentativa++
        Sleep(1000) // Espera 1 segundo para a próxima tentativa
        ConOut("[M410STTS] Aguardando gravacao do Pedido " + cC5Num + "... (" + cValToChar(nTentativa) + "s)")
    EndDo
Return lRet

/*/{Protheus.doc} ValidaGravacao
Espera a nota aparecer fisicamente na SF2 antes de prosseguir
/*/
Static Function ValidaGravacao(cDoc, cSerie)
    Local lRet      := .F.
    Local nTentativa := 0
    Local nMax      := 5 // Limite de 5 segundos

    While nTentativa < nMax
        // Força o Refresh do buffer da tabela para o banco de dados
        // SF2->(dbSkip(0)) 
        
        SF2->(DbSetOrder(1)) // F2_FILIAL + F2_DOC + F2_SERIE
        If SF2->(MsSeek(xFilial("SF2") + cDoc + cSerie))
            lRet := .T.
            Exit
        EndIf
        
        nTentativa++
        Sleep(1000) // Espera 1 segundo para a próxima tentativa
        ConOut("[M410STTS] Aguardando gravacao da NF " + cDoc + "... (" + cValToChar(nTentativa) + "s)")
    EndDo

Return lRet

/*/
Atualiza vencimento
/*/
User Function JVencto()  
    Local cAliasSE1     := GetNextAlias()
    Local oJsonView     := JsonObject():New()
    Local cErro         := ""
    Local nParcela      := 0
    Private lMsErroAuto := .F.

    cErro := oJsonView:FromJson(ZKD->ZKD_VIEW)

    If Empty(cErro)
        BeginSql alias cAliasSE1
            SELECT 
                SE1.* FROM 
                %table:SE1% SE1 
            WHERE 
                E1_FILIAL = %exp:SF2->F2_FILIAL% AND 
                E1_NUM = %exp:SF2->F2_DOC% AND 
                E1_PREFIXO = %exp:SF2->F2_SERIE% AND 
                E1_CLIENTE = %exp:SF2->F2_CLIENTE% AND 
                E1_LOJA = %exp:SF2->F2_LOJA% AND 
                %notDel%
            Order By E1_PARCELA
        EndSql
        
        While (cAliasSE1)->(!Eof())
            SE1->(DbGoTo((cAliasSE1)->R_E_C_N_O_))
            If SE1->(Recno()) == (cAliasSE1)->R_E_C_N_O_
                nParcela++
                If Len(oJsonView["financeiro"]) >= nParcela
                    If RecLock('SE1',.F.)
                        SE1->E1_VENCTO  := Stod(StrTran(oJsonView["financeiro"][nParcela]["vencimento"], "/", ""))
                        SE1->E1_VENCREA := Stod(StrTran(oJsonView["financeiro"][nParcela]["vencimento"], "/", ""))
                        SE1->E1_XDESCPG := oJsonView["financeiro"][nParcela]["descricao_pagamento"]
                        SE1->(MsUnlock())
                    EndIf
                EndIf
            EndIf
            
            (cAliasSE1)->(DbSkip())
        EndDo  
        (cAliasSE1)->(DbCloseArea())
    EndIf
Return

/*/
Baixa do titulo a receber
/*/
User Function JBaxAuto()  
    Local aBaixa        := {}
    Local cAliasSE1     := GetNextAlias()
    Local cDescPgto     := SuperGetMv("HV_DESCPG",,"PIX_COBRANCA/")
    Private lMsErroAuto := .F.

    BeginSql alias cAliasSE1
        SELECT 
            SE1.* FROM 
            %table:SE1% SE1 
        WHERE 
            E1_FILIAL = %exp:SF2->F2_FILIAL% AND 
            E1_NUM = %exp:SF2->F2_DOC% AND 
            E1_PREFIXO = %exp:SF2->F2_SERIE% AND 
            E1_CLIENTE = %exp:SF2->F2_CLIENTE% AND 
            E1_LOJA = %exp:SF2->F2_LOJA% AND 
            %notDel%
    EndSql
    
    While (cAliasSE1)->(!Eof())
        // Realiza a baixa apenas se a data de vencimento for menor ou igual a data atual para evitar baixa antecipada
        If Stod((cAliasSE1)->E1_VENCREA) <= dDataBase .and. AllTrim((cAliasSE1)->E1_XDESCPG) $ cDescPgto
            lMsErroAuto := .F.
            aBaixa := {{"E1_PREFIXO"  ,(cAliasSE1)->E1_PREFIXO      ,Nil    },;
                    {"E1_NUM"      ,(cAliasSE1)->E1_NUM             ,Nil    },;
                    {"E1_PARCELA"  ,(cAliasSE1)->E1_PARCELA         ,Nil    },;
                    {"E1_TIPO"     ,(cAliasSE1)->E1_TIPO            ,Nil    },;
                    {"AUTMOTBX"    ,"NOR"                           ,Nil    },;
                    {"AUTBANCO"    ,"CX1"                           ,Nil    },;
                    {"AUTAGENCIA"  ,"00001"                         ,Nil    },;
                    {"AUTCONTA"    ,"0000000001"                    ,Nil    },;
                    {"AUTDTBAIXA"  ,dDataBase                       ,Nil    },;
                    {"AUTDTCREDITO",dDataBase                       ,Nil    },;
                    {"AUTHIST"     ,"BAIXA TESTE"                   ,Nil    },;
                    {"AUTJUROS"    ,(cAliasSE1)->E1_JUROS           ,Nil,.T.},;
                    {"AUTVALREC"   ,(cAliasSE1)->E1_VALOR           ,Nil    }}
        
            MSExecAuto({|x,y| Fina070(x,y)},aBaixa,3)

            If lMsErroAuto
                ConOut("[JBaxAuto] Erro ao executar baixa automática para Título: " + (cAliasSE1)->E1_NUM + " Parcela: " + (cAliasSE1)->E1_PARCELA)
            Else
                ConOut("[JBaxAuto] Baixa automática realizada para Título: " + (cAliasSE1)->E1_NUM + " Parcela: " + (cAliasSE1)->E1_PARCELA)
            EndIf
        EndIf
        (cAliasSE1)->(DbSkip())
    EndDo  
    (cAliasSE1)->(DbCloseArea())
Return
