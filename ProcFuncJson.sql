CREATE OR REPLACE FUNCTION f_constroi_json_energia (
    p_id_usuario     IN ES_USUARIO.ID_USUARIO%TYPE,
    p_nome_usuario   IN ES_USUARIO.DS_NOME%TYPE,
    p_email_usuario  IN ES_USUARIO.DS_EMAIL%TYPE,
    p_id_local       IN ES_LOCAL.ID_LOCAL%TYPE,
    p_nome_local     IN ES_LOCAL.DS_NOME%TYPE,
    p_id_sensor      IN ES_SENSOR.ID_SENSOR%TYPE,
    p_status_sensor  IN ES_SENSOR.DS_STATUS%TYPE,
    p_consumo_padrao IN ES_SENSOR.NR_CONSUMO_PADRAO%TYPE,
    p_id_consumo     IN ES_CONSUMO.ID_CONSUMO%TYPE,
    p_kwh_consumido  IN ES_CONSUMO.NR_KWH%TYPE,
    p_data_consumo   IN ES_CONSUMO.DT_CONSUMO%TYPE
) RETURN CLOB IS
    v_json CLOB;
    
  FUNCTION f_json_field(
      p_field_name IN VARCHAR2,
      p_field_value IN VARCHAR2
  ) RETURN CLOB IS
      v_field CLOB;
  BEGIN
      IF p_field_value IS NULL OR p_field_value = '""' THEN
          v_field := '"' || p_field_name || '": null';
      ELSE
          v_field := '"' || p_field_name || '": "' || p_field_value || '"';
      END IF;

      RETURN v_field;
  END;

BEGIN
    v_json := '{' ||
              f_json_field('id_usuario', TO_CHAR(p_id_usuario)) || ', ' ||
              f_json_field('nome_usuario', p_nome_usuario) || ', ' ||
              f_json_field('email_usuario', p_email_usuario) || ', ' ||
              f_json_field('id_local', TO_CHAR(p_id_local)) || ', ' ||
              f_json_field('nome_local', p_nome_local) || ', ' ||
              f_json_field('id_sensor', TO_CHAR(p_id_sensor)) || ', ' ||
              f_json_field('status_sensor', p_status_sensor) || ', ' ||
              f_json_field('consumo_padrao', TO_CHAR(p_consumo_padrao)) || ', ' ||
              f_json_field('id_consumo', TO_CHAR(p_id_consumo)) || ', ' ||
              f_json_field('kwh_consumido', TO_CHAR(p_kwh_consumido)) || ', ' ||
              f_json_field('data_consumo', TO_CHAR(p_data_consumo, 'YYYY-MM-DD')) || '}';

    RETURN v_json;

EXCEPTION
    WHEN VALUE_ERROR THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro de valor: Um dos parâmetros está nulo ou contém um valor inválido.');

    WHEN INVALID_NUMBER THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro de conversão de tipo: Um número inválido foi fornecido.');

    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Erro inesperado: ' || SQLERRM);
END;
/

---------------

CREATE OR REPLACE PROCEDURE p_retorna_json_energia (p_retorno OUT CLOB) IS
    v_json CLOB := '[';
BEGIN
    SELECT LISTAGG(f_constroi_json_energia(
        u.ID_USUARIO,
        u.DS_NOME,
        u.DS_EMAIL,
        l.ID_LOCAL,
        l.DS_NOME,
        s.ID_SENSOR,
        s.DS_STATUS,
        s.NR_CONSUMO_PADRAO,
        c.ID_CONSUMO,
        c.NR_KWH,
        c.DT_CONSUMO
    ), ',') WITHIN GROUP (ORDER BY u.ID_USUARIO)
    INTO v_json
    FROM ES_USUARIO u
    LEFT JOIN ES_LOCAL l ON l.ID_LOCAL = u.ID_USUARIO
    LEFT JOIN ES_SENSOR s ON s.ID_SENSOR = l.ID_LOCAL
    LEFT JOIN ES_CONSUMO c ON c.ID_CONSUMO = s.ID_SENSOR;

    IF v_json IS NULL THEN
        RAISE NO_DATA_FOUND;
    END IF;

    v_json := '[' || v_json || ']';
    p_retorno := v_json;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_retorno := '[{ "error": "Nenhum dado foi encontrado: ' || regexp_replace(sqlerrm, '"', '') || '"}]';
    WHEN VALUE_ERROR THEN
        p_retorno := '[{ "error": "Erro ao processar valores durante a construção do JSON: ' || regexp_replace(sqlerrm, '"', '') || '"}]';
    WHEN OTHERS THEN
        p_retorno := '[{ "error": "Erro inesperado: ' || regexp_replace(sqlerrm, '"', '') || '"}]';
END;
/

--------------- TESTE -----------------

DECLARE
   texto CLOB;
BEGIN
   p_retorna_json_energia(texto);
   DBMS_OUTPUT.PUT_LINE(texto);  
END;
/
