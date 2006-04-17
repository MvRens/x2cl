object frmMain: TfrmMain
  Left = 300
  Top = 219
  Caption = 'X2MenuBar Test'
  ClientHeight = 379
  ClientWidth = 589
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object bvlMenu: TBevel
    Left = 125
    Top = 0
    Width = 8
    Height = 379
    Align = alLeft
    Shape = bsLeftLine
    ExplicitLeft = 148
    ExplicitTop = -4
  end
  object lblAnimationTime: TLabel
    Left = 424
    Top = 20
    Width = 98
    Height = 13
    Caption = 'Animation time (ms):'
  end
  object mbTest: TX2MenuBar
    Left = 0
    Top = 0
    Width = 125
    Height = 379
    Align = alLeft
    Groups = <>
    Images = glMenu
    OnCollapsed = mbTestCollapsed
    OnCollapsing = mbTestCollapsing
    OnExpanded = mbTestExpanded
    OnExpanding = mbTestExpanding
    OnSelectedChanged = mbTestSelectedChanged
    OnSelectedChanging = mbTestSelectedChanging
    Painter = mcPainter
    Groups = <
      item
        Caption = 'Share'
        ImageIndex = 0
        Expanded = True
        Items = <
          item
            Caption = 'File'
            ImageIndex = 0
          end
          item
            Caption = 'Folder'
            ImageIndex = 1
          end
          item
            Caption = 'Photo'
            ImageIndex = 2
          end
          item
            Caption = 'Video'
            ImageIndex = 3
          end
          item
            Caption = 'Invisible item'
            Visible = False
          end
          item
            Caption = 'Disabled item'
            Enabled = False
          end>
      end
      item
        Caption = 'Group'
        ImageIndex = 1
        Expanded = False
        Items = <
          item
            Caption = 'Menu Item'
          end>
      end
      item
        Caption = 'Group without items'
        ImageIndex = 2
        Expanded = False
        Items = <>
      end
      item
        Caption = 'Biiiiig group.'
        Expanded = False
        Items = <
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end>
      end
      item
        Caption = 'Disabled group'
        Enabled = False
        Expanded = False
        Items = <
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end
          item
            Caption = 'Menu Item'
          end>
      end>
  end
  object seAnimationTime: TJvSpinEdit
    Left = 424
    Top = 36
    Width = 81
    Height = 21
    CheckMinValue = True
    ButtonKind = bkStandard
    Value = 250.000000000000000000
    TabOrder = 1
    OnChange = seAnimationTimeChange
  end
  object Panel1: TPanel
    Left = 280
    Top = 68
    Width = 133
    Height = 77
    BevelOuter = bvNone
    TabOrder = 2
    object rbmusikCube: TRadioButton
      Left = 0
      Top = 0
      Width = 113
      Height = 17
      Caption = 'musikCube style'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = PainterClick
    end
    object rbUnameIT: TRadioButton
      Left = 0
      Top = 17
      Width = 113
      Height = 17
      Caption = 'Uname-IT style'
      TabOrder = 1
      OnClick = PainterClick
    end
    object chkBlurShadow: TCheckBox
      Left = 20
      Top = 36
      Width = 97
      Height = 17
      Caption = 'Blur shadow'
      TabOrder = 2
      OnClick = chkBlurShadowClick
    end
  end
  object Panel2: TPanel
    Left = 424
    Top = 68
    Width = 153
    Height = 101
    BevelOuter = bvNone
    TabOrder = 3
    object rbSliding: TRadioButton
      Left = 0
      Top = 20
      Width = 113
      Height = 17
      Caption = 'Sliding animation'
      Checked = True
      TabOrder = 1
      TabStop = True
      OnClick = AnimationClick
    end
    object rbNoAnimation: TRadioButton
      Left = 0
      Top = 0
      Width = 113
      Height = 17
      Caption = 'No animation'
      TabOrder = 0
      OnClick = AnimationClick
    end
    object rbFade: TRadioButton
      Left = 0
      Top = 60
      Width = 113
      Height = 17
      Caption = 'Fading animation'
      TabOrder = 3
      OnClick = AnimationClick
    end
    object rbDissolve: TRadioButton
      Left = 0
      Top = 40
      Width = 113
      Height = 17
      Caption = 'Dissolving animation'
      TabOrder = 2
      OnClick = AnimationClick
    end
    object rbSlideFade: TRadioButton
      Left = 0
      Top = 80
      Width = 153
      Height = 17
      Caption = 'Fading + sliding animation'
      TabOrder = 4
      OnClick = AnimationClick
    end
  end
  object chkAutoCollapse: TCheckBox
    Left = 280
    Top = 196
    Width = 89
    Height = 17
    Caption = 'Auto collapse'
    TabOrder = 4
    OnClick = chkAutoCollapseClick
  end
  object chkAllowCollapseAll: TCheckBox
    Left = 280
    Top = 236
    Width = 101
    Height = 17
    Caption = 'Allow collapse all'
    TabOrder = 6
    OnClick = chkAllowCollapseAllClick
  end
  object chkAutoSelectItem: TCheckBox
    Left = 280
    Top = 216
    Width = 101
    Height = 17
    Caption = 'Auto select item'
    TabOrder = 5
    OnClick = chkAutoSelectItemClick
  end
  object chkScrollbar: TCheckBox
    Left = 424
    Top = 196
    Width = 121
    Height = 17
    Caption = 'Scrollbar'
    Checked = True
    State = cbChecked
    TabOrder = 7
    OnClick = chkScrollbarClick
  end
  object chkHideScrollbar: TCheckBox
    Left = 424
    Top = 217
    Width = 121
    Height = 17
    Caption = 'Hide Scrollbar'
    Checked = True
    State = cbChecked
    TabOrder = 8
    OnClick = chkHideScrollbarClick
  end
  object lbEvents: TListBox
    Left = 152
    Top = 267
    Width = 421
    Height = 93
    ItemHeight = 13
    TabOrder = 9
  end
  object Button1: TButton
    Left = 152
    Top = 68
    Width = 113
    Height = 25
    Caption = 'SelectFirst'
    Enabled = False
    TabOrder = 10
  end
  object Button2: TButton
    Left = 152
    Top = 96
    Width = 113
    Height = 25
    Caption = 'SelectPrior'
    Enabled = False
    TabOrder = 11
  end
  object Button3: TButton
    Left = 152
    Top = 124
    Width = 113
    Height = 25
    Caption = 'SelectNext'
    Enabled = False
    TabOrder = 12
  end
  object Button4: TButton
    Left = 152
    Top = 152
    Width = 113
    Height = 25
    Caption = 'SelectLast'
    Enabled = False
    TabOrder = 13
  end
  object Button5: TButton
    Left = 152
    Top = 180
    Width = 113
    Height = 25
    Caption = 'SelectGroupByIndex'
    Enabled = False
    TabOrder = 14
  end
  object Button6: TButton
    Left = 152
    Top = 208
    Width = 113
    Height = 25
    Caption = 'SelectItemByIndex'
    Enabled = False
    TabOrder = 15
  end
  object chkHotHand: TCheckBox
    Left = 424
    Top = 236
    Width = 149
    Height = 17
    Caption = 'Hand cursor for hot items'
    TabOrder = 16
    OnClick = chkHotHandClick
  end
  object gcMenu: TX2GraphicContainer
    Graphics = <
      item
        Name = 'ShareFile'
        Picture.Data = {
          0A54504E474F626A65637489504E470D0A1A0A0000000D494844520000001000
          00001008060000001FF3FF61000001844944415478DAA5D2CD4B02411400F0B7
          DB2DA27FAB4EE22102A1A0C0FCA0837A4989683734C7A072A12C45502902FB00
          E95487FEA20E1D24337777E635B33BBB389B5E6A60F6ED1EDE6FDE9BB71AFC73
          69C14BADF98A223A8EEB7DDB41B4FD38B11D1112D661A23F1728A657E69E5428
          F761796911869F5F0A32174044102551E6BF17C90364B76270F7F4A6202140AE
          5FB09459554E1589942B8CF9C0F4E280A600A6F58C462E3613A01C70F9B61DCA
          4F1F83D51CA0656EEB2A501FA0918FAB2D88646FA3D74A108D6A0F2E2A496D26
          20127D80972E93998208A00B97951D1530CE076816E2E052FFF238E125B228C4
          1F06E941230AEC9F3CE2F1DE1A7CBB2CAC00652B4CB6C2E49D1C912E07522A50
          22F7484AEB30B2250018224C2607509974A0719C5681BC798B75630386131AA9
          80274B2C68A5C22BB8AA46809C71C347B3091F631ACC414564152E8FD55A079A
          24A302A9621B5BB524BC8F9CA951AA80F72FF07D76DA8516C9AAC0EE411B755D
          0790339045841719DC8BA86241D37F4FE1AFEB07F8392D2050E7313500000000
          49454E44AE426082}
      end
      item
        Name = 'ShareFolder'
        Picture.Data = {
          0A54504E474F626A65637489504E470D0A1A0A0000000D494844520000001000
          00001008060000001FF3FF610000025B4944415478DAAD936D48535118C7FF77
          775BEAD8ACA123CB2834EC9B2DB2B0328CCC284B461192146A48040505D36A05
          154826A64D53A490303F6510C528421B6B2CC4C0E5170317ABA859099ACEBBF7
          B6BBFBD2F172433F680875E0CF797BFE3FCE79CE7928FC63A3961B38D201BB3F
          82524100E6140AA0A7D28ADA65039C2D88159DF3A7AA52F5D2FCF90D0AA60650
          4B02BCBDD8C504512288284CB23088EA0C63F18569FACFFE92007727BCB47E4B
          9E5A9385F4753B9091530EB5D6009AD690DD28519C2813B66B5A1CB9B908C075
          0762B139042EEE412CF01D51BF0789F04F4064C1712C36EEAE275119787A350B
          C79A64C0609B2209958E5E633C4FF9DE36A0B07610D1D97EA8523448D56AB122
          2D8D642E8EC98FA3D0E79442AD31E289250F15CD32C0D942058ACE0EA7ABD236
          C1D19C8E7D973F93D521804B4A4649624292CFF3151B0AEAF1F8E26654B6CA00
          C76DA53BFF68DFB6CCDC9DB037ADC5FE2BA3C4F41AE009804BCC03F8047E787D
          C8DE5E8547751538619501F62674AF5A5F525350D9AD1A68CCC5018B8BE4AA5F
          324060E57EEE041CC4A40026A6C3CBAE07A8BA2B03061A5141F1F4BDBD752FF4
          AF5ACB70E8928D24FC1931B20B00736312ACA010F42760EB79839ACE05AF3070
          2BC5A6CBDA6A9AF10DA1DCFC1008F649999704228508669605331E86776C06D3
          939189EA0E6453F31F0367D49AD55DF1F0246D32B713402F3125C04C45C8BD43
          98188F89D15032405E72F8781B0E2E5A0BCEAE7C8E99784F97551FC627B70BDF
          BEFCE2E3117E4AE031625809CB9EEBF8F0D7627A77BFE0D4D8D88855A9440022
          1C27DB71FABF55E352ED373075032024CD24170000000049454E44AE426082}
      end
      item
        Name = 'ShareWebcam'
        Picture.Data = {
          0A54504E474F626A65637489504E470D0A1A0A0000000D494844520000001000
          00001008060000001FF3FF61000002C14944415478DABD935D48935118C7FF9B
          DB9CD38913155CB586D008C30F9A95A8217927A14157DE441FE88521A4828108
          0A8992621745A80C477AB3A048D44A08A18589BA959AE0D4A09CBAE936F7E55E
          759B7BDFB91EDF20E82E283A70381CCE797EFFE739E7FF08F09743F04F00D5D5
          BA94C4C4E47A954AA171BB0F6452292B92CB25C24824088E63A32C1BE658F630
          B2BFBF175E5B5B5B0F0643AF8DC6E79F7F011A1B87DE3435555C0D8582181F37
          637BFB3BEAEA6ED28918BBBB3EC4C589F8AB1C071C1C846136CFC52626DE0D8D
          8E0EDEE6011D1D2F772A2B0BD2392E0A936915878711C46231088502582C6FB1
          B4B44CC0079899998048C48132A1A8D42D9DAEEB240F686919F017179F4D6118
          8ED4BD9048E22016FF9C16CB14525353A056E7C26AB5109C4166A692A0566F6F
          EFC3341ED0DDFDC25759A9552C2CAC8061F6715C7B2C968868D405AD36076EB7
          874A0990BA020A453A8145181B1BF1F7F575A7F280F6F621574D4D4586DDEE81
          D7CBC066B3D2EA446E6E16BABA9E906A0C39392AE4E79F874A758E32946078F8
          95BBBFBF278307B4B50D6CD6D65E3FB5B9E982CFC7606BCB4EEA3EACAE2E2110
          5042A3C9C6E4A40EA5A525042A444282140683C1A6D33D56F180E6E6A75F1B1A
          6E683636B649790F3B3B0E04832EACAF7F83D13887B4B44CC8E52C0A0B8B9097
          7701F1F1F1D0EBF52B7A7D6F360FA8AFEFFAD4DA7AB7C06ADD86C7B34BC10C1C
          0E3BA4D2E35F311F7B014AE50994945C21F544242727D1BB3D9A32189E5DE601
          55558D239D9DF7AE310C4BEA7EAA5100A7D3857098A1E010EDC5C8CA3A43CA32
          BACD61717131363030747F76F6430F0F282FBF73A9ACACE47D51915666B3B9C8
          386421B11432593C418294CD163DAC2DE2743AE697972DC66834326A327D34FD
          D60BE5E5B72EAAD5A7079392E41AB2AE9BCC6275B91CCB3E5FE08B40C0CE1F1D
          F917A6A767427FD24C429A47FFAD1B7F00ED1B51200D4AE2740000000049454E
          44AE426082}
      end
      item
        Name = 'ShareWebcamVideo'
        Picture.Data = {
          0A54504E474F626A65637489504E470D0A1A0A0000000D494844520000001000
          00001008060000001FF3FF61000002EA4944415478DAA5935D48935118C7FFF3
          DDAB6BCEF9FDED44DC4CA15E8761412A1296A121285ED595DD7521298C125341
          E9622B584CE6BCF122454891AE9424432B3FC8A4FC203F32D1E9FCAA95D36DCD
          B5BDAF7BB78E2B040BA2E8DC9CAFE7FC9EE7FCCFF90BF09F4DF0EB82CFE713E8
          F5FA149AA6198FC7C3884422262C2C8C118BC5A91CC7EDBBDDAE75ABD5BAC4B2
          9C4EA5524D1E03747777574B2492A688888830D2432A952238580C9AA6C82E8F
          830316DBDB7632077A7B7B5FD7D737E41C017A7A7A8A939393FB188611DA6C36
          2426268265DDB05A2D9899716373D30BA39187CD7608FA86ADCD06D7E0D0A0D8
          0F50ABD585342D7CEA703828A55289E8E818242424203C5C82AE2E0789909183
          FB70BB59389D2E02F66274F4BA6361615CEA075455DD1C11894EE43FEC7C8C2B
          C59791794A8EA2A26212ECC4F47436380EE430878D8D31D8ED6FC93A199BDEAC
          4FCD0CA4F801776A6B9D731F56C553CB1C3EED72A82C4FC2A5C2622814C99898
          9061656519F3F3F7B1B7B785A8A818040444212DEDCCAC56AB52FA013535B7ED
          E65D56FA688405EF0DC5D59CAF60329290937B0E7373720C0CA840511C76763E
          FB01F1F1371014343B6B3034FE005456560E9D4C935FACD6AF03541CCAB35791
          9A1082D34C3A9697F33035A5267A444128CC464848162C163BD1A97FB2B5557D
          F667053525F0F17D2C1527E81B36212B6E1D79F917E0724988FAB9100804F078
          78A2C5A1802EA2831B1919CFFB753A6DC9D133D6D5D5DD22719AF434B9D0E9E2
          488981E4B942313C1C47EECCC3EBF591B9070E871B4AA58FC09E7536371B2A8E
          7DA4F6F6F677A5A5A59966B39964B1C164B2A0A34388C04090CC3C2223BD2828
          A0C978D16B327D2CD56A1F3C3906D0E974E3656565E7799EF7976DB57E415BDB
          26C46211C94A932A8CBEA5A5B5171415D8A8D1685EFDE605F2A1AE51146590C9
          64110A8582F8C2EBBFF7E2E27B9FD1B8F6322040D8A4D1DC1BFBA39988418288
          894A481515B1B1B185168BE51531D8DD969696D1BF72E3BFB6EF2C065120000A
          A5C30000000049454E44AE426082}
      end>
    Left = 180
    Top = 8
  end
  object glMenu: TX2GraphicList
    Container = gcMenu
    Left = 208
    Top = 8
  end
  object mcPainter: TX2MenuBarmusikCubePainter
    Left = 152
    Top = 8
  end
  object unaPainter: TX2MenuBarunaPainter
    BlurShadow = False
    Left = 152
    Top = 36
  end
end
