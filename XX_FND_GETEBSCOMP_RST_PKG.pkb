CREATE OR REPLACE PACKAGE BODY XX_FND_GETEBSCOMP_RST_PKG AS
  /*-------------------------------------------------------------------------------------------
  *********************************************************************************************
  Details : Package Body
  
  Package Name : XX_FND_GETEBSRST_PKG.pkb
  Description  : Rest API Package for EBS Search Program: - To enable users to search for custom 
                 & Default Oracle EBS components efficiently via a user-friendly interface. 
                 Component types include concurrent programs, custom packages, tables, views, 
                 workflows, and more
  Doc ID       : 
  
  =============================================================================================
  REM    Version     Revision Date           Developer             Change Description 
  ---    -------     ------------            ---------------       ------------------
  REM    1.0         22-JULY-2025            Rohit Chaudhari       Intitial Version
  *********************************************************************************************
  ---------------------------------------------------------------------------------------------*/
  PROCEDURE log(p_msg in VARCHAR2) IS
  BEGIN
    --
    dbms_output.put_line(TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS TZH:TZM') || p_msg);
    --
  END log;

  -- Procedure to get Sales order details
  PROCEDURE xx_get_conc_program(p_find_program_name IN VARCHAR2,
                                x_prog_dets         OUT VARCHAR2,
                                x_status            OUT VARCHAR2,
                                x_err_msg           OUT VARCHAR2) IS
    --
    lc_find_program_name VARCHAR2(12000) := p_find_program_name;                   
    lc_program_dets      VARCHAR2(30000);
    --
    lc_err_msg           VARCHAR2(30000);
    --
  BEGIN
    --
    SELECT JSON_OBJECT('component_type' VALUE 'Concurrent Program',
                   'data' VALUE 
                   JSON_OBJECT('concurrent_porgram' VALUE 
                     JSON_OBJECT('concurrent program id' VALUE fcp.concurrent_program_id,
                                    'user_concurrent_program_name' VALUE fcpt.user_concurrent_program_name,
                                    'concurrent_program_name' VALUE fcp.concurrent_program_name,
                                    'execution_options' VALUE fcp.execution_options,
                                    'output_file_type' VALUE fcp.output_file_type,
                                    'enabled_flag' VALUE fcp.enabled_flag,
                                    'save_output_flag' VALUE fcp.save_output_flag),
                     'application_short_name' VALUE fa.application_short_name,
                     'executable' VALUE JSON_OBJECT('executable_id' VALUE fe.executable_id,
                                  'executable_name' VALUE fe.executable_name,
                                  'execution_file_name' VALUE fe.execution_file_name,
                                  'executable Type' VALUE flv.meaning))) AS CONC_JSON
    INTO lc_program_dets 
    FROM apps.fnd_concurrent_programs    fcp,
         apps.fnd_concurrent_programs_tl fcpt,
         apps.fnd_executables            fe,
         apps.fnd_executables_tl         fet,
         apps.fnd_application            fa,
         apps.fnd_application_tl         fat,
         apps.fnd_lookup_values          flv
    WHERE 1 = 1
    AND fe.executable_id = fet.executable_id
    AND fcp.concurrent_program_id = fcpt.concurrent_program_id
    AND fcpt.language = fet.language
    AND fcp.executable_id = fe.executable_id
    AND fcp.executable_application_id = fe.application_id
    AND fcp.application_id = fa.application_id
    AND fa.application_id = fat.application_id
    AND flv.lookup_code = fe.execution_method_code
    AND flv.lookup_type = 'CP_EXECUTION_METHOD_CODE'
    AND fcpt.user_concurrent_program_name = lc_find_program_name;
    --
    x_prog_dets := lc_program_dets;
    --
  EXCEPTION
    --
    WHEN no_data_found THEN
      --
      x_status := 'no_data_found';
      lc_err_msg := 'No Data found for current paramtere : ' || p_find_program_name;
      --
      x_err_msg := JSON_OBJECT('status' VALUE 'error',
                               'message' VALUE lc_err_msg);
      log(lc_err_msg);
      
    WHEN OTHERS THEN
      --
      lc_err_msg := 'Unexpected Error while running  : ' || dbms_utility.format_error_backtrace || SQLERRM;
      x_status := 'ERROR';
      --
      x_err_msg := JSON_OBJECT('status' VALUE 'error',
                               'message' VALUE lc_err_msg);
      log(lc_err_msg);
      --
  END xx_get_conc_program;
  --
  -- Procedure to get suggestions 
  PROCEDURE xx_get_compo_suggest_wrapper(p_suggestion_text      IN VARCHAR2,
                                         p_comp_type            IN VARCHAR2,
                                         x_suggestion_results   OUT VARCHAR2,
                                         x_error_msg            OUT VARCHAR2) AS
  --
  lc_check_status VARCHAR2(600);
  lc_error_msg    VARCHAR2(700);
  --
  ex_custom_issue EXCEPTION;
  --
  BEGIN
    --
    NULL;
    --
  EXCEPTION
    --
    WHEN ex_custom_issue THEN
      --
      log(lc_error_msg);
      x_error_msg := lc_error_msg;
      --
    WHEN OTHERS THEN
      --
      lc_error_msg := 'ORACLE PL/SQL : Unexpected Error occured while searching ' || SQLERRM || ' : ' 
                       || dbms_utility.format_error_backtrace;
      log(lc_error_msg);
      x_error_msg := lc_error_msg;
      --
  END xx_get_compo_suggest_wrapper;
  --
  -- Procedure to get component details 
  PROCEDURE xx_get_compo_dets_wrapper(p_component_name    IN VARCHAR2,
                                      p_comp_type         IN VARCHAR2,
                                      x_component_results OUT VARCHAR2,
                                      x_error_msg         OUT VARCHAR2) AS
    --
    lc_component_name    VARCHAR2(14000) := p_component_name;
    lc_comp_type         VARCHAR2(400) := p_comp_type;
    lc_component_results VARCHAR2(5000);
    --
    lc_check_status VARCHAR2(600);
    lc_error_msg    VARCHAR2(700);
    --
    ex_custom_issue EXCEPTION;
    --
  BEGIN
    --
    xx_get_conc_program(p_find_program_name => lc_component_results,
                        x_prog_dets         => lc_component_results,
                        x_status            => lc_check_status,
                        x_err_msg           => lc_error_msg);
    --
  EXCEPTION
    --
    WHEN ex_custom_issue THEN
      --
      log(lc_error_msg);
      x_error_msg := lc_error_msg;
      --
    WHEN OTHERS THEN
      --
      lc_error_msg := 'ORACLE PL/SQL : Unexpected Error occured while searching ' || SQLERRM || ' : ' 
                       || dbms_utility.format_error_backtrace;
      log(lc_error_msg);
      x_error_msg := lc_error_msg;
      --
  END xx_get_compo_dets_wrapper;

END XX_FND_GETEBSCOMP_RST_PKG;
/
