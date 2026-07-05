#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} ULOJA001
// Função para criar a tela de integração NFE e NFCe Protheus
/*/
User Function ULOJA001()
Local oBrowse

oBrowse := FWmBrowse():New()
oBrowse:SetAlias( 'ZKD' )
oBrowse:SetDescription( 'Integração NFE e NFCe Protheus' )
// Adiciona as legendas do Browse
oBrowse:AddLegend("ZKD_STATUS == 'R'", "YELLOW", "Recebido")
oBrowse:AddLegend("ZKD_STATUS == 'E'", "RED", "Error")
oBrowse:AddLegend("ZKD_STATUS == 'P'", "GREEN", "Processado")
oBrowse:Activate()
Return NIL

//-------------------------------------------------------------------
Static Function MenuDef()
    Local aRotina := {}

    ADD OPTION aRotina Title 'Visualizar'  Action 'VIEWDEF.ULOJA001' OPERATION 2 ACCESS 0
    // ADD OPTION aRotina Title 'Incluir'     Action 'VIEWDEF.ULOJA001' OPERATION 3 ACCESS 0
    ADD OPTION aRotina Title 'Alterar'     Action 'VIEWDEF.ULOJA001' OPERATION 4 ACCESS 0
    // ADD OPTION aRotina Title 'Excluir'     Action 'VIEWDEF.ULOJA001' OPERATION 5 ACCESS 0
    // ADD OPTION aRotina Title 'Imprimir Integração bot Protheus'    Action 'u_UCOME003' OPERATION 8 ACCESS 0
Return aRotina

//-------------------------------------------------------------------
Static Function ModelDef()
    // Estrutura do Cabeçalho: Apenas o que identifica a conferência e o conferente
    Local oStruZKD := FWFormStruct( 1, 'ZKD')
    Local oModel

    // Cria o objeto do Modelo de Dados
    oModel := MPFormModel():New( 'ZKDMDL', /*bPreValidacao*/, /*{ | oMdlG | ZKDMDLPOS( oMdlG ) }*/, /*bCommit*/, /*bCancel*/ )

    // Adiciona ao modelo uma estrutura de formulário de edição por campo
    oModel:AddFields( 'ZKDMASTER', /*cOwner*/, oStruZKD )

    // Chave primaria
    oModel:SetPrimaryKey({ "ZKD_FILIAL", "ZKD_ID" })

    // Adiciona a descricao do Modelo de Dados
    oModel:SetDescription( 'Integração bot Protheus' )

    // Adiciona a descricao do Componente do Modelo de Dados
    oModel:GetModel( 'ZKDMASTER' ):SetDescription( 'Integração bot Protheus' )
Return oModel

//-------------------------------------------------------------------
Static Function ViewDef()
    // Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
    Local oStruZKD := FWFormStruct( 2, 'ZKD')
    // Cria a estrutura a ser usada na View
    Local oModel   := FWLoadModel( 'ULOJA001' )
    Local oView

    // Cria o objeto de View
    oView := FWFormView():New()

    // Define qual o Modelo de dados será utilizado
    oView:SetModel( oModel )

    //Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
    oView:AddField( 'VIEW_S_ZKD', oStruZKD, 'ZKDMASTER' )

    // Criar um "box" horizontal para receber algum elemento da view
    oView:CreateHorizontalBox( 'SUPERIOR', 100 )

    // Relaciona o ID da View com o "box" para exibicao
    oView:SetOwnerView( 'VIEW_S_ZKD', 'SUPERIOR' )

    // Criar novo botao na barra de botoes
    // oView:AddUserButton( 'Manutenção de Grupo', 'CLIPS', { |oView| u_ULOJE003() } )

    // Liga a identificacao do componente
    oView:EnableTitleView('VIEW_S_ZKD','Integração bot Protheus')

    // Habilita a pesquisa
    //oView:SetViewProperty( 'VIEW_ZKD', "GRIDSEEK" )
Return oView
