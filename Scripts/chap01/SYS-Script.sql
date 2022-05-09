/**
 * 시스템 속성 변경 - 문자 집합 속성
 */
UPDATE SYS.PROPS$
   SET VALUE$='KO16MSWIN949'
 WHERE NAME='NLS_CHARACTERSET';
 
UPDATE SYS.PROPS$
   SET VALUE$='KO16MSWIN949'
 WHERE NAME='NLS_NCHAR_CHARACTERSET';
 
 UPDATE SYS.PROPS$
    SET VALUE$='KOREAN_KOREA.KO16MSWIN949'
  WHERE NAME='NLS_LANGUAGE';
  
COMMIT;


/**
 * 문자집합 설정 스크립트 입력
 */
ALTER SYSTEM ENABLE RESTRICTED SESSION;
ALTER SYSTEM SET JOB_QUEUE_PROCESSES = 0;
ALTER SYSTEM SET AQ_TM_PROCESSES = 0;
ALTER DATABASE OPEN;
ALTER DATABASE CHARACTER SET KO16MSWIN949;