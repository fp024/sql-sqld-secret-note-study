# Chaper 1. 오라클 DBMS 실습 환경 구축

## Docker 로 Oracle 11g R2 설치

저자님은 윈도우 10 환경에서 Oracle XE 11g R2를 설치하셨는데, 나는 Docker로 설치해보자.

* 윈도우로 설치하려면 아래 자료실에서 받도록 하자!
  * https://www.hanbit.co.kr/src/10436

#### Oracle 11g Release 2

* https://github.com/wnameless/docker-oracle-xe-11g

  ```bash
  # 도커 허브에서 가져오기
  docker pull wnameless/oracle-xe-11g-r2
  
  # 원격데이터베이스 연결 허용, 외부 포트는 11521 사용, 타임존은 호스트 서버 설정 파일 사용하도록 맞춤
  # SQLD 디렉토리는 데이터 덤프 편하게 연결해둠.
  docker run --name oracle-xe-11g-r2 -v /etc/localtime:/etc/localtime:ro -v /home/fp024/SQLD:/SQLD -d -p 11521:1521 -e ORACLE_ALLOW_REMOTE=true wnameless/oracle-xe-11g-r2
  ```
  * 최초 기본 비밀번호: oracle



### oracle 컨테이너로 콘솔 접속

```bash
docker exec -it oracle-xe-11g-r2 bash
```

Docker Desktop에서 콘솔 아이콘 눌러서 콘솔 띄우는 것보다 WSL Ubuntu에서 위명령 입력해서 접근하는 것이 낫다. Docker Desktop에서 띄울 때는 cmd를 사용해서 한글 깨지고 입력이 힘듦 ㅠㅠ..😓



### Oracle 리스너 확인

`lsnrctl status` 명령도 잘 동작한다.

```bash
root@4193aa9c52e1:/# lsnrctl status

LSNRCTL for Linux: Version 11.2.0.2.0 - Production on 09-MAY-2022 05:00:00

Copyright (c) 1991, 2011, Oracle.  All rights reserved.

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=EXTPROC_FOR_XE)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 11.2.0.2.0 - Production
Start Date                09-MAY-2022 04:02:27
Uptime                    0 days 0 hr. 57 min. 32 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Default Service           XE
Listener Parameter File   /u01/app/oracle/product/11.2.0/xe/network/admin/listener.ora
Listener Log File         /u01/app/oracle/diag/tnslsnr/4193aa9c52e1/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC_FOR_XE)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=4193aa9c52e1)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=4193aa9c52e1)(PORT=8080))(Presentation=HTTP)(Session=RAW))
Services Summary...
Service "PLSExtProc" has 1 instance(s).
  Instance "PLSExtProc", status UNKNOWN, has 1 handler(s) for this service...
Service "XE" has 1 instance(s).
  Instance "XE", status READY, has 1 handler(s) for this service...
Service "XEXDB" has 1 instance(s).
  Instance "XE", status READY, has 1 handler(s) for this service...
The command completed successfully
root@4193aa9c52e1:/#
```



## SQL*Plus 접속

책에는 계정명 없이 SYSDBA로 접속하는 것으로 되어있던데, 내 환경에서 잘 안된다...

```bash
sqlplus "/as SYSDBA"
```

그래서 SYS 계정으로 명시했다/

```bash
 sqlplus SYS AS SYSDBA
```



```sql
SQL> SET linesize 200;   -- 한 화면에 표시되는 SQL 명령문의 출력결과에 대한 행크기
SQL> SET timing on;      -- SQL 명령문을 실행하는 데 소요된 시간을 출력
SQL> SET serveroutput on;   -- PL/SQL문 실행시 DBMS_OUTPUT.PUT_LINE()으로 로그를 남길경우 
                           -- 이걸 지정해야 로그가 정상 출력됨
SQL> SELECT * FROM DUAL;

D
-
X

Elapsed: 00:00:00.01
SQL>
```



## 문자셋 (이부분은 그냥 AL32UTF8 사용 유지하려고 했는데... 예제 DB적용시 문제가 있음 😓 )

* NLS 상태 확인

  ```sql
  SELECT *
  FROM sys.props$
  WHERE name = 'NLS_LANGUAGE';
  ```

  | NAME              | VALUE$   | COMMENT$      |
  | :---------------- | :------- | :------------ |
  | NLS\_CHARACTERSET | AL32UTF8 | Character set |

책에서는 MS949로 바꾸라고 하는데, 내 환경에서는 일부러 바꿀 필요는 없을 것 같다.  일단은 AL32UTF8 인 상태로 진행하려고 했는데... 예제 DB적용시 컬럼 사이즈 문제 때문에, MS949 쓰기로 했다.



* 시스템 속성 변경 - 문자 집합 속성 - SYS 계정에서 실행

  ```sql
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
  ```

  

* 오라클 DBMS 중지

  ```sql
  SQL> SHUTDOWN IMMEDIATE;
  ```

* MOUNT 모드로 오라클 DBMS를 시작

  ```sql
  SQL> STARTUP MOUNT;
  ```

* 문자집합 설정 스크립트 입력

  ```sql
  ALTER SYSTEM ENABLE RESTRICTED SESSION;
  ALTER SYSTEM SET JOB_QUEUE_PROCESSES = 0;
  ALTER SYSTEM SET AQ_TM_PROCESSES = 0;
  ALTER DATABASE OPEN;
  ALTER DATABASE CHARACTER SET KO16MSWIN949;
  ```

* 오라클 DBMS 중지

  ```sql
  SQL> SHUTDOWN IMMEDIATE;
  ```

* 오라클 DBMS 시작

  ```sql
  SQL> STARTUP;
  ```

* 환경변수 설정

  컨테이너의 `/etc/bash.bashrc`  파일에 설정

  ```bash
  export NLS_LANG=KOREAN_KOREA.KO16MSWIN949
  ```

  Oracle 컨테이너가 최소화버전이라 vim또는 nano가 설치되어있지 않은데 설치하도록 하자!
  
  ```bash
  $ apt update
  $ apt upgrade -y
  $ apt install vim
  ```
  
  업그레이드(apt upgrade)는 그냥 했음..
  
  

## GUI 도구

* SQL Developer
  * https://www.oracle.com/tools/downloads/sqldev-downloads.html
* DBeaver
  * https://dbeaver.io/download/

위의 프로그램 모두 있고, JetBrains의 DataGrip도 사용하고 있다.





## 의견

Oracle을 Docker로 간단하게 설치하였는데, 앞으로의 책 진행에 문제가 없을 것 같다...😄

KO16MSWIN949 의 두번째 O가 숫자 0인줄 알고 고생했다. 😓 책에는 0과 O가 정확하게 구분되는 폰트를 넣어주시는 것이 좋을 것 같다.
