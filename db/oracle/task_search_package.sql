-- Oracle PL/SQL package for task search
-- This is a reference artifact — it does not run locally against H2.
-- It mirrors the logic used by the Spring Data repository and is
-- representative of the kind of Oracle PL/SQL found in production.

CREATE OR REPLACE PACKAGE task_search_pkg AS

    TYPE task_record IS RECORD (
        id          NUMBER,
        title       VARCHAR2(255),
        description VARCHAR2(1000),
        status      VARCHAR2(20),
        priority    VARCHAR2(10),
        assignee    VARCHAR2(100),
        created_at  TIMESTAMP
    );

    TYPE task_cursor IS REF CURSOR RETURN task_record;

    PROCEDURE search_tasks(
        p_search_term IN  VARCHAR2 DEFAULT NULL,
        p_status      IN  VARCHAR2 DEFAULT NULL,
        p_page        IN  NUMBER   DEFAULT 1,
        p_page_size   IN  NUMBER   DEFAULT 10,
        p_results     OUT task_cursor,
        p_total_count OUT NUMBER
    );

END task_search_pkg;
/

CREATE OR REPLACE PACKAGE BODY task_search_pkg AS

    PROCEDURE search_tasks(
        p_search_term IN  VARCHAR2 DEFAULT NULL,
        p_status      IN  VARCHAR2 DEFAULT NULL,
        p_page        IN  NUMBER   DEFAULT 1,
        p_page_size   IN  NUMBER   DEFAULT 10,
        p_results     OUT task_cursor,
        p_total_count OUT NUMBER
    ) IS
        -- Max PL/SQL size, so long input cannot cause ORA-06502.
        v_term     VARCHAR2(32767);
        v_status   VARCHAR2(32767);
        v_page     NUMBER;
        v_size     NUMBER;
        v_offset   NUMBER;
    BEGIN
        -- Escape \ % _ so user text is matched literally (Oracle has no default LIKE escape).
        v_term := '%' || REPLACE(REPLACE(REPLACE(LOWER(TRIM(p_search_term)),
                      '\', '\\'), '%', '\%'), '_', '\_') || '%';

        -- Match the API: status is case-insensitive, and bad paging values fall back to safe ones.
        v_status := UPPER(TRIM(p_status));
        v_page   := GREATEST(NVL(p_page, 1), 1);
        v_size   := LEAST(GREATEST(NVL(p_page_size, 10), 1), 100);
        v_offset := (v_page - 1) * v_size;

        -- Total count for pagination metadata.
        -- Brackets around the two LIKEs are required: AND runs before OR.
        SELECT COUNT(*)
          INTO p_total_count
          FROM tasks
         WHERE archived = 0
           AND (LOWER(title) LIKE v_term ESCAPE '\'
                OR LOWER(description) LIKE v_term ESCAPE '\')
           AND (v_status IS NULL OR status = v_status);

        -- Paginated results using ROWNUM (pre-12c pattern)
        OPEN p_results FOR
            SELECT id, title, description, status, priority, assignee, created_at
              FROM (
                  SELECT t.*, ROWNUM AS rn
                    FROM (
                        SELECT id, title, description, status, priority,
                               assignee, created_at
                          FROM tasks
                         WHERE archived = 0
                           AND (LOWER(title) LIKE v_term ESCAPE '\'
                                OR LOWER(description) LIKE v_term ESCAPE '\')
                           AND (v_status IS NULL OR status = v_status)
                         ORDER BY created_at DESC, id DESC
                    ) t
                   WHERE ROWNUM <= v_offset + v_size
              )
             WHERE rn > v_offset;

    END search_tasks;

END task_search_pkg;
/
