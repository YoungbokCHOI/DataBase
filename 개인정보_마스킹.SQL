CREATE OR REPLACE FUNCTION  Fn_MASKING_NO(IN_DATA IN varchar2, IN_TYPE IN varchar2)
      RETURN varchar2
IS
     RS VARCHAR2(20);   --  RETURN VALUE
     V_TYPE VARCHAR2(20);
BEGIN

     V_TYPE := UPPER(IN_TYPE); --TYPE

     IF V_TYPE = 'CARD' THEN /*신용카드 번호: 1234-5678-1234-5678 또는 1234567812345678 -> 1234-5678-****-**** */
        RS := REGEXP_REPLACE(REGEXP_REPLACE(IN_DATA,'[^[:digit:]]'), '([0-9]{4})([0-9]{4})([0-9]{0,8})', '\1-\2-****-****') ;

     ELSIF V_TYPE = 'IP' THEN /*IP주소: 123.123.123.123 -> 123.***.***.123 */
         RS := REGEXP_REPLACE(IN_DATA, '([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})', '\1.***.***.\4') ;

     ELSIF V_TYPE = 'PHONE' THEN /*전화번호: 010-1234-5678 -> 010-****-5678 */
        IF LENGTH(REGEXP_REPLACE(IN_DATA,'[^[:DIGIT:]]')) IN (7,8) THEN
            RS := REGEXP_REPLACE(REGEXP_REPLACE(IN_DATA,'[^[:DIGIT:]]'), '([0-9]{3,4})([0-9]{4})','****-\2' ) ;
        ELSIF LENGTH(REGEXP_REPLACE(IN_DATA,'[^[:DIGIT:]]')) IN (11,12) THEN
            RS := REGEXP_REPLACE(REGEXP_REPLACE(IN_DATA,'[^[:DIGIT:]]'), '(0[0-9]{1,2})([0-9]{3,4})([0-9]{4})','\1-****-\3' ) ;
        ELSE
            RS := REGEXP_REPLACE(REGEXP_REPLACE(IN_DATA,'[^[:DIGIT:]]'), '(001|002|007[0-9]{2})([0-9]{2})([0-9]+)([0-9]{4})','\1-*******-\4' ) ;
        END IF;
     ELSIF V_TYPE IN ( 'TEL', 'PHONE') THEN /*일반 전화번호: 02-1234-5678 -> 031-****-5678 */
           RS := CASE WHEN LENGTH(NVL(IN_DATA, 0)) < 4 THEN IN_DATA  -- NULL 이거나 3자릿수 이하면 그냥
                      WHEN SUBSTR(IN_DATA, 1,2 ) = '02' THEN REGEXP_REPLACE(IN_DATA, '([[:digit:]]{2})([[:digit:]]{4})([[:digit:]]{3,})', '\1****\3')  -- 전화번호 앞이 02 서울이면
                      ELSE REGEXP_REPLACE(IN_DATA, '([[:digit:]]{3})([[:digit:]]{3,4})([[:digit:]]{3,})', '\1****\3') 
                 END; -- 그 외는 모두
        
     ELSIF V_TYPE IN ('EMAIL', 'MAIL', 'E-MAIL') THEN /*이메일: ADKLF@ADFKL.COM -> ADK**@********* */
        RS := SUBSTR(IN_DATA,0, REGEXP_INSTR(IN_DATA, '@')-3 )||REGEXP_REPLACE(SUBSTR(IN_DATA, REGEXP_INSTR(IN_DATA, '@')-2 ),'[^@]','*') ;

     ELSIF V_TYPE IN ('REP_ID', 'REPID') THEN /*주민등록번호: 850101-1234567 또는 8501011234567 -> 850101-1****** */
        RS := REGEXP_REPLACE(REGEXP_REPLACE(IN_DATA,'[^[:digit:]]'), '([[:digit:]]{6})([[:digit:]])([[:digit:]]{6})','\1-******' ) ;   -- 7번자리도 안보이게
        --RS := REGEXP_REPLACE(REGEXP_REPLACE(IN_DATA,'[^[:DIGIT:]]'), '([[:DIGIT:]]{6})([[:DIGIT:]])([[:DIGIT:]]{6})','\1-\2******' ) ; -- 7번째자리 보이게
     ELSIF V_TYPE = 'NAME' THEN /*성명 홍길동 -> 홍길* */
        --RS := RPAD( SUBSTR(IN_DATA, 0, LENGTH(IN_DATA)-1) , LENGTHB(IN_DATA)-1,'*') ;
        RS := REGEXP_REPLACE(IN_DATA, '\w', '*', 2);
     ELSIF V_TYPE IN ('BIRTH','BIRTHDAT') THEN /*생년월일 85년1월3일 -> 85년**월**일 */
        RS := REGEXP_REPLACE(IN_DATA,'([0-9]{2,4})([년\-]\ ?)([0-9]{1,2})([월\-]\ ?)([0-9]{1,2})(일?)', '\1\2**\4**\6') ;

     ELSIF V_TYPE IN ('CAR','CARNO') THEN /*차량번호  */
        RS := REGEXP_REPLACE(IN_DATA, '\w', '*', 4);
     ELSE
        RS := REGEXP_REPLACE(IN_DATA, '\w', '*', 4);
     END IF;
 RETURN(RS);
END;
/