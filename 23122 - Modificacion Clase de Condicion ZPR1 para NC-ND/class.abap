class zclsd_exit_sap definition
  public
  final
  create public .

  public section.

    "! Permite consultar si el control exit esta activo.
    "! @parameter i_codex | identificador del control exit
    "! @parameter r_activ | activo = X, inactivo = ''
    class-methods ctrl_exit_sap
      importing
        !i_codex       type zd_codex
      returning
        value(r_activ) type zd_activ .
    "! Permite bloquear campo importe - condicion ZPR1 - VA01,VA02
    "! @parameter i_komv | informacion condiciones
    class-methods exit_block_price_cond
      importing
        !i_komv type komv .
  protected section.
  private section.
    constants c_codexit_01 type zd_codex value 'EXIT_BLOCK_PRICE_COND' ##NO_TEXT.

endclass.



class zclsd_exit_sap implementation.


  method ctrl_exit_sap.

    " get data
    select single activ
      into @r_activ
      from ztca_ctl_exit
     where codex eq @i_codex
       and activ eq @abap_true.

  endmethod.


  method exit_block_price_cond.

    " declarations
    data: c_zprz       type kschl value 'ZPR1',
          c_va01       type tcode value 'VA01',
          c_va02       type tcode value 'VA02',
          c_tipd       type zcpar value 'TIP_DOC_VT',
          c_komv_kbetr type screen-name value 'KOMV-KBETR'.

    data: r_vbtyp type range of vbtyp.

    field-symbols: <fs_vbak> type vbak.

    " check - ctrl exit
    check zclsd_exit_sap=>ctrl_exit_sap( i_codex = zclsd_exit_sap=>c_codexit_01 ) eq abap_true.

    " check - filters
    if  i_komv-kschl eq c_zprz and ( sy-tcode eq c_va01 or sy-tcode eq c_va02 ).

      " assing
      assign ('(SAPMV45A)VBAK') to <fs_vbak>.

      " get data
      select single auart, vbtyp
        from tvak
       where auart eq @<fs_vbak>-auart
       into @data(es_tvak).

      " get data
      select single *
        into @data(es_usuario)
        from ztsd_par_usu
       where uname eq @sy-uname
         and activ eq @abap_true.

      " get data
      select single *
        into @data(es_parametro)
        from ztsd_par_ge2
       where zcpar eq @c_tipd.

      " split data
      split es_parametro-zvpar at ';' into table data(ti_valores).
      r_vbtyp = value #( for ls_valor in ti_valores
                         (
                          sign    = if_fsbp_const_range=>sign_include
                          option  = if_fsbp_const_range=>option_equal
                          low     = ls_valor
                         )
                        ).

      " validations
      if screen-name eq c_komv_kbetr.
        screen-input = 0.   " block field
        if es_tvak-vbtyp in r_vbtyp and es_usuario-activ eq abap_true.
          screen-input = 1. " un-block field
        endif.
      endif.

    endif.

  endmethod.
endclass.