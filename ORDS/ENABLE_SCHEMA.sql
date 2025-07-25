BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled             => TRUE,
        p_schema              => 'APPS',
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'apps',
        p_auto_rest_auth      => FALSE
    );
    COMMIT;
END;
/
