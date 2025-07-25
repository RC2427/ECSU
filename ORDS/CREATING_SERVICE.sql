-- Create the ECSU REST Service
BEGIN
  -- Defining the Module (a logical container for our APIs)
  ords.define_module(p_module_name    => 'ECSU.api',
                     p_base_path      => '/ECSU/',
                     p_items_per_page => 25,
                     p_status         => 'PUBLISHED',
                     p_comments       => 'ECSU Search Services');

  -- Defining the URL Template for all component details operation
  ords.define_template(p_module_name => 'ECSU.api',
                       p_pattern     => 'getComponent');

  -- Defining the POST Handler that executes your PL/SQL package
  ords.define_handler(p_module_name => 'ECSU.api',
                      p_pattern     => 'getComponent',
                      p_method      => 'POST',
                      p_source_type => ords.source_type_plsql,
                      p_source      => 'DECLARE
                      l_com_results  VARCHAR2(4000);
                      l_status        VARCHAR2(100);
                      l_error_message VARCHAR2(4000);
                    BEGIN
                      --
                      apps.xx_fnd_getebscomp_rst_pkg.xx_get_compo_dets_wrapper(p_component_name => :p_component_name,
                                             p_comp_type      => :p_comp_type,
                                             x_component_results => l_com_results,
                                             x_status         => l_status,
                                             x_error_msg  => l_error_message);
                      --
                      IF l_status = ''SUCCESS'' AND l_com_results IS NOT NULL THEN
                      --
                      owa_util.mime_header(''application/json''); 
                      htp.p(l_com_results);
                      owa_util.http_header_close;
                      :http_status_code := 200;
                      --
                      ELSE
                      --
                      owa_util.mime_header(''application/json'');
                      htp.p(json_object(''status'' VALUE l_status, ''message'' VALUE nvl(l_error_message, ''Unknown error'')));
                      owa_util.http_header_close;
                      :http_status_code := 400;
                      --
                      END IF;
                    END;');  
  --------------------------------------------------- 
  ords.define_parameter(p_module_name        => 'ECSU.api',
                        p_pattern            => 'getComponent',
                        p_method             => 'POST',
                        p_name               => 'http_status_code',
                        p_bind_variable_name => 'http_status_code',
                        p_param_type         => 'INT',
                        p_access_method      => 'OUT');


  -------------------------------------------------------------------   

  ords.define_template(p_module_name => 'ECSU.api',
                       p_pattern     => 'getComponentSuggestion');

  ords.define_handler(p_module_name => 'ECSU.api',
                      p_pattern     => 'getComponentSuggestion',
                      p_method      => 'POST',
                      p_source_type => ords.source_type_plsql,
                      p_source      => 'BEGIN 
                                        --# CACHE-CONTROL: public, max-age=60
                                        --
                                          DECLARE
                                            --
                                            l_com_results   VARCHAR2(32000);
                                            l_status        VARCHAR2(100);
                                            l_error_message VARCHAR2(4000);
                                            --
                                          BEGIN
                                            --
                                            apps.xx_fnd_getebscomp_rst_pkg.xx_get_compo_suggest_wrapper(p_suggestion_text      => :p_suggestion_text,
                                                                                                        p_comp_type            => :p_comp_type,
                                                                                                        x_suggestion_results   => l_com_results,
                                                                                                        x_status               => l_status,
                                                                                                        x_error_msg            => l_error_message);
                                            --
                                            IF l_status = ''SUCCESS'' AND l_com_results IS NOT NULL THEN
                                              --
                                              owa_util.mime_header(''application/json''); 
                                              htp.p(l_com_results);
                                              owa_util.http_header_close;
                                              :http_status_code := 200;
                                              --
                                            ELSE
                                              --
                                              owa_util.mime_header(''application/json'');
                                              htp.p(json_object(''status'' VALUE l_status, ''message'' VALUE nvl(l_error_message, ''Unknown error'')));
                                              owa_util.http_header_close;
                                              :http_status_code := 400;
                                              --
                                            END IF;
                                            --
                                            END;
                                            --
                                          END;');

  ords.define_parameter(p_module_name        => 'ECSU.api',
                        p_pattern            => 'getComponentSuggestion',
                        p_method             => 'POST',
                        p_name               => 'http_status_code',
                        p_bind_variable_name => 'http_status_code',
                        p_param_type         => 'INT',
                        p_access_method      => 'OUT');

  --
  COMMIT;
  --
END;
/
