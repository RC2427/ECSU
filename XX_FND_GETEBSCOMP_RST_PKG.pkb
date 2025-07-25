CREATE OR REPLACE PACKAGE BODY XX_FND_GETEBSCOMP_RST_PKG AS
  /*-------------------------------------------------------------------------------------------
  *********************************************************************************************
  Details : Package Body
  
  Package Name : XX_FND_GETEBSCOMP_RST_PKG.pkb
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
  ---- Global Constants ----
  -- Status Constants
  gc_process_success CONSTANT VARCHAR2(120) := 'SUCCESS';
  gc_process_no_data_fnd CONSTANT VARCHAR2(120) := 'NO DATA FOUND';
  gc_process_error CONSTANT VARCHAR2(120) := 'ERROR';
  --
  --
  PROCEDURE log(p_msg in VARCHAR2) IS
  BEGIN
    --
    dbms_output.put_line(TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS TZH:TZM') || ' : ' ||  p_msg);
    --
  END log;
  --
  FUNCTION check_if_process_enabled(p_check_var in VARCHAR2,
                                    p_check_vs  in VARCHAR2) RETURN VARCHAR2 IS
     --
     lc_check_val VARCHAR2(5000) := 'VALUENOTSET';
     --
   BEGIN
     --
     SELECT ffvt.description
       INTO lc_check_val
       FROM apps.fnd_flex_value_sets ffvs,
            apps.fnd_flex_values     ffv,
            apps.fnd_flex_values_tl  ffvt
      WHERE 1 = 1
        AND ffvs.flex_value_set_id = ffv.flex_value_set_id
        AND ffv.flex_value_id = ffvt.flex_value_id
        AND ffv.enabled_flag = 'Y'
        AND (ffv.end_date_active IS NULL OR trunc(ffv.start_date_active) <= trunc(SYSDATE))
        AND (ffv.end_date_active IS NULL OR trunc(ffv.end_date_active) >= trunc(SYSDATE))
        AND ffvt.language = userenv('LANG')
        AND flex_value_set_name = p_check_vs
        AND ffv.flex_value  = p_check_var;
     --
     RETURN lc_check_val;
     --
  EXCEPTION
    --
    WHEN NO_DATA_FOUND THEN
       lc_check_val := 'VALUENOTSET';
       RETURN lc_check_val;
       --
  END check_if_process_enabled;
  --------------------------------------------------------------------------------
  -- Procedure to get all Valueset details
  PROCEDURE xx_get_value_set(p_find_component_name IN VARCHAR2,
                             x_prog_dets           OUT VARCHAR2,
                             x_status              OUT VARCHAR2,
                             x_err_msg             OUT VARCHAR2) IS
    --
    lc_find_program_name VARCHAR2(12000) := p_find_component_name;
    lc_program_dets      VARCHAR2(30000);
    --
    lc_err_msg VARCHAR2(30000);
    --
  BEGIN
    --
    log('Search Procedure : xx_get_value_set : ' || p_find_component_name);
    --
    SELECT json_object('component_type' VALUE 'Value Set',
                       'data' VALUE
                       json_object('value_set_id' VALUE
                                   MIN(ffvt.flex_value_id),
                                   'value_set_name' VALUE
                                   MIN(ffvs.flex_value_set_name),
                                   'values' VALUE
                                   json_arrayagg(json_object('flex_value_id'
                                                             VALUE
                                                             ffv.flex_value_id,
                                                             'flex_value'
                                                             VALUE
                                                             ffv.flex_value,
                                                             'description' VALUE
                                                             ffvt.description,
                                                             'enabled_flag'
                                                             VALUE
                                                             ffv.enabled_flag,
                                                             'child_range' VALUE CASE
                                                               WHEN ffnh.child_flex_value_low IS NOT NULL OR
                                                                    ffnh.child_flex_value_high IS NOT NULL THEN
                                                                json_object('low' VALUE ffnh.child_flex_value_low,
                                                                            'high' VALUE ffnh.child_flex_value_high)
                                                               ELSE
                                                                NULL
                                                             END) RETURNING CLOB))
                       RETURNING CLOB) AS value_set_json
    INTO lc_program_dets
    FROM apps.fnd_flex_value_sets           ffvs,
         apps.fnd_flex_values               ffv,
         apps.fnd_flex_values_tl            ffvt,
         apps.fnd_flex_value_norm_hierarchy ffnh
    WHERE 1 = 1
    AND ffvs.flex_value_set_id = ffv.flex_value_set_id
    AND ffv.flex_value_set_id = ffnh.flex_value_set_id(+)
    AND ffv.flex_value_id = ffvt.flex_value_id
    AND (ffv.end_date_active IS NULL OR trunc(ffv.start_date_active) <= trunc(SYSDATE))
    AND (ffv.end_date_active IS NULL OR trunc(ffv.end_date_active) >= trunc(SYSDATE))
    AND ffvt.language = userenv('LANG')
    AND ffvs.flex_value_set_name = lc_find_program_name
    GROUP BY ffvs.flex_value_set_id;
    --
    x_prog_dets := lc_program_dets;
    x_status    := gc_process_success;
    --
  EXCEPTION
    --
    WHEN no_data_found THEN
      --
      x_status   := gc_process_no_data_fnd;
      lc_err_msg := 'xx_get_value_set - No Data Found for current parameters : ' ||
                    p_find_component_name;
      --
      x_err_msg := json_object('status' VALUE 'error',
                               'message' VALUE lc_err_msg);
      log(lc_err_msg);
    
    WHEN OTHERS THEN
      --
      lc_err_msg := 'xx_get_value_set - Unexpected Error while running  : ' ||
                    dbms_utility.format_error_backtrace || SQLERRM;
      x_status   := gc_process_error;
      --
      x_err_msg := json_object('status' VALUE 'error',
                               'message' VALUE lc_err_msg);
      log(lc_err_msg);
      --
  END xx_get_value_set;
  -------
  -- Procedure to get suggestions for Valueset
  --------------------------------------------------------------------------------
  -- Procedure to get all concurrent program details
  PROCEDURE xx_get_conc_program(p_find_component_name IN VARCHAR2,
                                x_prog_dets         OUT VARCHAR2,
                                x_status            OUT VARCHAR2,
                                x_err_msg           OUT VARCHAR2) IS
    --
    lc_find_program_name VARCHAR2(12000) := p_find_component_name;                   
    lc_program_dets      VARCHAR2(30000);
    --
    lc_err_msg           VARCHAR2(30000);
    --
  BEGIN
    --
    log('Search Proc : xx_get_conc_program : ' || p_find_component_name);
    --
    SELECT JSON_OBJECT('component_type' VALUE 'Concurrent Program',
                   'data' VALUE 
                   JSON_OBJECT('concurrent_program' VALUE 
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
    x_status := gc_process_success;
    --
  EXCEPTION
    --
    WHEN no_data_found THEN
      --
      x_status := gc_process_no_data_fnd;
      lc_err_msg := 'xx_get_conc_program - No Data Found for current paramters : ' || p_find_component_name;
      --
      x_err_msg := JSON_OBJECT('status' VALUE 'error',
                               'message' VALUE lc_err_msg);
      log(lc_err_msg);
      
    WHEN OTHERS THEN
      --
      lc_err_msg := 'xx_get_conc_program - Unexpected Error while running  : ' || dbms_utility.format_error_backtrace || SQLERRM;
      x_status := gc_process_error;
      --
      x_err_msg := JSON_OBJECT('status' VALUE 'error',
                               'message' VALUE lc_err_msg);
      log(lc_err_msg);
      --
  END xx_get_conc_program;
  -------
  -- Procedure to get suggestions for concurrent program
  PROCEDURE xx_get_conc_suggest_program(p_find_component_name IN VARCHAR2,
                                        x_prog_dets         OUT VARCHAR2,
                                        x_status            OUT VARCHAR2,
                                        x_err_msg           OUT VARCHAR2) IS
    --
    lc_find_program_name VARCHAR2(12000) := '%' || p_find_component_name || '%';                   
    lc_program_dets      VARCHAR2(30000);
    --
    lc_err_msg           VARCHAR2(30000);
    --
  BEGIN
    --
    log('Search Proc : xx_get_conc_suggest_program : ' || lc_find_program_name);
    --
    SELECT json_object('component_type' VALUE 'Concurrent Program',
                       'data' VALUE json_object('concurrent_program' VALUE
                                   json_arrayagg(json_object('concurrent_program_id'
                                                             VALUE
                                                             conc_suggestion.concurrent_program_id,
                                                             'user_concurrent_program_name'
                                                             VALUE
                                                             conc_suggestion.user_concurrent_program_name)
                                                 RETURNING CLOB)) RETURNING CLOB) AS conc_json
    INTO lc_program_dets
    FROM (SELECT fcp.concurrent_program_id,
                 fcpt.user_concurrent_program_name
          FROM apps.fnd_concurrent_programs    fcp,
               apps.fnd_concurrent_programs_tl fcpt,
               apps.fnd_executables            fe,
               apps.fnd_executables_tl         fet
          WHERE fe.executable_id = fet.executable_id
          AND fcp.concurrent_program_id = fcpt.concurrent_program_id
          AND fcpt.language = fet.language
          AND fcp.executable_id = fe.executable_id
          AND fcp.executable_application_id = fe.application_id
          AND fcpt.user_concurrent_program_name LIKE lc_find_program_name
          FETCH FIRST 5 rows ONLY) conc_suggestion;
    --
    x_prog_dets := lc_program_dets;
    x_status    := gc_process_success;
    --
  EXCEPTION
    --
    WHEN no_data_found THEN
      --
      x_status   := gc_process_no_data_fnd;
      lc_err_msg := 'xx_get_conc_suggest_program - No Data Found for current paramters : ' ||
                    p_find_component_name;
      --
      x_err_msg := json_object('status' VALUE 'error',
                               'message' VALUE lc_err_msg);
      log(lc_err_msg);
    
    WHEN OTHERS THEN
      --
      lc_err_msg := 'xx_get_conc_suggest_program - Unexpected Error while running  : ' ||
                    dbms_utility.format_error_backtrace || SQLERRM;
      x_status   := gc_process_error;
      --
      x_err_msg := json_object('status' VALUE 'error',
                               'message' VALUE lc_err_msg);
      log(lc_err_msg);
      --
  END xx_get_conc_suggest_program;
  --------------------------------------------------------------------------------
  --
  -- Procedure to get suggestions (MAIN Procedure)
  PROCEDURE xx_get_compo_suggest_wrapper(p_suggestion_text      IN VARCHAR2,
                                         p_comp_type            IN VARCHAR2,
                                         x_suggestion_results   OUT VARCHAR2,
                                         x_status               OUT VARCHAR2,
                                         x_error_msg            OUT VARCHAR2) AS
  --
  lc_component_name  VARCHAR2(14000) := p_suggestion_text;
  lc_comp_type       VARCHAR2(400) := p_comp_type;
  --
  lc_suggestion_results VARCHAR2(5000);
  lc_check_status VARCHAR2(600);
  lc_error_msg    VARCHAR2(700);
  --
  ex_custom_issue EXCEPTION;
  --
  BEGIN
    --
    IF upper(check_if_process_enabled('PROCESS_ENABLED','XX_ECSU_SETUP_VS')) != 'YES' THEN
      --
      lc_error_msg := 'xx_get_compo_dets_wrapper - Process not enabled in Setup VS : XX_ECSU_SETUP_VS';
      RAISE ex_custom_issue;
      --
    END IF;
    --
    IF lc_component_name IS NULL OR lc_comp_type IS NULL THEN
      --
      lc_error_msg := 'xx_get_compo_dets_wrapper - Input paremeters are NULL : p_suggestion_text/p_comp_type : ' 
                      || p_suggestion_text || ' / ' || p_comp_type;
      RAISE ex_custom_issue;
      --
    END IF;
    --
    CASE
    --
      WHEN lc_comp_type = 'concurrent_program' THEN
        --
        xx_get_conc_suggest_program(p_find_component_name => lc_component_name,
                                x_prog_dets         => lc_suggestion_results,
                                x_status            => lc_check_status,
                                x_err_msg           => lc_error_msg);
        --
      WHEN lc_comp_type = 'value_set' THEN
        --
        xx_get_value_set(p_find_component_name => lc_component_name,
                         x_prog_dets           => lc_suggestion_results,
                         x_status              => lc_check_status,
                         x_err_msg             => lc_error_msg);
        --
      ELSE
        --
        lc_check_status := gc_process_error;
        lc_error_msg    := 'Incorrect component type / Component type not supported : ' || p_comp_type;
        --
    END CASE;
    --
    IF lc_check_status != gc_process_success THEN
      --
      RAISE ex_custom_issue;
      --
    END IF;
    --
    x_suggestion_results := lc_suggestion_results;
    x_status := gc_process_success;
    --
  EXCEPTION
    --
    WHEN ex_custom_issue THEN
      --
      lc_error_msg := 'ORACLE PL/SQL ERROR : ' || lc_error_msg;
      log(lc_error_msg);
      x_error_msg := lc_error_msg;
      x_status := gc_process_error;
      --
    WHEN OTHERS THEN
      --
      lc_error_msg := 'ORACLE PL/SQL ERROR : xx_get_compo_suggest_wrapper - Unexpected Error occured while searching ' || SQLERRM || ' : ' 
                       || dbms_utility.format_error_backtrace;
      log(lc_error_msg);
      x_error_msg := lc_error_msg;
      x_status := gc_process_error;
      --
  END xx_get_compo_suggest_wrapper;
  --
  -- Procedure to get component details ( MAIN Procedure )
  PROCEDURE xx_get_compo_dets_wrapper(p_component_name    IN VARCHAR2,
                                      p_comp_type         IN VARCHAR2,
                                      x_component_results OUT VARCHAR2,
                                      x_status            OUT VARCHAR2,
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
    IF upper(check_if_process_enabled('PROCESS_ENABLED','XX_ECSU_SETUP_VS')) != 'YES' THEN
      --
      lc_error_msg := 'xx_get_compo_dets_wrapper - Process not enabled in Setup VS : XX_ECSU_SETUP_VS';
      RAISE ex_custom_issue;
      --
    END IF;
    --
    IF p_component_name IS NULL OR p_comp_type IS NULL THEN
      --
      lc_error_msg := 'xx_get_compo_dets_wrapper - Input paremeters are NULL : p_component_name/p_comp_type : ' 
                      || p_component_name || ' / ' || p_comp_type;
      RAISE ex_custom_issue;
      --
    END IF;
    --
    CASE
    --
      WHEN lc_comp_type = 'concurrent_program' THEN
        --
        xx_get_conc_program(p_find_component_name => lc_component_name,
                            x_prog_dets         => lc_component_results,
                            x_status            => lc_check_status,
                            x_err_msg           => lc_error_msg);
        --
      WHEN lc_comp_type = 'value_set' THEN
        --
        xx_get_value_set(p_find_component_name => lc_component_name,
                         x_prog_dets           => lc_component_results,
                         x_status              => lc_check_status,
                         x_err_msg             => lc_error_msg);
        --
      ELSE
        --
        lc_check_status := gc_process_error;
        lc_error_msg    := 'Incorrect component type / Component type not supported : ' || p_comp_type;
        --
    END CASE;
    --
    IF lc_check_status != gc_process_success THEN
      --
      RAISE ex_custom_issue;
      --
    END IF;
    --
    x_component_results := lc_component_results;
    x_status := gc_process_success;
    --
  EXCEPTION
    --
    WHEN ex_custom_issue THEN
      --
      lc_error_msg := 'ORACLE PL/SQL ERROR : ' || lc_error_msg;
      log(lc_error_msg);
      --
      x_error_msg := lc_error_msg;
      x_status := gc_process_error;
      --
    WHEN OTHERS THEN
      --
      lc_error_msg := 'ORACLE PL/SQL ERROR : xx_get_compo_dets_wrapper - Unexpected Error occured while searching ' || SQLERRM || ' : ' 
                       || dbms_utility.format_error_backtrace;
      log(lc_error_msg);
      --
      x_error_msg := lc_error_msg;
      x_status := gc_process_error;
      --
  END xx_get_compo_dets_wrapper;

END XX_FND_GETEBSCOMP_RST_PKG;
/
