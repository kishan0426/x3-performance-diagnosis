SET DEFINE ON
SET VERIFY OFF
SET FEEDBACK OFF
SET HEADING OFF
SET PAGESIZE 0
SET LINESIZE 1000
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET TAB OFF
SET TRIMSPOOL ON
SET SERVEROUTPUT ON SIZE UNLIMITED

DEFINE wh_count        = 12
DEFINE wh_interval     = 5
DEFINE wh_top          = 5
DEFINE wh_filter       = ALL

DEFINE wh_mode         = ROOTCAUSE
DEFINE wh_depth        = DEEP

DEFINE wh_dashboard    = Y
DEFINE wh_graph        = Y
DEFINE wh_summary      = Y
DEFINE wh_evidence     = Y

DEFINE wh_sql          = Y
DEFINE wh_sql_text     = Y
DEFINE wh_sql_top      = 5

DEFINE wh_plan         = Y
DEFINE wh_plan_sort    = ELAPSED
DEFINE wh_plan_top     = 5

DEFINE wh_process      = Y
DEFINE wh_blocker      = Y
DEFINE wh_chain        = Y
DEFINE wh_chain_depth  = 10
DEFINE wh_blockers     = Y

DEFINE wh_io           = Y
DEFINE wh_io_detail    = Y
DEFINE wh_file_detail  = Y

DEFINE wh_lgwr         = Y
DEFINE wh_dbwr         = Y
DEFINE wh_ckpt         = Y
DEFINE wh_arch         = Y

DEFINE wh_controlfile  = Y
DEFINE wh_redo         = Y
DEFINE wh_datafile     = Y
DEFINE wh_temp         = Y

DEFINE wh_resource_limit = Y
DEFINE wh_temp_sql       = Y
DEFINE wh_undo_sql       = Y
DEFINE wh_redo_sql       = Y
DEFINE wh_resource_top   = 10

DEFINE wh_activity       = Y
DEFINE wh_activity_graph = Y
DEFINE wh_activity_top   = 5

DEFINE wh_rootcause    = Y
DEFINE wh_dependency   = Y
DEFINE wh_confidence   = Y

DEFINE wh_rac          = Y
DEFINE wh_gc_detail    = Y

DEFINE wh_kernel       = Y
DEFINE wh_p123         = Y
DEFINE wh_history      = Y
DEFINE wh_baseline     = Y

DEFINE wh_min_wait_ms  = 1
DEFINE wh_root_ms      = 5
DEFINE wh_high_ms      = 10

DECLARE
  l_count        PLS_INTEGER := &wh_count;
  l_interval     NUMBER      := &wh_interval;
  l_top          PLS_INTEGER := &wh_top;
  l_filter       VARCHAR2(10) := UPPER(TRIM('&wh_filter'));
  l_mode         VARCHAR2(20) := UPPER(TRIM('&wh_mode'));
  l_depth        VARCHAR2(12) := UPPER(TRIM('&wh_depth'));

  l_dashboard    VARCHAR2(1) := UPPER(TRIM('&wh_dashboard'));
  l_graph        VARCHAR2(1) := UPPER(TRIM('&wh_graph'));
  l_summary      VARCHAR2(1) := UPPER(TRIM('&wh_summary'));
  l_evidence     VARCHAR2(1) := UPPER(TRIM('&wh_evidence'));

  l_sql          VARCHAR2(1) := UPPER(TRIM('&wh_sql'));
  l_sql_text     VARCHAR2(1) := UPPER(TRIM('&wh_sql_text'));
  l_sql_top      PLS_INTEGER := &wh_sql_top;

  l_plan         VARCHAR2(1) := UPPER(TRIM('&wh_plan'));
  l_plan_sort    VARCHAR2(10) := UPPER(TRIM('&wh_plan_sort'));
  l_plan_top     PLS_INTEGER := &wh_plan_top;

  l_process      VARCHAR2(1) := UPPER(TRIM('&wh_process'));
  l_blocker      VARCHAR2(1) := UPPER(TRIM('&wh_blocker'));
  l_chain        VARCHAR2(1) := UPPER(TRIM('&wh_chain'));
  l_chain_depth  PLS_INTEGER := &wh_chain_depth;
  l_blockers     VARCHAR2(1) := UPPER(TRIM('&wh_blockers'));

  l_io           VARCHAR2(1) := UPPER(TRIM('&wh_io'));
  l_io_detail    VARCHAR2(1) := UPPER(TRIM('&wh_io_detail'));
  l_file_detail  VARCHAR2(1) := UPPER(TRIM('&wh_file_detail'));

  l_lgwr         VARCHAR2(1) := UPPER(TRIM('&wh_lgwr'));
  l_dbwr         VARCHAR2(1) := UPPER(TRIM('&wh_dbwr'));
  l_ckpt         VARCHAR2(1) := UPPER(TRIM('&wh_ckpt'));
  l_arch         VARCHAR2(1) := UPPER(TRIM('&wh_arch'));

  l_controlfile  VARCHAR2(1) := UPPER(TRIM('&wh_controlfile'));
  l_redo         VARCHAR2(1) := UPPER(TRIM('&wh_redo'));
  l_datafile     VARCHAR2(1) := UPPER(TRIM('&wh_datafile'));
  l_temp         VARCHAR2(1) := UPPER(TRIM('&wh_temp'));

  l_resource_limit VARCHAR2(1) := UPPER(TRIM('&wh_resource_limit'));
  l_temp_sql       VARCHAR2(1) := UPPER(TRIM('&wh_temp_sql'));
  l_undo_sql       VARCHAR2(1) := UPPER(TRIM('&wh_undo_sql'));
  l_redo_sql       VARCHAR2(1) := UPPER(TRIM('&wh_redo_sql'));
  l_resource_top  PLS_INTEGER := &wh_resource_top;
  l_activity       VARCHAR2(1) := UPPER(TRIM('&wh_activity'));
  l_activity_graph VARCHAR2(1) := UPPER(TRIM('&wh_activity_graph'));
  l_activity_top   PLS_INTEGER := &wh_activity_top;

  l_rootcause    VARCHAR2(1) := UPPER(TRIM('&wh_rootcause'));
  l_dependency   VARCHAR2(1) := UPPER(TRIM('&wh_dependency'));
  l_confidence   VARCHAR2(1) := UPPER(TRIM('&wh_confidence'));

  l_rac          VARCHAR2(1) := UPPER(TRIM('&wh_rac'));
  l_gc_detail    VARCHAR2(1) := UPPER(TRIM('&wh_gc_detail'));

  l_kernel       VARCHAR2(1) := UPPER(TRIM('&wh_kernel'));
  l_p123         VARCHAR2(1) := UPPER(TRIM('&wh_p123'));
  l_history      VARCHAR2(1) := UPPER(TRIM('&wh_history'));
  l_baseline     VARCHAR2(1) := UPPER(TRIM('&wh_baseline'));

  l_min_wait_ms  NUMBER := &wh_min_wait_ms;
  l_root_ms      NUMBER := &wh_root_ms;
  l_high_ms      NUMBER := &wh_high_ms;

  l_sample       PLS_INTEGER := 0;

  TYPE t_prev IS RECORD(total_waits NUMBER, wait_cs NUMBER);
  TYPE t_prev_tab IS TABLE OF t_prev INDEX BY VARCHAR2(700);
  g_prev t_prev_tab;

  TYPE t_redo_prev IS RECORD(bytes NUMBER);
  TYPE t_redo_prev_tab IS TABLE OF t_redo_prev INDEX BY VARCHAR2(100);
  g_prev_redo t_redo_prev_tab;
  TYPE t_redo_sql IS RECORD(sql_id VARCHAR2(13), bytes NUMBER);
  TYPE t_redo_sql_tab IS TABLE OF t_redo_sql INDEX BY VARCHAR2(30);
  g_redo_sql t_redo_sql_tab;

  TYPE t_sqlact_prev IS RECORD(parse_calls NUMBER, executions NUMBER, cpu_us NUMBER, elapsed_us NUMBER);
  TYPE t_sqlact_prev_tab IS TABLE OF t_sqlact_prev INDEX BY VARCHAR2(100);
  g_prev_sqlact t_sqlact_prev_tab;
  TYPE t_sqlact IS RECORD(sql_id VARCHAR2(13), parse_calls NUMBER, executions NUMBER, cpu_us NUMBER, wait_us NUMBER);
  TYPE t_sqlact_tab IS TABLE OF t_sqlact INDEX BY VARCHAR2(100);
  g_sqlact t_sqlact_tab;
  TYPE t_sample_activity IS RECORD(parse_calls NUMBER, executions NUMBER, cpu_us NUMBER, wait_us NUMBER);
  TYPE t_sample_activity_tab IS TABLE OF t_sample_activity INDEX BY PLS_INTEGER;
  g_activity_samples t_sample_activity_tab;
  g_sample_parse NUMBER := 0;
  g_sample_exec NUMBER := 0;
  g_sample_cpu_us NUMBER := 0;
  g_sample_wait_us NUMBER := 0;
  g_activity_cpu_max NUMBER := 0;
  g_activity_wait_max NUMBER := 0;

  TYPE t_event IS RECORD(event VARCHAR2(128), wait_class VARCHAR2(64), waits NUMBER, wait_cs NUMBER);
  TYPE t_event_tab IS TABLE OF t_event INDEX BY VARCHAR2(128);
  g_evt t_event_tab;
  g_total t_event_tab;

  TYPE t_sql IS RECORD(inst_id NUMBER, sql_id VARCHAR2(13), child_no NUMBER, waits NUMBER, wait_cs NUMBER, sql_text VARCHAR2(1000));
  TYPE t_sql_tab IS TABLE OF t_sql INDEX BY VARCHAR2(100);
  g_sql t_sql_tab;

  TYPE t_func_io IS RECORD(function_name VARCHAR2(30), waits NUMBER, wait_ms NUMBER);
  TYPE t_func_io_tab IS TABLE OF t_func_io INDEX BY VARCHAR2(30);
  g_prev_func t_func_io_tab;
  g_cur_func  t_func_io_tab;

  TYPE t_file_io IS RECORD(function_name VARCHAR2(30), filetype_name VARCHAR2(50), waits NUMBER, wait_ms NUMBER, write_mb NUMBER, write_reqs NUMBER);
  TYPE t_file_io_tab IS TABLE OF t_file_io INDEX BY VARCHAR2(150);
  g_prev_file t_file_io_tab;
  g_cur_file  t_file_io_tab;

  TYPE t_graph IS RECORD(waits NUMBER, wait_cs NUMBER);
  TYPE t_graph_tab IS TABLE OF t_graph INDEX BY PLS_INTEGER;
  g_graph t_graph_tab;
  g_graph_max NUMBER := 0;

  g_sample_waits NUMBER := 0;
  g_sample_cs    NUMBER := 0;
  g_total_waits  NUMBER := 0;
  g_total_cs     NUMBER := 0;

  g_root_cause VARCHAR2(500);
  g_root_conf  VARCHAR2(30);
  g_root_chain VARCHAR2(4000);
  g_root_evidence VARCHAR2(12000);

  FUNCTION n(p NUMBER) RETURN VARCHAR2 IS BEGIN RETURN TO_CHAR(NVL(p,0),'FM999999999999990'); END;
  FUNCTION d(p NUMBER) RETURN VARCHAR2 IS BEGIN RETURN TO_CHAR(NVL(p,0),'FM999999990.00'); END;
  FUNCTION s(p NUMBER) RETURN VARCHAR2 IS BEGIN RETURN d(NVL(p,0)/100); END;

  FUNCTION yn(p VARCHAR2) RETURN BOOLEAN IS BEGIN RETURN UPPER(p)='Y'; END;

  FUNCTION op_class(p_cmd NUMBER, p_sql VARCHAR2) RETURN VARCHAR2 IS
    x VARCHAR2(4000) := UPPER(NVL(p_sql,''));
  BEGIN
    IF REGEXP_LIKE(x,'^[[:space:]]*(SELECT|INSERT|UPDATE|DELETE|MERGE)([[:space:]]|$)') THEN RETURN 'DML'; END IF;
    IF REGEXP_LIKE(x,'^[[:space:]]*(COMMIT|ROLLBACK|SAVEPOINT)([[:space:]]|$)') THEN RETURN 'TCL'; END IF;
    IF REGEXP_LIKE(x,'^[[:space:]]*(CREATE|ALTER|DROP|TRUNCATE|RENAME|COMMENT|GRANT|REVOKE)([[:space:]]|$)') THEN RETURN 'DDL'; END IF;
    IF p_cmd = 2 OR p_cmd = 3 OR p_cmd = 6 OR p_cmd = 7 OR p_cmd = 85 THEN
      RETURN 'DML';
    ELSIF p_cmd = 44 OR p_cmd = 45 THEN
      RETURN 'TCL';
    ELSE
      RETURN 'OTHER';
    END IF;
  END;

  FUNCTION passes_filter(p_op VARCHAR2) RETURN BOOLEAN IS
  BEGIN RETURN l_filter='ALL' OR l_filter=p_op; END;

  FUNCTION key_of(p_inst NUMBER,p_sid NUMBER,p_ser NUMBER,p_event VARCHAR2) RETURN VARCHAR2 IS
  BEGIN RETURN p_inst||':'||p_sid||':'||p_ser||':'||NVL(p_event,'<NULL>'); END;

  PROCEDURE reset_sample IS
  BEGIN
    g_evt.DELETE; g_sql.DELETE; g_cur_func.DELETE; g_cur_file.DELETE; g_sqlact.DELETE;
    g_sample_parse:=0; g_sample_exec:=0; g_sample_cpu_us:=0; g_sample_wait_us:=0;
    g_sample_waits:=0; g_sample_cs:=0;
    g_root_cause:=NULL; g_root_conf:=NULL; g_root_chain:=NULL; g_root_evidence:=NULL;
  END;

  PROCEDURE add_event(p_event VARCHAR2,p_class VARCHAR2,p_waits NUMBER,p_cs NUMBER) IS
  BEGIN
    IF g_evt.EXISTS(p_event) THEN
      g_evt(p_event).waits:=g_evt(p_event).waits+p_waits;
      g_evt(p_event).wait_cs:=g_evt(p_event).wait_cs+p_cs;
    ELSE
      g_evt(p_event).event:=p_event; g_evt(p_event).wait_class:=p_class; g_evt(p_event).waits:=p_waits; g_evt(p_event).wait_cs:=p_cs;
    END IF;
  END;

  PROCEDURE add_total(p_event VARCHAR2,p_class VARCHAR2,p_waits NUMBER,p_cs NUMBER) IS
  BEGIN
    IF g_total.EXISTS(p_event) THEN
      g_total(p_event).waits:=g_total(p_event).waits+p_waits;
      g_total(p_event).wait_cs:=g_total(p_event).wait_cs+p_cs;
    ELSE
      g_total(p_event).event:=p_event; g_total(p_event).wait_class:=p_class; g_total(p_event).waits:=p_waits; g_total(p_event).wait_cs:=p_cs;
    END IF;
  END;

  PROCEDURE add_sql(p_inst NUMBER,p_sqlid VARCHAR2,p_child NUMBER,p_waits NUMBER,p_cs NUMBER,p_text VARCHAR2) IS
    k VARCHAR2(100):=p_inst||'|'||p_sqlid||'|'||p_child;
  BEGIN
    IF p_sqlid IS NULL THEN RETURN; END IF;
    IF g_sql.EXISTS(k) THEN
      g_sql(k).waits:=g_sql(k).waits+p_waits; g_sql(k).wait_cs:=g_sql(k).wait_cs+p_cs;
    ELSE
      g_sql(k).inst_id:=p_inst; g_sql(k).sql_id:=p_sqlid; g_sql(k).child_no:=p_child; g_sql(k).waits:=p_waits; g_sql(k).wait_cs:=p_cs; g_sql(k).sql_text:=p_text;
    END IF;
  END;

  PROCEDURE collect_io IS
    k VARCHAR2(150);
  BEGIN
    FOR r IN (SELECT function_name,NVL(number_of_waits,0) waits,NVL(wait_time,0) wait_ms FROM v$iostat_function WHERE function_name IN ('LGWR','DBWR','CKPT','ARCH')) LOOP
      g_cur_func(r.function_name).function_name:=r.function_name; g_cur_func(r.function_name).waits:=r.waits; g_cur_func(r.function_name).wait_ms:=r.wait_ms;
    END LOOP;
    FOR r IN (SELECT function_name,filetype_name,NVL(number_of_waits,0) waits,NVL(wait_time,0) wait_ms,NVL(small_write_megabytes,0)+NVL(large_write_megabytes,0) write_mb,NVL(small_write_reqs,0)+NVL(large_write_reqs,0) write_reqs FROM v$iostat_function_detail WHERE filetype_name IN ('Control File','Data File','Log File','Temp File')) LOOP
      k:=r.function_name||'|'||r.filetype_name;
      g_cur_file(k).function_name:=r.function_name; g_cur_file(k).filetype_name:=r.filetype_name; g_cur_file(k).waits:=r.waits; g_cur_file(k).wait_ms:=r.wait_ms; g_cur_file(k).write_mb:=r.write_mb; g_cur_file(k).write_reqs:=r.write_reqs;
    END LOOP;
  END;

  FUNCTION func_delta(p_name VARCHAR2,p_metric VARCHAR2) RETURN NUMBER IS
    c NUMBER:=0; o NUMBER:=0;
  BEGIN
    IF NOT g_cur_func.EXISTS(p_name) THEN RETURN 0; END IF;
    IF p_metric='WAITS' THEN c:=g_cur_func(p_name).waits; IF g_prev_func.EXISTS(p_name) THEN o:=g_prev_func(p_name).waits; END IF; END IF;
    IF p_metric='WAIT_MS' THEN c:=g_cur_func(p_name).wait_ms; IF g_prev_func.EXISTS(p_name) THEN o:=g_prev_func(p_name).wait_ms; END IF; END IF;
    RETURN GREATEST(c-o,0);
  END;

  FUNCTION file_delta(p_filetype VARCHAR2,p_metric VARCHAR2) RETURN NUMBER IS
    k VARCHAR2(150); c NUMBER:=0; o NUMBER:=0;
  BEGIN
    k:=g_cur_file.FIRST;
    WHILE k IS NOT NULL LOOP
      IF g_cur_file(k).filetype_name=p_filetype THEN
        IF p_metric='WAITS' THEN c:=c+g_cur_file(k).waits; IF g_prev_file.EXISTS(k) THEN o:=o+g_prev_file(k).waits; END IF; END IF;
        IF p_metric='WAIT_MS' THEN c:=c+g_cur_file(k).wait_ms; IF g_prev_file.EXISTS(k) THEN o:=o+g_prev_file(k).wait_ms; END IF; END IF;
        IF p_metric='WRITE_MB' THEN c:=c+g_cur_file(k).write_mb; IF g_prev_file.EXISTS(k) THEN o:=o+g_prev_file(k).write_mb; END IF; END IF;
        IF p_metric='WRITE_REQS' THEN c:=c+g_cur_file(k).write_reqs; IF g_prev_file.EXISTS(k) THEN o:=o+g_prev_file(k).write_reqs; END IF; END IF;
      END IF;
      k:=g_cur_file.NEXT(k);
    END LOOP;
    RETURN GREATEST(c-o,0);
  END;

  FUNCTION bg_event(p_name VARCHAR2) RETURN VARCHAR2 IS x VARCHAR2(128);
  BEGIN
    SELECT MAX(s.event) INTO x FROM gv$bgprocess b JOIN gv$session s ON s.inst_id=b.inst_id AND s.paddr=b.paddr WHERE b.name=p_name AND s.status='ACTIVE';
    RETURN x;
  EXCEPTION WHEN OTHERS THEN RETURN NULL; END;

  PROCEDURE show_bg(p_name VARCHAR2) IS
  BEGIN
    FOR r IN (SELECT s.inst_id,s.sid,s.serial#,s.state,s.event,s.wait_class,s.p1text,s.p1,s.p2text,s.p2,s.p3text,s.p3 FROM gv$bgprocess b JOIN gv$session s ON s.inst_id=b.inst_id AND s.paddr=b.paddr WHERE b.name=p_name) LOOP
      DBMS_OUTPUT.PUT_LINE('    '||p_name||' INST='||r.inst_id||' SID='||r.sid||','||r.serial#||' state='||NVL(r.state,'-')||' event='||NVL(r.event,'ON CPU'));
      IF yn(l_p123) THEN DBMS_OUTPUT.PUT_LINE('      p1='||NVL(r.p1text,'-')||'='||NVL(TO_CHAR(r.p1),'-')||' p2='||NVL(r.p2text,'-')||'='||NVL(TO_CHAR(r.p2),'-')||' p3='||NVL(r.p3text,'-')||'='||NVL(TO_CHAR(r.p3),'-')); END IF;
    END LOOP;
  END;

  PROCEDURE wait_chain(p_pattern VARCHAR2) IS
    c NUMBER:=0;
    shown NUMBER:=0;
  BEGIN
    IF NOT yn(l_chain) OR NOT yn(l_blocker) THEN RETURN; END IF;
    DBMS_OUTPUT.PUT_LINE('  BLOCKER CHAIN');
    FOR r IN (SELECT chain_id,instance,sid,sess_serial#,wait_event_text,blocker_is_valid,blocker_instance,blocker_sid,blocker_sess_serial#,num_waiters,chain_is_cycle FROM v$wait_chains WHERE in_wait='TRUE' AND (p_pattern IS NULL OR wait_event_text LIKE p_pattern) ORDER BY chain_id,instance,sid) LOOP
      c:=c+1;
      IF shown < l_chain_depth THEN
      shown:=shown+1;
      DBMS_OUTPUT.PUT_LINE('    CHAIN='||r.chain_id||' WAITER='||r.instance||':'||r.sid||','||r.sess_serial#||' EVENT='||NVL(r.wait_event_text,'-'));
      IF r.blocker_is_valid='TRUE' THEN DBMS_OUTPUT.PUT_LINE('      BLOCKER='||r.blocker_instance||':'||r.blocker_sid||','||r.blocker_sess_serial#); ELSE DBMS_OUTPUT.PUT_LINE('      BLOCKER=NONE VISIBLE'); END IF;
      IF r.num_waiters IS NOT NULL THEN DBMS_OUTPUT.PUT_LINE('      DOWNSTREAM='||n(r.num_waiters)); END IF;
      IF r.chain_is_cycle='TRUE' THEN DBMS_OUTPUT.PUT_LINE('      WARNING=CYCLIC CHAIN'); END IF;
      END IF;
    END LOOP;
    IF c=0 THEN DBMS_OUTPUT.PUT_LINE('    none'); END IF;
  END;

  PROCEDURE print_plan(p_sql_id VARCHAR2) IS
    l_inst NUMBER; l_child NUMBER; l_hash NUMBER;
  BEGIN
    SELECT MAX(inst_id),MAX(child_number),MAX(plan_hash_value) INTO l_inst,l_child,l_hash FROM gv$sql WHERE sql_id=p_sql_id;
    IF l_inst IS NULL THEN DBMS_OUTPUT.PUT_LINE('  PLAN unavailable for '||p_sql_id); RETURN; END IF;
    DBMS_OUTPUT.PUT_LINE('  PLAN TREE  SQL_ID='||p_sql_id||' CHILD='||l_child||' HASH='||l_hash);
    FOR r IN (SELECT p.id,p.depth,p.operation,p.options,p.object_name,p.cardinality e_rows,ps.last_output_rows a_rows,ps.last_elapsed_time elapsed_us,NVL(ps.last_cr_buffer_gets,0)+NVL(ps.last_cu_buffer_gets,0) buffers,ps.last_disk_reads reads FROM gv$sql_plan p LEFT OUTER JOIN gv$sql_plan_statistics_all ps ON ps.inst_id=p.inst_id AND ps.sql_id=p.sql_id AND ps.child_number=p.child_number AND ps.plan_hash_value=p.plan_hash_value AND ps.id=p.id WHERE p.inst_id=l_inst AND p.sql_id=p_sql_id AND p.child_number=l_child ORDER BY p.id) LOOP
      DBMS_OUTPUT.PUT_LINE(RPAD(r.id,5)||RPAD(RPAD(' ',NVL(r.depth,0)*2,' ')||NVL(r.operation,'-')||NVL(' '||r.options,'')||NVL(' '||r.object_name,''),62)||LPAD(n(r.e_rows),10)||LPAD(n(r.a_rows),10)||LPAD(d(NVL(r.elapsed_us,0)/1000),10)||LPAD(n(r.buffers),12)||LPAD(n(r.reads),10));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('  PLAN HOTSPOTS SORT='||l_plan_sort);
    FOR r IN (SELECT rank_no,id,operation,options,object_name,e_rows,a_rows,elapsed_us,buffers,reads FROM (SELECT ROW_NUMBER() OVER (ORDER BY CASE l_plan_sort WHEN 'ELAPSED' THEN NVL(ps.last_elapsed_time,0) WHEN 'BUFFER' THEN NVL(ps.last_cr_buffer_gets,0)+NVL(ps.last_cu_buffer_gets,0) WHEN 'READ' THEN NVL(ps.last_disk_reads,0) WHEN 'ROWS' THEN NVL(ps.last_output_rows,0) WHEN 'COST' THEN NVL(p.cost,0) ELSE NVL(ps.last_elapsed_time,0) END DESC,p.id) rank_no,p.id,p.operation,p.options,p.object_name,p.cardinality e_rows,ps.last_output_rows a_rows,ps.last_elapsed_time elapsed_us,NVL(ps.last_cr_buffer_gets,0)+NVL(ps.last_cu_buffer_gets,0) buffers,ps.last_disk_reads reads FROM gv$sql_plan p LEFT OUTER JOIN gv$sql_plan_statistics_all ps ON ps.inst_id=p.inst_id AND ps.sql_id=p.sql_id AND ps.child_number=p.child_number AND ps.plan_hash_value=p.plan_hash_value AND ps.id=p.id WHERE p.inst_id=l_inst AND p.sql_id=p_sql_id AND p.child_number=l_child) WHERE rank_no<=l_plan_top ORDER BY rank_no) LOOP
      DBMS_OUTPUT.PUT_LINE('    '||RPAD(n(r.rank_no),4)||' ID='||RPAD(n(r.id),4)||' '||RPAD(SUBSTR(r.operation||NVL(' '||r.options,''),1,34),35)||RPAD(SUBSTR(NVL(r.object_name,'-'),1,24),25)||' E='||LPAD(n(r.e_rows),8)||' A='||LPAD(n(r.a_rows),8)||' ms='||LPAD(d(NVL(r.elapsed_us,0)/1000),9)||' B='||LPAD(n(r.buffers),9)||' R='||LPAD(n(r.reads),8));
    END LOOP;
  END;

  PROCEDURE diag_control_write IS
    p1 NUMBER:=0; p2 NUMBER:=0; p3 NUMBER:=0; active_cnt NUMBER:=0; cf_cnt NUMBER:=0; waits NUMBER; wait_ms NUMBER; avg_ms NUMBER; write_mb NUMBER; write_reqs NUMBER;
  BEGIN
    SELECT NVL(SUM(p1),0),NVL(SUM(p2),0),NVL(SUM(p3),0),COUNT(*) INTO p1,p2,p3,active_cnt FROM gv$session WHERE event='control file parallel write' AND status='ACTIVE';
    BEGIN SELECT COUNT(*) INTO cf_cnt FROM v$controlfile; EXCEPTION WHEN OTHERS THEN cf_cnt:=0; END;
    waits:=file_delta('Control File','WAITS'); wait_ms:=file_delta('Control File','WAIT_MS'); write_mb:=file_delta('Control File','WRITE_MB'); write_reqs:=file_delta('Control File','WRITE_REQS');
    IF waits>0 THEN avg_ms:=wait_ms/waits; ELSE avg_ms:=0; END IF;
    DBMS_OUTPUT.PUT_LINE('  CONTROL FILE I/O');
    DBMS_OUTPUT.PUT_LINE('    active waiters : '||n(active_cnt));
    DBMS_OUTPUT.PUT_LINE('    copies         : '||n(cf_cnt));
    DBMS_OUTPUT.PUT_LINE('    P1 files       : '||n(p1));
    DBMS_OUTPUT.PUT_LINE('    P2 blocks      : '||n(p2));
    DBMS_OUTPUT.PUT_LINE('    P3 requests    : '||n(p3));
    DBMS_OUTPUT.PUT_LINE('    I/O waits      : '||n(waits));
    DBMS_OUTPUT.PUT_LINE('    I/O wait       : '||d(wait_ms)||' ms');
    DBMS_OUTPUT.PUT_LINE('    average I/O    : '||d(avg_ms)||' ms');
    DBMS_OUTPUT.PUT_LINE('    write MB       : '||d(write_mb));
    DBMS_OUTPUT.PUT_LINE('    write reqs     : '||n(write_reqs));
    IF waits>0 AND avg_ms>=l_high_ms THEN g_root_cause:='CONTROL FILE STORAGE LATENCY'; g_root_conf:='HIGH'; g_root_chain:='control file parallel write -> Control File I/O -> storage'; g_root_evidence:='Average control-file I/O='||d(avg_ms)||' ms';
    ELSIF waits>0 AND avg_ms>=l_root_ms THEN g_root_cause:='ELEVATED CONTROL FILE I/O LATENCY'; g_root_conf:='MEDIUM'; g_root_chain:='control file parallel write -> Control File I/O'; g_root_evidence:='Average control-file I/O='||d(avg_ms)||' ms';
    ELSE g_root_cause:='CONTROL FILE WRITE ACTIVITY'; g_root_conf:='LOW'; g_root_chain:='control file parallel write -> Control File I/O'; g_root_evidence:='Activity observed without strong latency evidence'; END IF;
  END;

  PROCEDURE diag_control_read IS
    waits NUMBER; wait_ms NUMBER; avg_ms NUMBER;
  BEGIN
    waits:=file_delta('Control File','WAITS'); wait_ms:=file_delta('Control File','WAIT_MS'); IF waits>0 THEN avg_ms:=wait_ms/waits; ELSE avg_ms:=0; END IF;
    DBMS_OUTPUT.PUT_LINE('  CONTROL FILE READ');
    DBMS_OUTPUT.PUT_LINE('    waits   : '||n(waits)); DBMS_OUTPUT.PUT_LINE('    wait    : '||d(wait_ms)||' ms'); DBMS_OUTPUT.PUT_LINE('    average : '||d(avg_ms)||' ms');
    IF avg_ms>=l_high_ms THEN g_root_cause:='CONTROL FILE READ LATENCY'; g_root_conf:='HIGH'; g_root_chain:='control file sequential read -> Control File I/O -> storage'; g_root_evidence:='Average control-file read='||d(avg_ms)||' ms'; ELSE g_root_cause:='CONTROL FILE READ ACTIVITY'; g_root_conf:='LOW'; g_root_chain:='control file sequential read -> Control File I/O'; g_root_evidence:='Read activity without strong latency evidence'; END IF;
  END;

  PROCEDURE diag_lgwr IS
    le VARCHAR2(128); de VARCHAR2(128); ce VARCHAR2(128); lw NUMBER; lm NUMBER; la NUMBER; dw NUMBER; dm NUMBER; da NUMBER; syncs NUMBER:=0;
  BEGIN
    le:=bg_event('LGWR'); de:=bg_event('DBWR'); ce:=bg_event('CKPT'); lw:=func_delta('LGWR','WAITS'); lm:=func_delta('LGWR','WAIT_MS'); dw:=func_delta('DBWR','WAITS'); dm:=func_delta('DBWR','WAIT_MS'); IF lw>0 THEN la:=lm/lw; ELSE la:=0; END IF; IF dw>0 THEN da:=dm/dw; ELSE da:=0; END IF;
    DBMS_OUTPUT.PUT_LINE('  LGWR DEPENDENCY'); DBMS_OUTPUT.PUT_LINE('    LGWR : '||NVL(le,'ON CPU / NONE')); DBMS_OUTPUT.PUT_LINE('    DBWR : '||NVL(de,'ON CPU / NONE')); DBMS_OUTPUT.PUT_LINE('    CKPT : '||NVL(ce,'ON CPU / NONE')); DBMS_OUTPUT.PUT_LINE('    LGWR I/O : '||n(lw)||' waits / '||d(lm)||' ms / avg '||d(la)||' ms'); DBMS_OUTPUT.PUT_LINE('    DBWR I/O : '||n(dw)||' waits / '||d(dm)||' ms / avg '||d(da)||' ms'); IF yn(l_process) THEN IF yn(l_lgwr) THEN show_bg('LGWR'); END IF; IF yn(l_dbwr) THEN show_bg('DBWR'); END IF; IF yn(l_ckpt) THEN show_bg('CKPT'); END IF; END IF;
    BEGIN SELECT COUNT(*) INTO syncs FROM gv$archive_dest WHERE target='STANDBY' AND status='VALID' AND UPPER(NVL(transmit_mode,'-')) LIKE 'SYNC%'; EXCEPTION WHEN OTHERS THEN syncs:=0; END;
    IF le='log file parallel write' AND de='db file parallel write' AND da>=l_high_ms AND da>la THEN g_root_cause:='SHARED STORAGE WRITE LATENCY'; g_root_conf:='HIGH'; g_root_chain:='foreground -> log file sync -> LGWR + DBWR -> storage'; g_root_evidence:='LGWR avg='||d(la)||' ms; DBWR avg='||d(da)||' ms';
    ELSIF le='log file parallel write' THEN g_root_cause:='REDO LOG I/O LATENCY'; g_root_conf:='HIGH'; g_root_chain:='foreground -> log file sync -> LGWR -> log file parallel write -> redo I/O'; g_root_evidence:='LGWR avg I/O='||d(la)||' ms';
    ELSIF le='LGWR wait on SENDREQ' THEN g_root_cause:='SYNCHRONOUS DATA GUARD / REDO TRANSPORT'; g_root_conf:='HIGH'; g_root_chain:='foreground -> log file sync -> LGWR -> SENDREQ -> standby'; g_root_evidence:='VALID SYNC destinations='||n(syncs);
    ELSE g_root_cause:='LGWR COMMIT COMPLETION PATH'; g_root_conf:='MEDIUM'; g_root_chain:='foreground -> log file sync -> LGWR -> completion'; g_root_evidence:='LGWR current event='||NVL(le,'none'); END IF;
  END;

  PROCEDURE diag_dbwr IS
    de VARCHAR2(128); ce VARCHAR2(128); w NUMBER; m NUMBER; a NUMBER;
  BEGIN
    de:=bg_event('DBWR'); ce:=bg_event('CKPT'); w:=func_delta('DBWR','WAITS'); m:=func_delta('DBWR','WAIT_MS'); IF w>0 THEN a:=m/w; ELSE a:=0; END IF;
    DBMS_OUTPUT.PUT_LINE('  DBWR / CHECKPOINT'); DBMS_OUTPUT.PUT_LINE('    DBWR : '||NVL(de,'ON CPU / NONE')); DBMS_OUTPUT.PUT_LINE('    CKPT : '||NVL(ce,'ON CPU / NONE')); DBMS_OUTPUT.PUT_LINE('    DBWR I/O : '||n(w)||' waits / '||d(m)||' ms / avg '||d(a)||' ms'); IF yn(l_process) THEN IF yn(l_dbwr) THEN show_bg('DBWR'); END IF; IF yn(l_ckpt) THEN show_bg('CKPT'); END IF; END IF;
    IF de='db file parallel write' AND a>=l_root_ms THEN g_root_cause:='DBWR DATAFILE I/O LATENCY'; g_root_conf:='HIGH'; g_root_chain:='dirty-buffer pressure -> DBWR -> db file parallel write -> datafile storage'; g_root_evidence:='DBWR avg write='||d(a)||' ms'; ELSE g_root_cause:='DBWR / CHECKPOINT PRESSURE'; g_root_conf:='MEDIUM'; g_root_chain:='dirty buffers -> DBWR/CKPT -> datafile flush'; g_root_evidence:='DBWR='||NVL(de,'none')||'; CKPT='||NVL(ce,'none'); END IF;
  END;

  PROCEDURE diag_tx IS c NUMBER;
  BEGIN
    SELECT COUNT(*) INTO c FROM v$wait_chains WHERE in_wait='TRUE' AND wait_event_text LIKE 'enq: TX%';
    wait_chain('enq: TX%');
    IF c>0 THEN g_root_cause:='BLOCKING TRANSACTION / TX CONTENTION'; g_root_conf:='HIGH'; g_root_chain:='TX wait -> blocker -> holding transaction -> victims'; g_root_evidence:='Active TX chain rows='||n(c); ELSE g_root_cause:='TX CONTENTION WITHOUT VISIBLE BLOCKER'; g_root_conf:='MEDIUM'; g_root_chain:='TX wait -> transaction/ITL dependency'; g_root_evidence:='No active blocker visible'; END IF;
  END;

  PROCEDURE diag_tm IS c NUMBER;
  BEGIN
    SELECT COUNT(*) INTO c FROM v$wait_chains WHERE in_wait='TRUE' AND wait_event_text LIKE 'enq: TM%';
    wait_chain('enq: TM%');
    IF c>0 THEN g_root_cause:='TABLE-LEVEL LOCK CONTENTION'; g_root_conf:='HIGH'; g_root_chain:='TM wait -> blocker -> table/DDL/transaction dependency'; g_root_evidence:='Active TM chain rows='||n(c); ELSE g_root_cause:='TM CONTENTION'; g_root_conf:='MEDIUM'; g_root_chain:='TM wait -> table-level lock dependency'; g_root_evidence:='No active blocker visible'; END IF;
  END;

  PROCEDURE diag_hot IS f NUMBER; b NUMBER; q VARCHAR2(13);
  BEGIN
    SELECT MAX(p1),MAX(p2),MAX(sql_id) INTO f,b,q FROM gv$session WHERE event LIKE 'buffer busy waits%' AND status='ACTIVE';
    wait_chain('buffer busy%');
    g_root_cause:='HOT BLOCK / BUFFER CONTENTION'; g_root_conf:='HIGH'; g_root_chain:='buffer busy waits -> file/block -> object -> SQL'; g_root_evidence:='file='||n(f)||', block='||n(b)||', SQL_ID='||NVL(q,'-');
  END;

  PROCEDURE diag_read(p_event VARCHAR2) IS q VARCHAR2(13); f NUMBER; b NUMBER;
  BEGIN
    SELECT MAX(sql_id),MAX(p1),MAX(p2) INTO q,f,b FROM gv$session WHERE event=p_event AND status='ACTIVE';
    DBMS_OUTPUT.PUT_LINE('  READ'); DBMS_OUTPUT.PUT_LINE('    event='||p_event); DBMS_OUTPUT.PUT_LINE('    SQL_ID='||NVL(q,'-')||' file='||n(f)||' block='||n(b));
    IF l_plan='Y' AND q IS NOT NULL THEN print_plan(q); END IF;
    g_root_cause:='PHYSICAL READ / SQL PLAN I/O'; g_root_conf:='MEDIUM'; g_root_chain:=p_event||' -> SQL -> plan -> object -> physical I/O'; g_root_evidence:='SQL_ID='||NVL(q,'-')||', file='||n(f)||', block='||n(b);
  END;

  PROCEDURE diag_temp(p_event VARCHAR2) IS q VARCHAR2(13);
  BEGIN
    SELECT MAX(sql_id) INTO q FROM gv$session WHERE event=p_event AND status='ACTIVE';
    IF l_plan='Y' AND q IS NOT NULL THEN print_plan(q); END IF;
    g_root_cause:='TEMP I/O / WORKAREA SPILL'; g_root_conf:='MEDIUM'; g_root_chain:=p_event||' -> SQL -> sort/hash/workarea -> TEMP'; g_root_evidence:='SQL_ID='||NVL(q,'-');
  END;

  PROCEDURE diag_rac IS c NUMBER;
  BEGIN
    SELECT COUNT(*) INTO c FROM v$wait_chains WHERE in_wait='TRUE' AND (wait_event_text LIKE 'gc %' OR wait_event_text LIKE 'gcs %' OR wait_event_text LIKE 'ges %');
    wait_chain(NULL); g_root_cause:='RAC GLOBAL CACHE / INTER-INSTANCE CONTENTION'; g_root_conf:=CASE WHEN c>0 THEN 'HIGH' ELSE 'LOW' END; g_root_chain:='gc/gcs/ges -> remote instance -> global cache'; g_root_evidence:='Matching chain rows='||n(c);
  END;

  PROCEDURE diagnose IS
    e VARCHAR2(128); k VARCHAR2(128); mx NUMBER:=-1;
  BEGIN
    IF NOT yn(l_rootcause) THEN RETURN; END IF;

    k:=g_evt.FIRST; WHILE k IS NOT NULL LOOP IF g_evt(k).wait_cs>mx THEN mx:=g_evt(k).wait_cs; e:=g_evt(k).event; END IF; k:=g_evt.NEXT(k); END LOOP;
    IF e IS NULL THEN RETURN; END IF;
    IF e='control file parallel write' THEN diag_control_write;
    ELSIF e='control file sequential read' THEN diag_control_read;
    ELSIF (e='log file sync' OR e='log file parallel write') AND yn(l_lgwr) AND yn(l_redo) THEN diag_lgwr;
    ELSIF e='db file parallel write' THEN diag_dbwr;
    ELSIF e LIKE 'log file switch (checkpoint incomplete)%' THEN diag_dbwr; g_root_cause:='CHECKPOINT CANNOT ADVANCE FAST ENOUGH'; g_root_conf:='HIGH'; g_root_chain:='log switch -> checkpoint incomplete -> CKPT/DBWR -> datafile flush'; g_root_evidence:='Redo log reuse waits for checkpoint progress';
    ELSIF e LIKE 'log file switch (private strand flush incomplete)%' THEN diag_lgwr; diag_dbwr; g_root_cause:='PRIVATE STRAND FLUSH / DBWR PRESSURE'; g_root_conf:='HIGH'; g_root_chain:='log switch -> private strand flush -> LGWR/DBWR'; g_root_evidence:='Private-strand flush dependency detected';
    ELSIF e LIKE 'enq: TX%' THEN diag_tx;
    ELSIF e LIKE 'enq: TM%' THEN diag_tm;
    ELSIF e LIKE 'buffer busy waits%' THEN diag_hot;
    ELSIF e IN ('db file sequential read','db file scattered read','direct path read') THEN diag_read(e);
    ELSIF e IN ('direct path read temp','direct path write temp') AND yn(l_temp) THEN diag_temp(e);
    ELSIF (e LIKE 'gc %' OR e LIKE 'gcs %' OR e LIKE 'ges %') AND yn(l_rac) THEN diag_rac;
    ELSIF e LIKE '%library cache%' OR e LIKE 'cursor:%' THEN wait_chain(NULL); g_root_cause:='LIBRARY CACHE / CURSOR CONTENTION'; g_root_conf:='MEDIUM'; g_root_chain:='library cache wait -> cursor/object dependency -> blocker'; g_root_evidence:='Library-cache wait observed';
    ELSE g_root_cause:='WAIT EVENT REQUIRES ADDITIONAL BRANCH'; g_root_conf:='LOW'; g_root_chain:=e||' -> resource/process dependency'; g_root_evidence:='No dedicated branch yet'; END IF;
    DBMS_OUTPUT.PUT_LINE(''); DBMS_OUTPUT.PUT_LINE('  DIAGNOSIS'); DBMS_OUTPUT.PUT_LINE('  ----------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('    ROOT CAUSE : '||NVL(g_root_cause,'UNDETERMINED')); DBMS_OUTPUT.PUT_LINE('    CONFIDENCE : '||NVL(g_root_conf,'LOW')); DBMS_OUTPUT.PUT_LINE('    PATH       : '||NVL(g_root_chain,'-')); DBMS_OUTPUT.PUT_LINE('    EVIDENCE   : '||NVL(g_root_evidence,'-'));
  END;

  PROCEDURE sample_header IS e VARCHAR2(128); c VARCHAR2(64); mx NUMBER:=-1; avgms NUMBER:=0; k VARCHAR2(128);
  BEGIN
    k:=g_evt.FIRST; WHILE k IS NOT NULL LOOP IF g_evt(k).wait_cs>mx THEN mx:=g_evt(k).wait_cs; e:=g_evt(k).event; c:=g_evt(k).wait_class; END IF; k:=g_evt.NEXT(k); END LOOP;
    IF g_sample_waits>0 THEN avgms:=(g_sample_cs/g_sample_waits)*10; END IF;
    DBMS_OUTPUT.PUT_LINE(''); DBMS_OUTPUT.PUT_LINE('+------------------------------------------------------------------------------+'); DBMS_OUTPUT.PUT_LINE('| XHAWK  SAMPLE '||LPAD(l_sample,2,'0')||'/'||LPAD(l_count,2,'0')||'  '||TO_CHAR(SYSTIMESTAMP,'HH24:MI:SS')||'  FILTER='||l_filter||'                         |'); DBMS_OUTPUT.PUT_LINE('+------------------------------------------------------------------------------+'); DBMS_OUTPUT.PUT_LINE('| WAITS='||RPAD(n(g_sample_waits),8)||' WAIT_TIME='||RPAD(s(g_sample_cs)||' s',12)||' AVG='||RPAD(d(avgms)||' ms',10)||' |'); DBMS_OUTPUT.PUT_LINE('| TOP='||RPAD(SUBSTR(NVL(e,'NONE'),1,68),68)||'|'); DBMS_OUTPUT.PUT_LINE('| CLASS='||RPAD(SUBSTR(NVL(c,'-'),1,65),65)||'|'); DBMS_OUTPUT.PUT_LINE('+------------------------------------------------------------------------------+');
  END;

  PROCEDURE breakdown IS k VARCHAR2(128); i PLS_INTEGER:=0; TYPE rr IS RECORD(k VARCHAR2(128),v NUMBER); TYPE rt IS TABLE OF rr INDEX BY PLS_INTEGER; a rt; p PLS_INTEGER; tk VARCHAR2(128); tv NUMBER;
  BEGIN
    k:=g_evt.FIRST; WHILE k IS NOT NULL LOOP i:=i+1; a(i).k:=k; a(i).v:=g_evt(k).wait_cs; k:=g_evt.NEXT(k); END LOOP; IF i=0 THEN RETURN; END IF;
    IF i>1 THEN FOR x IN 1..i-1 LOOP p:=x; FOR y IN x+1..i LOOP IF a(y).v>a(p).v THEN p:=y; END IF; END LOOP; IF p<>x THEN tk:=a(x).k; tv:=a(x).v; a(x).k:=a(p).k; a(x).v:=a(p).v; a(p).k:=tk; a(p).v:=tv; END IF; END LOOP; END IF;
    DBMS_OUTPUT.PUT_LINE(''); DBMS_OUTPUT.PUT_LINE('  WAIT BREAKDOWN'); DBMS_OUTPUT.PUT_LINE('  ----------------------------------------------------------------------'); DBMS_OUTPUT.PUT_LINE('  '||RPAD('Rank',5)||RPAD('Event',45)||RPAD('Class',17)||LPAD('Waits',8)||LPAD('Time',10));
    i:=LEAST(i,l_sql_top); FOR x IN 1..i LOOP k:=a(x).k; DBMS_OUTPUT.PUT_LINE('  '||RPAD(x,5)||RPAD(SUBSTR(g_evt(k).event,1,44),45)||RPAD(SUBSTR(g_evt(k).wait_class,1,16),17)||LPAD(n(g_evt(k).waits),8)||LPAD(s(g_evt(k).wait_cs)||'s',10)); END LOOP;
  END;

  PROCEDURE func_io IS w NUMBER; m NUMBER; a NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE(''); DBMS_OUTPUT.PUT_LINE('  FUNCTION I/O'); DBMS_OUTPUT.PUT_LINE('  ----------------------------------------------------------------------');
    FOR r IN (SELECT 'LGWR' name FROM dual UNION ALL SELECT 'DBWR' FROM dual UNION ALL SELECT 'CKPT' FROM dual UNION ALL SELECT 'ARCH' FROM dual) LOOP
      w:=func_delta(r.name,'WAITS'); m:=func_delta(r.name,'WAIT_MS'); IF w>0 THEN a:=m/w; ELSE a:=0; END IF; DBMS_OUTPUT.PUT_LINE('  '||RPAD(r.name,7)||' waits='||LPAD(n(w),7)||' wait='||LPAD(d(m),8)||' ms avg='||LPAD(d(a),7)||' ms');
    END LOOP;
  END;

  PROCEDURE file_io IS w NUMBER; m NUMBER; a NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE(''); DBMS_OUTPUT.PUT_LINE('  FILE-TYPE I/O'); DBMS_OUTPUT.PUT_LINE('  ----------------------------------------------------------------------');
    FOR r IN (SELECT 'Control File' name FROM dual UNION ALL SELECT 'Data File' FROM dual UNION ALL SELECT 'Log File' FROM dual UNION ALL SELECT 'Temp File' FROM dual) LOOP
      w:=file_delta(r.name,'WAITS'); m:=file_delta(r.name,'WAIT_MS'); IF w>0 THEN a:=m/w; ELSE a:=0; END IF; DBMS_OUTPUT.PUT_LINE('  '||RPAD(r.name,13)||' waits='||LPAD(n(w),7)||' wait='||LPAD(d(m),8)||' ms avg='||LPAD(d(a),7)||' ms');
    END LOOP;
  END;

  PROCEDURE top_sql IS k VARCHAR2(100); i PLS_INTEGER:=0; TYPE rr IS RECORD(k VARCHAR2(100),v NUMBER); TYPE rt IS TABLE OF rr INDEX BY PLS_INTEGER; a rt; p PLS_INTEGER; tk VARCHAR2(100); tv NUMBER;
  BEGIN
    k:=g_sql.FIRST; WHILE k IS NOT NULL LOOP i:=i+1; a(i).k:=k; a(i).v:=g_sql(k).wait_cs; k:=g_sql.NEXT(k); END LOOP; IF i=0 THEN RETURN; END IF;
    IF i>1 THEN FOR x IN 1..i-1 LOOP p:=x; FOR y IN x+1..i LOOP IF a(y).v>a(p).v THEN p:=y; END IF; END LOOP; IF p<>x THEN tk:=a(x).k; tv:=a(x).v; a(x).k:=a(p).k; a(x).v:=a(p).v; a(p).k:=tk; a(p).v:=tv; END IF; END LOOP; END IF;
    IF NOT yn(l_sql) THEN RETURN; END IF;
    DBMS_OUTPUT.PUT_LINE(''); DBMS_OUTPUT.PUT_LINE('  TOP SQL'); DBMS_OUTPUT.PUT_LINE('  ----------------------------------------------------------------------');
    i:=LEAST(i,l_sql_top); FOR x IN 1..i LOOP k:=a(x).k; DBMS_OUTPUT.PUT_LINE('  #'||x||' SQL_ID='||g_sql(k).sql_id||' CHILD='||g_sql(k).child_no||' WAIT='||s(g_sql(k).wait_cs)||'s'); IF yn(l_sql_text) THEN DBMS_OUTPUT.PUT_LINE('     '||SUBSTR(NVL(g_sql(k).sql_text,'-'),1,220)); END IF; IF yn(l_plan) THEN print_plan(g_sql(k).sql_id); END IF; END LOOP;
  END;

  PROCEDURE graph IS bars PLS_INTEGER;
  BEGIN
    IF l_graph<>'Y' THEN RETURN; END IF;
    DBMS_OUTPUT.PUT_LINE(''); DBMS_OUTPUT.PUT_LINE('  INTERVAL TREND'); DBMS_OUTPUT.PUT_LINE('  ----------------------------------------------------------------------');
    FOR i IN 1..l_sample LOOP IF g_graph.EXISTS(i) THEN IF g_graph_max>0 THEN bars:=ROUND(g_graph(i).wait_cs/g_graph_max*40); ELSE bars:=0; END IF; DBMS_OUTPUT.PUT_LINE(LPAD(i,3)||' | '||RPAD('#',bars,'#')||' '||s(g_graph(i).wait_cs)||' s'); END IF; END LOOP;
  END;



  PROCEDURE collect_sql_activity IS
    k VARCHAR2(100);
    old_parse NUMBER;
    old_exec NUMBER;
    old_cpu NUMBER;
    old_elapsed NUMBER;
    dp NUMBER;
    de NUMBER;
    dc NUMBER;
    delap NUMBER;
    dw NUMBER;
    txt VARCHAR2(1000);
  BEGIN
    IF NOT yn(l_activity) THEN RETURN; END IF;

    /*
      GV$SQLSTATS provides cumulative per-SQL_ID statistics at each instance.
      Deltas between samples are used so cursor statistics are not mistaken
      for activity in the current interval.
    */
    FOR r IN (
      SELECT inst_id, sql_id,
             NVL(parse_calls,0) parse_calls,
             NVL(executions,0) executions,
             NVL(cpu_time,0) cpu_us,
             NVL(elapsed_time,0) elapsed_us
      FROM gv$sqlstats
    ) LOOP
      k:=r.inst_id||':'||r.sql_id;
      old_parse:=0; old_exec:=0; old_cpu:=0; old_elapsed:=0;
      IF g_prev_sqlact.EXISTS(k) THEN
        old_parse:=g_prev_sqlact(k).parse_calls;
        old_exec:=g_prev_sqlact(k).executions;
        old_cpu:=g_prev_sqlact(k).cpu_us;
        old_elapsed:=g_prev_sqlact(k).elapsed_us;
      END IF;

      IF r.parse_calls>=old_parse THEN dp:=r.parse_calls-old_parse; ELSE dp:=r.parse_calls; END IF;
      IF r.executions>=old_exec THEN de:=r.executions-old_exec; ELSE de:=r.executions; END IF;
      IF r.cpu_us>=old_cpu THEN dc:=r.cpu_us-old_cpu; ELSE dc:=r.cpu_us; END IF;
      IF r.elapsed_us>=old_elapsed THEN delap:=r.elapsed_us-old_elapsed; ELSE delap:=r.elapsed_us; END IF;

      g_prev_sqlact(k).parse_calls:=r.parse_calls;
      g_prev_sqlact(k).executions:=r.executions;
      g_prev_sqlact(k).cpu_us:=r.cpu_us;
      g_prev_sqlact(k).elapsed_us:=r.elapsed_us;

      -- First sample establishes the baseline; do not count accumulated history.
      IF l_sample>1 THEN
        dw:=GREATEST(delap-dc,0);
        g_sample_parse:=g_sample_parse+dp;
        g_sample_exec:=g_sample_exec+de;
        g_sample_cpu_us:=g_sample_cpu_us+dc;
        g_sample_wait_us:=g_sample_wait_us+dw;

        IF dp>0 OR de>0 OR dc>0 OR dw>0 THEN
          IF g_sqlact.EXISTS(k) THEN
            g_sqlact(k).parse_calls:=g_sqlact(k).parse_calls+dp;
            g_sqlact(k).executions:=g_sqlact(k).executions+de;
            g_sqlact(k).cpu_us:=g_sqlact(k).cpu_us+dc;
            g_sqlact(k).wait_us:=g_sqlact(k).wait_us+dw;
          ELSE
            g_sqlact(k).sql_id:=r.sql_id;
            g_sqlact(k).parse_calls:=dp;
            g_sqlact(k).executions:=de;
            g_sqlact(k).cpu_us:=dc;
            g_sqlact(k).wait_us:=dw;
          END IF;
        END IF;
      END IF;
    END LOOP;

    g_activity_samples(l_sample).parse_calls:=g_sample_parse;
    g_activity_samples(l_sample).executions:=g_sample_exec;
    g_activity_samples(l_sample).cpu_us:=g_sample_cpu_us;
    g_activity_samples(l_sample).wait_us:=g_sample_wait_us;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  SQL ACTIVITY / CPU-WAIT PROFILE - SAMPLE '||l_sample);
    DBMS_OUTPUT.PUT_LINE('  ----------------------------------------------------------------------');
    IF l_sample=1 THEN
      DBMS_OUTPUT.PUT_LINE('    Baseline captured from GV$SQLSTATS; interval deltas start at sample 2.');
    ELSE
      DBMS_OUTPUT.PUT_LINE('    PARSE CALLS delta : '||n(g_sample_parse));
      DBMS_OUTPUT.PUT_LINE('    EXECUTIONS delta  : '||n(g_sample_exec));
      DBMS_OUTPUT.PUT_LINE('    CPU time          : '||d(g_sample_cpu_us/1000000)||' sec');
      DBMS_OUTPUT.PUT_LINE('    WAIT time*        : '||d(g_sample_wait_us/1000000)||' sec');
      DBMS_OUTPUT.PUT_LINE('    ELAPSED (CPU+WAIT): '||d((g_sample_cpu_us+g_sample_wait_us)/1000000)||' sec');
      IF g_sample_exec>0 THEN
        DBMS_OUTPUT.PUT_LINE('    AVG CPU / EXEC    : '||d(g_sample_cpu_us/1000/g_sample_exec)||' ms');
        DBMS_OUTPUT.PUT_LINE('    AVG ELAPSED / EXEC: '||d((g_sample_cpu_us+g_sample_wait_us)/1000/g_sample_exec)||' ms');
      ELSE
        DBMS_OUTPUT.PUT_LINE('    AVG CPU / EXEC    : n/a');
        DBMS_OUTPUT.PUT_LINE('    AVG ELAPSED / EXEC: n/a');
      END IF;

      IF yn(l_activity_graph) THEN
        DECLARE
          mx NUMBER;
          cb PLS_INTEGER;
          wb PLS_INTEGER;
        BEGIN
          mx:=GREATEST(g_sample_cpu_us,g_sample_wait_us);
          IF mx>0 THEN
            cb:=ROUND(g_sample_cpu_us/mx*30);
            wb:=ROUND(g_sample_wait_us/mx*30);
          ELSE
            cb:=0; wb:=0;
          END IF;
          DBMS_OUTPUT.PUT_LINE('    CPU  |'||RPAD('#',cb,'#')||' '||d(g_sample_cpu_us/1000000)||' s');
          DBMS_OUTPUT.PUT_LINE('    WAIT |'||RPAD('*',wb,'*')||' '||d(g_sample_wait_us/1000000)||' s');
          DBMS_OUTPUT.PUT_LINE('    Scale: each bar is relative to the larger CPU/WAIT value in this sample.');
        END;
      END IF;

      IF g_sqlact.COUNT>0 THEN
        DECLARE
          TYPE t_key_tab IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
          TYPE t_val_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
          a_key t_key_tab;
          a_val t_val_tab;
          cnt PLS_INTEGER:=0;
          pick PLS_INTEGER;
          swap_key VARCHAR2(100);
          swap_val NUMBER;
          kk VARCHAR2(100);
        BEGIN
          kk:=g_sqlact.FIRST;
          WHILE kk IS NOT NULL LOOP
            cnt:=cnt+1; a_key(cnt):=kk;
            a_val(cnt):=g_sqlact(kk).cpu_us+g_sqlact(kk).wait_us;
            kk:=g_sqlact.NEXT(kk);
          END LOOP;
          IF cnt>1 THEN
            FOR i IN 1..cnt-1 LOOP
              pick:=i;
              FOR j IN i+1..cnt LOOP
                IF a_val(j)>a_val(pick) THEN pick:=j; END IF;
              END LOOP;
              IF pick<>i THEN
                swap_key:=a_key(i); swap_val:=a_val(i);
                a_key(i):=a_key(pick); a_val(i):=a_val(pick);
                a_key(pick):=swap_key; a_val(pick):=swap_val;
              END IF;
            END LOOP;
          END IF;
          DBMS_OUTPUT.PUT_LINE('    TOP SQL_ID BY ELAPSED DELTA');
          FOR i IN 1..LEAST(cnt,l_activity_top) LOOP
            kk:=a_key(i);
            DBMS_OUTPUT.PUT_LINE('      '||i||'. SQL_ID='||g_sqlact(kk).sql_id||
              ' PARSES='||n(g_sqlact(kk).parse_calls)||
              ' EXECS='||n(g_sqlact(kk).executions)||
              ' CPU='||d(g_sqlact(kk).cpu_us/1000000)||'s'||
              ' WAIT='||d(g_sqlact(kk).wait_us/1000000)||'s');
          END LOOP;
        END;
      ELSE
        DBMS_OUTPUT.PUT_LINE('    No SQL_ID activity deltas recorded in this interval.');
      END IF;
    END IF;
    DBMS_OUTPUT.PUT_LINE('    * WAIT is estimated as GV$SQLSTATS.ELAPSED_TIME - CPU_TIME.');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('  SQL activity sampling unavailable: '||SQLERRM);
  END;

  PROCEDURE activity_graph IS
    mx NUMBER:=0;
    cb PLS_INTEGER;
    wb PLS_INTEGER;
  BEGIN
    IF NOT yn(l_activity) OR NOT yn(l_activity_graph) THEN RETURN; END IF;
    FOR i IN 2..l_count LOOP
      IF g_activity_samples.EXISTS(i) THEN
        mx:=GREATEST(mx,g_activity_samples(i).cpu_us,g_activity_samples(i).wait_us);
      END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  CPU / WAIT GRAPH BY SAMPLE');
    DBMS_OUTPUT.PUT_LINE('  ----------------------------------------------------------------------');
    IF mx=0 THEN
      DBMS_OUTPUT.PUT_LINE('    No CPU/WAIT deltas recorded.');
      RETURN;
    END IF;
    FOR i IN 2..l_count LOOP
      IF g_activity_samples.EXISTS(i) THEN
        cb:=ROUND(g_activity_samples(i).cpu_us/mx*30);
        wb:=ROUND(g_activity_samples(i).wait_us/mx*30);
        DBMS_OUTPUT.PUT_LINE('    S'||LPAD(i,2,'0')||
          ' CPU |'||RPAD('#',cb,'#')||' '||d(g_activity_samples(i).cpu_us/1000000)||'s');
        DBMS_OUTPUT.PUT_LINE('       WAIT|'||RPAD('*',wb,'*')||' '||d(g_activity_samples(i).wait_us/1000000)||'s');
      END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('    Legend: # CPU seconds, * estimated non-CPU elapsed seconds.');
    DBMS_OUTPUT.PUT_LINE('    Graph uses one common scale across all samples.');
  END;

  PROCEDURE report_resource_limit IS
    lim NUMBER;
    pct NUMBER;
    headroom NUMBER;
  BEGIN
    IF NOT yn(l_resource_limit) THEN RETURN; END IF;
    DBMS_OUTPUT.PUT_LINE('  PROCESS / SESSION LIMITS (GV$RESOURCE_LIMIT)');
    DBMS_OUTPUT.PUT_LINE('    INST RESOURCE  CURRENT   HIGH-WATER LIMIT       USED%   HEADROOM');
    FOR r IN (
      SELECT inst_id, resource_name, current_utilization,
             max_utilization, limit_value
      FROM gv$resource_limit
      WHERE resource_name IN ('processes','sessions')
      ORDER BY inst_id, resource_name
    ) LOOP
      lim := NULL;
      IF REGEXP_LIKE(TRIM(r.limit_value),'^[0-9]+$') THEN
        lim := TO_NUMBER(TRIM(r.limit_value));
      END IF;
      IF lim > 0 THEN
        pct := r.current_utilization / lim * 100;
        headroom := GREATEST(lim-r.current_utilization,0);
      ELSE
        pct := NULL;
        headroom := NULL;
      END IF;
      DBMS_OUTPUT.PUT_LINE(
        '    '||LPAD(r.inst_id,4)||' '||RPAD(r.resource_name,9)||
        LPAD(n(r.current_utilization),9)||LPAD(n(r.max_utilization),11)||
        LPAD(NVL(r.limit_value,'-'),10)||
        LPAD(CASE WHEN pct IS NULL THEN 'n/a' ELSE d(pct)||'%' END,9)||
        LPAD(CASE WHEN headroom IS NULL THEN 'n/a' ELSE n(headroom) END,11)
      );
      IF pct >= 85 THEN
        DBMS_OUTPUT.PUT_LINE('      *** WARNING: '||r.resource_name||
          ' current utilization is at least 85% of configured limit on INST '||r.inst_id);
      END IF;
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('    resource-limit report unavailable: '||SQLERRM);
  END;

  PROCEDURE report_temp_sql IS
    bsize NUMBER;
    used_mb NUMBER;
    total_mb NUMBER;
    free_mb NUMBER;
    shown PLS_INTEGER := 0;
  BEGIN
    IF NOT yn(l_temp_sql) THEN RETURN; END IF;
    DBMS_OUTPUT.PUT_LINE('  TEMP SPACE / TOP TEMP SQL');
    FOR r IN (
      SELECT tablespace_name, tablespace_size, allocated_space, free_space
      FROM dba_temp_free_space
      ORDER BY tablespace_name
    ) LOOP
      DBMS_OUTPUT.PUT_LINE('    TEMP '||RPAD(r.tablespace_name,25)||
        ' total='||d(r.tablespace_size/1048576)||' MB'||
        ' allocated='||d(r.allocated_space/1048576)||' MB'||
        ' free='||d(r.free_space/1048576)||' MB');
    END LOOP;

    BEGIN
      SELECT value INTO bsize FROM v$parameter WHERE name='db_block_size';
    EXCEPTION WHEN OTHERS THEN bsize:=8192;
    END;

    DBMS_OUTPUT.PUT_LINE('    TOP TEMP CONSUMERS (SQL_ID_TEMPSEG; current segment attribution)');
    FOR r IN (
      SELECT * FROM (
        SELECT u.inst_id, u.username, s.sid, s.serial#, u.sql_id_tempseg sql_id,
               u.tablespace, u.segtype,
               SUM(u.blocks)*bsize/1048576 mb,
               MAX(SUBSTR(q.sql_text,1,180)) sql_text
        FROM gv$tempseg_usage u
        LEFT JOIN gv$session s
          ON s.inst_id=u.inst_id
         AND s.saddr=u.session_addr
         AND s.serial#=u.session_num
        LEFT JOIN gv$sql q
          ON q.inst_id=u.inst_id
         AND q.sql_id=u.sql_id_tempseg
         AND q.child_number=s.sql_child_number
        GROUP BY u.inst_id,u.username,s.sid,s.serial#,u.sql_id_tempseg,
                 u.tablespace,u.segtype
        ORDER BY SUM(u.blocks) DESC
      ) WHERE ROWNUM <= l_resource_top
    ) LOOP
      shown:=shown+1;
      DBMS_OUTPUT.PUT_LINE('    #'||shown||' INST='||r.inst_id||
        ' SID='||NVL(TO_CHAR(r.sid),'-')||','||NVL(TO_CHAR(r.serial#),'-')||
        ' USER='||NVL(r.username,'-')||
        ' TEMP='||d(r.mb)||' MB'||
        ' TS='||r.tablespace||' TYPE='||r.segtype||
        ' SQL_ID='||NVL(r.sql_id,'-'));
      IF r.sql_text IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('       SQL='||r.sql_text);
      END IF;
      IF r.sql_id IS NOT NULL AND yn(l_plan) THEN
        print_plan(r.sql_id);
      END IF;
    END LOOP;
    IF shown=0 THEN DBMS_OUTPUT.PUT_LINE('    no active TEMP segment consumers'); END IF;
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('    TEMP SQL report unavailable: '||SQLERRM);
  END;

  PROCEDURE report_undo_sql IS
    total_bytes NUMBER;
    active_bytes NUMBER;
    unexpired_bytes NUMBER;
    expired_bytes NUMBER;
    shown PLS_INTEGER:=0;
  BEGIN
    IF NOT yn(l_undo_sql) THEN RETURN; END IF;
    DBMS_OUTPUT.PUT_LINE('  UNDO SPACE / ACTIVE TRANSACTION SQL');
    FOR r IN (
      SELECT df.tablespace_name, df.total_bytes,
             NVL(x.active_bytes,0) active_bytes,
             NVL(x.unexpired_bytes,0) unexpired_bytes,
             NVL(x.expired_bytes,0) expired_bytes
      FROM (SELECT tablespace_name,SUM(bytes) total_bytes
            FROM dba_data_files
            GROUP BY tablespace_name) df
      JOIN dba_tablespaces t
        ON t.tablespace_name=df.tablespace_name
       AND t.contents='UNDO'
      LEFT JOIN (
        SELECT tablespace_name,
               SUM(CASE WHEN status='ACTIVE' THEN bytes ELSE 0 END) active_bytes,
               SUM(CASE WHEN status='UNEXPIRED' THEN bytes ELSE 0 END) unexpired_bytes,
               SUM(CASE WHEN status='EXPIRED' THEN bytes ELSE 0 END) expired_bytes
        FROM dba_undo_extents
        GROUP BY tablespace_name
      ) x ON x.tablespace_name=df.tablespace_name
      ORDER BY df.tablespace_name
    ) LOOP
      DBMS_OUTPUT.PUT_LINE('    UNDO '||RPAD(r.tablespace_name,24)||
        ' datafiles='||d(r.total_bytes/1048576)||' MB'||
        ' active='||d(r.active_bytes/1048576)||' MB'||
        ' unexpired='||d(r.unexpired_bytes/1048576)||' MB'||
        ' expired='||d(r.expired_bytes/1048576)||' MB');
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('    TOP ACTIVE TRANSACTIONS BY UNDO BLOCKS');
    FOR r IN (
      SELECT * FROM (
        SELECT s.inst_id,s.sid,s.serial#,s.username,s.status,
               NVL(s.sql_id,s.prev_sql_id) sql_id,
               t.used_ublk,t.used_urec,
               t.used_ublk*(SELECT TO_NUMBER(value) FROM v$parameter
                            WHERE name='db_block_size') undo_bytes,
               s.module,s.program
        FROM gv$transaction t
        JOIN gv$session s
          ON s.inst_id=t.inst_id
         AND s.saddr=t.ses_addr
        ORDER BY t.used_ublk DESC
      ) WHERE ROWNUM<=l_resource_top
    ) LOOP
      shown:=shown+1;
      DBMS_OUTPUT.PUT_LINE('    #'||shown||' INST='||r.inst_id||
        ' SID='||r.sid||','||r.serial#||
        ' USER='||NVL(r.username,'-')||
        ' UNDO='||n(r.used_ublk)||' blocks / '||
        d(r.undo_bytes/1048576)||' MB'||
        ' RECORDS='||n(r.used_urec)||
        ' SQL_ID='||NVL(r.sql_id,'-'));
      DBMS_OUTPUT.PUT_LINE('       MODULE='||SUBSTR(NVL(r.module,'-'),1,70)||
        ' PROGRAM='||SUBSTR(NVL(r.program,'-'),1,90));
      IF r.sql_id IS NOT NULL AND yn(l_sql_text) THEN
        FOR q IN (SELECT MAX(SUBSTR(sql_text,1,180)) sql_text
                  FROM gv$sql WHERE inst_id=r.inst_id AND sql_id=r.sql_id) LOOP
          IF q.sql_text IS NOT NULL THEN DBMS_OUTPUT.PUT_LINE('       SQL='||q.sql_text); END IF;
        END LOOP;
      END IF;
    END LOOP;
    IF shown=0 THEN DBMS_OUTPUT.PUT_LINE('    no active transactions found'); END IF;
    DBMS_OUTPUT.PUT_LINE('    NOTE: transaction SQL_ID is the session current/previous SQL_ID;');
    DBMS_OUTPUT.PUT_LINE('          it is an association, not guaranteed attribution of all undo in the transaction.');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('    UNDO report unavailable: '||SQLERRM);
  END;

  PROCEDURE report_redo_sql IS
    k VARCHAR2(100);
    old_bytes NUMBER;
    delta_bytes NUMBER;
    sql_key VARCHAR2(30);
    best_key VARCHAR2(30);
    best_bytes NUMBER;
    rank_no PLS_INTEGER:=0;
  BEGIN
    IF NOT yn(l_redo_sql) THEN RETURN; END IF;
    g_redo_sql.DELETE;
    DBMS_OUTPUT.PUT_LINE('  REDO GENERATION BY SQL_ID (session statistic delta)');
    FOR r IN (
      SELECT s.inst_id,s.sid,s.serial#,
             NVL(s.sql_id,s.prev_sql_id) sql_id,
             st.value redo_bytes
      FROM gv$session s
      JOIN gv$sesstat st ON st.inst_id=s.inst_id AND st.sid=s.sid
      JOIN gv$statname sn ON sn.inst_id=st.inst_id AND sn.statistic#=st.statistic#
      WHERE sn.name='redo size'
        AND s.type='USER'
        AND st.value>0
    ) LOOP
      k:=r.inst_id||':'||r.sid||':'||r.serial#;
      old_bytes:=0;
      IF g_prev_redo.EXISTS(k) THEN old_bytes:=g_prev_redo(k).bytes; END IF;
      IF r.redo_bytes>=old_bytes THEN
        delta_bytes:=r.redo_bytes-old_bytes;
      ELSE
        delta_bytes:=r.redo_bytes;
      END IF;
      IF l_sample=1 THEN delta_bytes:=0; END IF;
      g_prev_redo(k).bytes:=r.redo_bytes;

      IF delta_bytes>0 THEN
        sql_key:=NVL(r.sql_id,'<NO SQL_ID>');
        IF g_redo_sql.EXISTS(sql_key) THEN
          g_redo_sql(sql_key).bytes:=g_redo_sql(sql_key).bytes+delta_bytes;
        ELSE
          g_redo_sql(sql_key).sql_id:=sql_key;
          g_redo_sql(sql_key).bytes:=delta_bytes;
        END IF;
      END IF;
    END LOOP;

    IF l_sample=1 THEN
      DBMS_OUTPUT.PUT_LINE('    baseline captured; SQL_ID redo deltas begin at sample 2');
      RETURN;
    END IF;

    FOR x IN 1..LEAST(l_resource_top,g_redo_sql.COUNT) LOOP
      best_key:=NULL; best_bytes:=-1;
      k:=g_redo_sql.FIRST;
      WHILE k IS NOT NULL LOOP
        IF g_redo_sql(k).bytes>best_bytes THEN
          best_bytes:=g_redo_sql(k).bytes; best_key:=k;
        END IF;
        k:=g_redo_sql.NEXT(k);
      END LOOP;
      EXIT WHEN best_key IS NULL;
      rank_no:=rank_no+1;
      DBMS_OUTPUT.PUT_LINE('    #'||rank_no||
        ' SQL_ID='||g_redo_sql(best_key).sql_id||
        ' REDO='||d(best_bytes/1048576)||' MB ('||n(best_bytes)||' bytes)');
      g_redo_sql.DELETE(best_key);
    END LOOP;
    IF rank_no=0 THEN DBMS_OUTPUT.PUT_LINE('    no redo delta observed in this interval'); END IF;
    DBMS_OUTPUT.PUT_LINE('    NOTE: redo is measured per session and assigned to its sampled current/previous SQL_ID.');
    DBMS_OUTPUT.PUT_LINE('          SQL_ID attribution is approximate if a session runs multiple statements between samples.');
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('    redo SQL report unavailable: '||SQLERRM);
  END;

  PROCEDURE report_resource_diagnostics IS
  BEGIN
    report_resource_limit;
    report_temp_sql;
    report_undo_sql;
    report_redo_sql;
  END;


BEGIN
  IF l_count<1 OR l_interval<0 OR l_top<1 OR l_plan_top<1 THEN RAISE_APPLICATION_ERROR(-20001,'Invalid numeric parameter'); END IF;
  IF l_filter NOT IN ('ALL','DML','DDL','TCL','OTHER') THEN RAISE_APPLICATION_ERROR(-20002,'Invalid wh_filter'); END IF;
  IF l_graph NOT IN ('Y','N') OR l_plan NOT IN ('Y','N') THEN RAISE_APPLICATION_ERROR(-20003,'wh_graph/wh_plan must be Y or N'); END IF;
  IF l_plan_sort NOT IN ('ELAPSED','BUFFER','READ','ROWS','COST') THEN RAISE_APPLICATION_ERROR(-20004,'Invalid wh_plan_sort'); END IF;
  IF l_mode NOT IN ('LIVE','WAIT','ROOTCAUSE','BLOCKER','IO','SQL','PLAN','RAC','ALL') THEN RAISE_APPLICATION_ERROR(-20005,'Invalid wh_mode'); END IF;
  IF l_depth NOT IN ('BASIC','NORMAL','DEEP','FORENSIC') THEN RAISE_APPLICATION_ERROR(-20006,'Invalid wh_depth'); END IF;
  IF l_chain_depth<1 THEN RAISE_APPLICATION_ERROR(-20007,'wh_chain_depth must be >= 1'); END IF;
  IF l_sql_top<1 THEN RAISE_APPLICATION_ERROR(-20008,'wh_sql_top must be >= 1'); END IF;
  IF l_resource_top<1 THEN RAISE_APPLICATION_ERROR(-20010,'wh_resource_top must be >= 1'); END IF;
  IF l_activity_top<1 THEN RAISE_APPLICATION_ERROR(-20011,'wh_activity_top must be >= 1'); END IF;
  IF l_min_wait_ms<0 OR l_root_ms<0 OR l_high_ms<0 THEN RAISE_APPLICATION_ERROR(-20009,'thresholds must be >= 0'); END IF;

  DBMS_OUTPUT.PUT_LINE('+==============================================================================+');
  DBMS_OUTPUT.PUT_LINE('| XHAWK - ORACLE ROOT-CAUSE WAIT ANALYZER                                  |');
  DBMS_OUTPUT.PUT_LINE('+==============================================================================+');
  DBMS_OUTPUT.PUT_LINE('| samples='||RPAD(n(l_count),5)||' interval='||RPAD(n(l_interval)||'s',7)||' top='||RPAD(n(l_top),3)||' filter='||RPAD(l_filter,5)||' mode='||RPAD(l_mode,10)||' depth='||RPAD(l_depth,8)||'|');
  DBMS_OUTPUT.PUT_LINE('| dashboard='||l_dashboard||' sql='||l_sql||' plan='||l_plan||' io='||l_io||' blocker='||l_blocker||' rac='||l_rac||'|');
  DBMS_OUTPUT.PUT_LINE('+==============================================================================+');

  FOR z IN 1..l_count LOOP
    l_sample:=z; reset_sample;

    FOR r IN (SELECT se.inst_id,se.sid,s.serial#,s.type,s.sql_id,s.sql_child_number,q.command_type,se.event,se.wait_class,se.total_waits,se.time_waited_micro/10000 wait_cs, q.sql_text FROM gv$session_event se JOIN gv$session s ON s.inst_id=se.inst_id AND s.sid=se.sid LEFT OUTER JOIN gv$sql q ON q.inst_id=s.inst_id AND q.sql_id=s.sql_id AND q.child_number=s.sql_child_number WHERE se.wait_class<>'Idle' AND se.event IS NOT NULL AND se.total_waits>0) LOOP
      DECLARE op VARCHAR2(10); k VARCHAR2(700); ow NUMBER:=0; oc NUMBER:=0; dw NUMBER:=0; dc NUMBER:=0;
      BEGIN
        op:=op_class(r.command_type,r.sql_text);
        IF passes_filter(op) THEN
          k:=key_of(r.inst_id,r.sid,r.serial#,r.event);
          IF g_prev.EXISTS(k) THEN ow:=g_prev(k).total_waits; oc:=g_prev(k).wait_cs; END IF;
          IF r.total_waits>=ow THEN dw:=r.total_waits-ow; ELSE dw:=r.total_waits; END IF;
          IF r.wait_cs>=oc THEN dc:=r.wait_cs-oc; ELSE dc:=r.wait_cs; END IF;
          IF l_sample=1 THEN dw:=0; dc:=0; END IF;
          IF dw>0 OR dc>0 THEN add_event(r.event,r.wait_class,dw,dc); add_sql(r.inst_id,r.sql_id,r.sql_child_number,dw,dc,r.sql_text); IF l_sample>1 THEN add_total(r.event,r.wait_class,dw,dc); END IF; g_sample_waits:=g_sample_waits+dw; g_sample_cs:=g_sample_cs+dc; END IF;
          g_prev(k).total_waits:=r.total_waits; g_prev(k).wait_cs:=r.wait_cs;
        END IF;
      END;
    END LOOP;

    collect_sql_activity;
    collect_io; IF yn(l_dashboard) THEN sample_header; END IF;
    IF l_sample=1 THEN IF yn(l_baseline) THEN DBMS_OUTPUT.PUT_LINE('  BASELINE captured. Analysis begins with sample 2.'); ELSE DBMS_OUTPUT.PUT_LINE('  Baseline captured.'); END IF; ELSE diagnose; breakdown; func_io; file_io; top_sql; END IF;
    report_resource_diagnostics;
    g_graph(l_sample).waits:=g_sample_waits; g_graph(l_sample).wait_cs:=g_sample_cs; IF g_sample_cs>g_graph_max THEN g_graph_max:=g_sample_cs; END IF;
    IF l_sample>1 THEN g_total_waits:=g_total_waits+g_sample_waits; g_total_cs:=g_total_cs+g_sample_cs; END IF;
    g_prev_func:=g_cur_func; g_prev_file:=g_cur_file;
    IF z<l_count THEN DBMS_OUTPUT.PUT_LINE('  [sleep '||n(l_interval)||' sec]'); DBMS_LOCK.SLEEP(l_interval); END IF;
  END LOOP;

  IF yn(l_summary) THEN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('+==============================================================================+');
  DBMS_OUTPUT.PUT_LINE('| FINAL SUMMARY                                                              |');
  DBMS_OUTPUT.PUT_LINE('+==============================================================================+');
  DBMS_OUTPUT.PUT_LINE('  total waits : '||n(g_total_waits));
  DBMS_OUTPUT.PUT_LINE('  total time  : '||s(g_total_cs)||' s');
  IF l_count>1 THEN DBMS_OUTPUT.PUT_LINE('  avg/sample  : '||s(g_total_cs/(l_count-1))||' s'); ELSE DBMS_OUTPUT.PUT_LINE('  avg/sample  : 0.00 s'); END IF;
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('  FINAL WAIT BREAKDOWN');
  DBMS_OUTPUT.PUT_LINE('  ----------------------------------------------------------------------');
  DECLARE k VARCHAR2(128); i PLS_INTEGER:=0; TYPE rr IS RECORD(k VARCHAR2(128),v NUMBER); TYPE rt IS TABLE OF rr INDEX BY PLS_INTEGER; a rt; p PLS_INTEGER; tk VARCHAR2(128); tv NUMBER;
  BEGIN
    k:=g_total.FIRST; WHILE k IS NOT NULL LOOP i:=i+1; a(i).k:=k; a(i).v:=g_total(k).wait_cs; k:=g_total.NEXT(k); END LOOP;
    IF i>1 THEN FOR x IN 1..i-1 LOOP p:=x; FOR y IN x+1..i LOOP IF a(y).v>a(p).v THEN p:=y; END IF; END LOOP; IF p<>x THEN tk:=a(x).k; tv:=a(x).v; a(x).k:=a(p).k; a(x).v:=a(p).v; a(p).k:=tk; a(p).v:=tv; END IF; END LOOP; END IF;
    i:=LEAST(i,l_sql_top); FOR x IN 1..i LOOP k:=a(x).k; DBMS_OUTPUT.PUT_LINE('  '||RPAD(x,4)||RPAD(SUBSTR(g_total(k).event,1,48),50)||LPAD(n(g_total(k).waits),8)||LPAD(s(g_total(k).wait_cs)||'s',10)); END LOOP;
  END;
  END IF;
  graph;
  activity_graph;
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('+==============================================================================+');
  DBMS_OUTPUT.PUT_LINE('| COMPLETE  '||TO_CHAR(SYSTIMESTAMP,'YYYY-MM-DD HH24:MI:SS')||'                                             |');
  DBMS_OUTPUT.PUT_LINE('+==============================================================================+');
END;
/

