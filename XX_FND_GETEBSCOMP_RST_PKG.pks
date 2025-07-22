CREATE OR REPLACE PACKAGE XX_FND_GETEBSCOMP_RST_PKG AS
 /*#
  * This is Package for ECSU - Search Utility
  * @rep:scope public
  * @rep:product FND
  * @rep:lifecycle active
  * @rep:displayname XX_FND_GETEBSCOMP_RST_PKG
  * @rep:compatibility S
  * @rep:category BUSINESS_ENTITY XX_ECSU
  */
  /*-------------------------------------------------------------------------------------------
  *********************************************************************************************
  Details : Package
  
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
  /*#
  * Procedure for oracle component search suggestions
  * @param p_suggestion_text VARCHAR2
  * @param p_comp_type VARCHAR2
  * @param x_suggestion_results VARCHAR2
  * @param x_error_msg VARCHAR2
  * @rep:displayname Search Suggestion Utility Procedure 
  * @rep:scope public
  * @rep:lifecycle active
  * @rep:category BUSINESS_ENTITY XX_ECSU
  */
  -- Procedure to get suggestions 
  PROCEDURE xx_get_compo_suggest_wrapper(p_suggestion_text      IN VARCHAR2,
                                         p_comp_type            IN VARCHAR2,
                                         x_suggestion_results   OUT VARCHAR2,
                                         x_error_msg            OUT VARCHAR2);
  /*#
  * Procedure to get oracle component details
  * @param p_component_name VARCHAR2
  * @param p_comp_type VARCHAR2
  * @param x_component_results VARCHAR2
  * @param x_error_message VARCHAR2
  * @rep:displayname Search Utility Procedure 
  * @rep:scope public
  * @rep:lifecycle active
  * @rep:category BUSINESS_ENTITY XX_ECSU
  */
  -- Procedure to get component details
  PROCEDURE xx_get_compo_dets_wrapper(p_component_name       IN VARCHAR2,
                                      p_comp_type            IN VARCHAR2,
                                      x_component_results    OUT VARCHAR2,
                                      x_error_msg            OUT VARCHAR2);

END XX_FND_GETEBSCOMP_RST_PKG;
/
