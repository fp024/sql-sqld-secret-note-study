# Chaper 2. 실습 데이터 구성



## 2.1 사용자 계정 및 테이블 스페이스 생성

Docker로 사용하기 때문에 경로를 파악하기 위해서 컨테이너의 bash를 실행시킬 필요가 있는데,

아래와 같이  호스트 리눅스의 `.bashrc`에 별칭을 등록해서 별칭을 입력하면 바로 실행되게 하였다.

```bash
alias ora11sh="docker exec -it oracle-xe-11g-r2 bash"
```



SQLD 계정이 사용할 테이블 스페이스와 임시 테이블 스페이스는 다음 경로로 저장되게 하였다.

* 테이블 스페이스

  `/u01/app/oracle/oradata/XE/SQLD_DATA.dbf`

* 임시 테이블 스페이스

  `/u01/app/oracle/oradata/XE/SQLD_TEMP.dbf`

🎇 자세한 내용은 [SYS-Script.sql](SYS-Script.sql)을 참조할 것.



## 2.2 실습 데이터 모델 소개

### 2.2.1 상가 데이터

### 2.2.2 지하철역 승하차 데이터

### 2.2.3 인구 데이터



지금 시점에 데이터가 변경 되어있을 수 있으므로 예제 데이터는 출판사 예제 파일을 다운로드 받아 사용해야겠다.



### 주요 테이블 명세





### 기타 테이블 명세







## 2.3 테이블 생성 및 데이터 입력

1. Oracle 11gR2 컨테이너에 들어가서 /SQLD 경로를 만들어두자

   ```bash
   $ ora11sh
   root@4193aa9c52e1:/# mkdir SQLD
   root@4193aa9c52e1:/# exit
   ```

2. 저자님 덤프파일을 받아 WSL2 Ubuntu Home에 옮겨둔다.

   * https://www.hanbit.co.kr/lib/examFileDown.php?hed_idx=5927

     ```bash
     $ wget -O EXPORT_SQLD.zip https://www.hanbit.co.kr/lib/examFileDown.php?hed_idx=5927
     $ unzip EXPORT_SQLD.zip
     ```

     별도 가상머신 Ubuntu에도 Docker를 설치해서 사용하고 있는데, 이때는 wget 으로 직접 받아 unzip으로 압축을 풀었다.
   * Windows 11이라면 탐색기에서 복사 가능함, Windows 10 이라면 WSL안에서 미리 마운트 뒤어있는 경로(`/mnt/c/...`)로 가져오는 식으로 하면 될 것 같다.

3. WSL2 Ubuntu Home에 옮겨둔 파일을 컨테이너의 /SQLD 디렉토리로 복사한다.

   ```bash
   $ docker cp EXPORT_SQLD.DMP oracle-xe-11g-r2:/SQLD
   $ ora11sh
   root@4193aa9c52e1:/# ls SQLD
   EXPORT_SQLD.DMP
   root@4193aa9c52e1:/#
   ```

4. SQLD 유저에 대해 /SQLD 디렉토리의 실행/쓰기/읽기 권한 부여

   ```sql
   CREATE OR REPLACE DIRECTORY D_SQLD AS '/SQLD';
   GRANT EXECUTE ON DIRECTORY D_SQLD TO SQLD WITH GRANT OPTION;
   GRANT WRITE ON DIRECTORY D_SQLD TO SQLD WITH GRANT OPTION;
   GRANT READ ON DIRECTORY D_SQLD TO SQLD WITH GRANT OPTION;
   ```

5. 덤프 실행

   ```bash
   root@4193aa9c52e1:/SQLD# impdp SQLD/1234 schemas=SQLD directory=D_SQLD dumpfile=EXPORT_SQLD.DMP logfile=EXPORT_SQLD.log
   
   Import: Release 11.2.0.2.0 - Production on Mon May 9 08:40:27 2022
   
   Copyright (c) 1982, 2009, Oracle and/or its affiliates.  All rights reserved.
   
   Connected to: Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production
   ORA-39002: invalid operation
   ORA-39070: Unable to open the log file.
   ORA-29283: invalid file operation
   ORA-06512: at "SYS.UTL_FILE", line 536
   ORA-29283: invalid file operation
   root@4193aa9c52e1:/SQLD#
   ```

   내 환경에서는 오류가 난다.  인코딩을 바꾸지 않아서 그럴까?

   저자님이 SQL 스크립트 덤프파일도 제공해주셨으니... 그것의 인코딩을 UTF-8로 변환후에 입력해보자!

   * https://www.hanbit.co.kr/lib/examFileDown.php?hed_idx=5928

     ```bash
     $ docker cp EXPORT_SQLD_SQL_SCRIPT.sql oracle-xe-11g-r2:/SQLD
     ```

   * 스크립트로 실행을 해보았는데... 실페는 한다 주로 아래와 같은 오류가 나타나던데..

     ```
     ERROR at line 1:
     ORA-12899: value too large for column "SQLD"."TB_BSSH"."LNM_ADRES" (actual:
     172, maximum: 150)
     ```

      UTF-8 이 한글이 3바이트라서 컬럼사이즈가 안맞아서 그런 것 같은데... (약간씩 초괴되는 모습이 보임)

     인코딩을 바꿔야할 것 같다. 😓

     인코딩을 바꾸면 덤프 파일로도 잘 될 듯...

6. MS949로 인코딩 바꾸고 임포트 덤프 다시 실행

   ```bash
   root@a6cb78bebee5:/SQLD# impdp SQLD/1234 schemas=SQLD directory=D_SQLD dumpfile=EXPORT_SQLD.DMP logfile=EXPORT_SQLD.log
   
   Import: Release 11.2.0.2.0 - Production on Mon May 9 10:19:37 2022
   
   Copyright (c) 1982, 2009, Oracle and/or its affiliates.  All rights reserved.
   
   Connected to: Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production
   Master table "SQLD"."SYS_IMPORT_SCHEMA_01" successfully loaded/unloaded
   Starting "SQLD"."SYS_IMPORT_SCHEMA_01":  SQLD/******** schemas=SQLD directory=D_SQLD dumpfile=EXPORT_SQLD.DMP logfile=EXPORT_SQLD.log
   Processing object type SCHEMA_EXPORT/USER
   ORA-31684: Object type USER:"SQLD" already exists
   Processing object type SCHEMA_EXPORT/SYSTEM_GRANT
   Processing object type SCHEMA_EXPORT/ROLE_GRANT
   Processing object type SCHEMA_EXPORT/DEFAULT_ROLE
   Processing object type SCHEMA_EXPORT/PRE_SCHEMA/PROCACT_SCHEMA
   Processing object type SCHEMA_EXPORT/TABLE/TABLE
   Processing object type SCHEMA_EXPORT/TABLE/TABLE_DATA
   . . imported "SQLD"."TB_BSSH"                            656.8 MB 2569764 rows
   . . imported "SQLD"."TB_RN"                              4.933 MB  107464 rows
   . . imported "SQLD"."TB_POPLTN"                          3.562 MB  117678 rows
   . . imported "SQLD"."TB_SUBWAY_STATN_TK_GFF"             1.087 MB   29040 rows
   . . imported "SQLD"."TB_ADRES_CL"                        712.0 KB   20646 rows
   . . imported "SQLD"."TB_ADSTRD"                          143.8 KB    3566 rows
   . . imported "SQLD"."TB_ADRES_CL_SE"                       5.5 KB       4 rows
   . . imported "SQLD"."TB_AGRDE_SE"                        5.617 KB      11 rows
   . . imported "SQLD"."TB_INDUTY_CL"                       34.64 KB     855 rows
   . . imported "SQLD"."TB_INDUTY_CL_SE"                    5.476 KB       3 rows
   . . imported "SQLD"."TB_PLOT_SE"                         5.445 KB       2 rows
   . . imported "SQLD"."TB_POPLTN_SE"                       5.460 KB       3 rows
   . . imported "SQLD"."TB_STDR_INDUST_CL"                  11.61 KB     203 rows
   . . imported "SQLD"."TB_SUBWAY_STATN"                    21.08 KB     605 rows
   . . imported "SQLD"."TB_TK_GFF_SE"                       5.453 KB       2 rows
   Processing object type SCHEMA_EXPORT/TABLE/INDEX/INDEX
   Processing object type SCHEMA_EXPORT/TABLE/CONSTRAINT/CONSTRAINT
   Processing object type SCHEMA_EXPORT/TABLE/INDEX/STATISTICS/INDEX_STATISTICS
   Processing object type SCHEMA_EXPORT/TABLE/COMMENT
   Processing object type SCHEMA_EXPORT/FUNCTION/FUNCTION
   Processing object type SCHEMA_EXPORT/PROCEDURE/PROCEDURE
   Processing object type SCHEMA_EXPORT/FUNCTION/ALTER_FUNCTION
   Processing object type SCHEMA_EXPORT/PROCEDURE/ALTER_PROCEDURE
   ORA-39082: Object type ALTER_PROCEDURE:"SQLD"."SP_INSERT_TB_POPLTN_CTPRVN" created with compilation warnings
   Processing object type SCHEMA_EXPORT/TABLE/CONSTRAINT/REF_CONSTRAINT
   Processing object type SCHEMA_EXPORT/TABLE/STATISTICS/TABLE_STATISTICS
   Job "SQLD"."SYS_IMPORT_SCHEMA_01" completed with 2 error(s) at 10:21:31
   
   root@a6cb78bebee5:/SQLD#
   ```

   이제는 잘 된다. 😄



✨ MS949로 써서 DBaver의 해당 프로젝트 텍스트 파일 인코딩을 일단은 MS949로 바꿔야하는지?

* 그런데 DBeaver에서 UTF-8로 사용해도 문제는 없다. 조회에 문제가 없는 걸보니 그냥 DBeaver 프로젝트는 UTF-8 유지해도 문제없을 듯..



#### 실습 데이터 구성 확인

| 순번 | 테이블명               | 테이블한글명   | 테이블행수 | 총테이블수 | 총행수  |
| ---- | ---------------------- | -------------- | ---------- | ---------- | ------- |
| 1    | TB_ADRES_CL            | 주소분류       | 20646      | 15         | 2849846 |
| 2    | TB_ADRES_CL_SE         | 주소분류구분   | 4          | 15         | 2849846 |
| 3    | TB_ADSTRD              | 행정동         | 3566       | 15         | 2849846 |
| 4    | TB_AGRDE_SE            | 연령대구분     | 11         | 15         | 2849846 |
| 5    | TB_PLOT_SE             | 대지구분       | 2          | 15         | 2849846 |
| 6    | TB_POPLTN              | 인구           | 117678     | 15         | 2849846 |
| 7    | TB_POPLTN_SE           | 인구구분       | 3          | 15         | 2849846 |
| 8    | TB_RN                  | 도로명         | 107464     | 15         | 2849846 |
| 9    | TB_STDR_INDUST_CL      | 표준산업분류   | 203        | 15         | 2849846 |
| 10   | TB_SUBWAY_STATN        | 지하철역       | 605        | 15         | 2849846 |
| 11   | TB_SUBWAY_STATN_TK_GFF | 지하철역승하차 | 29040      | 15         | 2849846 |
| 12   | TB_TK_GFF_SE           | 승하차구분     | 2          | 15         | 2849846 |
| 13   | TB_BSSH                | 상가           | 2569764    | 15         | 2849846 |
| 14   | TB_INDUTY_CL           | 업종분류       | 855        | 15         | 2849846 |
| 15   | TB_INDUTY_CL_SE        | 업종분류구분   | 3          | 15         | 2849846 |

덤프는 정상적으로 되었다.



## 2.4 SQL 실습환경 구축 과정 소개

* 이부분은 저자님께서 책의 모든과정을 학습 후에 한번 읽어보라고 하셨다.





## 의견

WSL2를 사용하는 Docker Desktop 을 사용한 것보다 Hyper-V Ubuntu에 Docker 설치해서 사용하는 것이 왠지 더 빠른 것 같다. 임포트 덤프 속도 차이가 좀 있던 거 같음.
