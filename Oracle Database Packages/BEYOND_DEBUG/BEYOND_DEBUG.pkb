create or replace PACKAGE BODY BEYOND_DEBUG AS
/********************************************************************************************************************************************************************************************************************************
  ____    __     __             ___          ____  __  _____   _     _      _
 |  _ \   \ \   / /            | \ \        / /  \/  |/ ____| | |   | |    | |
 | |_) | __\ \_/ /__  _ __   __| |\ \  /\  / /| \  / | (___   | |   | |_ __| |
 |  _ < / _ \   / _ \| '_ \ / _` | \ \/  \/ / | |\/| |\___ \  | |   | __/ _` |
 | |_) |  __/| | (_) | | | | (_| |  \  /\  /  | |  | |____) | | |___| || (_| |
 |____/ \___||_|\___/|_| |_|\__,_|   \/  \/   |_|  |_|_____/  |______\__\__,_|

Copyright (c) 2025 BeyondWMS Ltd.

This source file is licensed under the MIT License.
See the LICENSE file in the root of this repository (https://github.com/BeYondWMS/dispatcher-extension-libs-public)
for full license terms.

----------------------------------------------------------------------------------------------------
NAME: BEYOND_DEBUG
DESCRIPTION: BeYondWMS Enhanced Dispatcher Debugging Package
----------------------------------------------------------------------------------------------------
********************************************************************************************************************************************************************************************************************************/

/********************************************************************************************************************************************************************************************************************************
BeYond WMS Ltd.
–
NAME : print
–
DESCRIPTION : Procedure to Print Lines to Package Logs and DBMS_OUTPUT where applicable
-
DATE        BY                COMPANY             Reference               VERSION   DESCRIPTION
==========  ================= =================== ======================  =======   ===============================================================
2023-06-04  Kyle Shackleton   BeYond WMS Ltd                              1.0       Initial Version
2024-03-28  Kyle Shackleton   BeYond WMS Ltd                              1.1       Added JSON_OBJECT_T Logging Capability
2025-12-17  Kyle Shackleton   BeYond WMS Ltd.                             1.2       Prevented Hard Failures if DBMS_OUTPUT BUFFER Overflows
********************************************************************************************************************************************************************************************************************************/

/* Base print Procedure */
PROCEDURE print(
    in_loggingData   IN VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.g_dbmsOutput THEN
        << DBMS_OUTPUT_HANDLER >>
        BEGIN
            dbms_output.put_line(in_loggingData);
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -20000 AND INSTR(SQLERRM, 'ORU-10027') > 0 THEN
                    -- Buffer overflow: stop using DBMS_OUTPUT this session.
                    BEYOND_DEBUG.g_dbmsOutput := FALSE;
                    BEYOND_DEBUG.writeErrorLog($$PLSQL_UNIT, 'ORU-10027', SYS_CONTEXT('USERENV', 'MODULE') || '/' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || '/' || SYS_CONTEXT('USERENV', 'OS_USER') || ' - DBMS_OUTPUT Buffer Has Overflown, Setting g_dbmsOutput to FALSE');
                ELSE
                    RAISE;
                END IF;
        END DBMS_OUTPUT_HANDLER;
    END IF;
    dcsdba.libMqsDebug.print(in_loggingData, in_loggingLevel);
END print;

/* VARCHAR2 Package Logging */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    BEYOND_DEBUG.print(
        in_loggingCaller -- The Calling Object
            || '[Line '|| in_loggingLine ||'] - ' -- The Calling Object Line Number
            || (CASE WHEN in_loggingName IS NOT NULL THEN in_loggingName || ' = ' -- The "Variable" Name being Logged
            || '[' || in_loggingData || ']' ELSE in_loggingData END), -- The Data being Logged
        in_loggingLevel
    );
END print;

/* CLOB Package Logging */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
    /* CONSTANTS */
    lc_bufferSize CONSTANT INTEGER := 4000;

    /* VARIABLES */
    l_clob CLOB;
    l_clobLength INTEGER;
    l_buffer VARCHAR2(4000 CHAR);
    l_offset SIMPLE_INTEGER := 1;
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN -- Processing CLOB Could be Expensive, so only call if required
        l_clob := in_loggingCaller -- The Calling Object
            || '[Line '|| in_loggingLine ||'] - ' -- The Calling Object Line Number
            || (CASE WHEN in_loggingName IS NOT NULL THEN in_loggingName || ' = ' -- The "Variable" Name being Logged
            || '[' || in_loggingData || ']' ELSE in_loggingData END); -- The Data being Logged

        l_clobLength := DBMS_LOB.GETLENGTH(l_clob); -- Retrieve Character Length of CLOB

        WHILE l_offset <= l_clobLength LOOP
            l_buffer := DBMS_LOB.SUBSTR(l_clob, lc_bufferSize, l_offset);
            BEYOND_DEBUG.print(l_buffer, in_loggingLevel);
            l_offset := l_offset + lc_bufferSize;
        END LOOP;
    END IF;
END print;

/* Convert Number To VARCHAR2 */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN NUMBER
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    BEYOND_DEBUG.print(
        in_loggingCaller
        ,in_loggingLine
        ,in_loggingName
        ,TO_CHAR(in_loggingData)
        ,in_loggingLevel
    );
END print;

/* Convert DATE To VARCHAR2 */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN DATE
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    BEYOND_DEBUG.print(
        in_loggingCaller
        ,in_loggingLine
        ,in_loggingName
        ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ss')
        ,in_loggingLevel
    );
END print;

/* Convert TIMESTAMP To VARCHAR2 */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    BEYOND_DEBUG.print(
        in_loggingCaller
        ,in_loggingLine
        ,in_loggingName
        ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF')
        ,in_loggingLevel
    );
END print;

/* Convert TIMESTAMP WITH LOCAL TIME ZONE To VARCHAR2 */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH LOCAL TIME ZONE
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    BEYOND_DEBUG.print(
        in_loggingCaller
        ,in_loggingLine
        ,in_loggingName
        ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF TZR')
        ,in_loggingLevel
    );
END print;

/* Convert TIMESTAMP WITH TIME ZONE To VARCHAR2 */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH TIME ZONE
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    BEYOND_DEBUG.print(
        in_loggingCaller
        ,in_loggingLine
        ,in_loggingName
        ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF TZR')
        ,in_loggingLevel
    );
END print;

/* Convert Boolean To VARCHAR2 */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN BOOLEAN
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    BEYOND_DEBUG.print(
        in_loggingCaller
        ,in_loggingLine
        ,in_loggingName
        ,(CASE in_LoggingData WHEN TRUE THEN 'True' WHEN FALSE THEN 'False' ELSE 'NULL' END)
        ,in_loggingLevel
    );
END print;

/* Convert INTERVAL DAY TO SECOND To VARCHAR2 */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN INTERVAL DAY TO SECOND
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    BEYOND_DEBUG.print(
        in_loggingCaller
        ,in_loggingLine
        ,in_loggingName
        ,BEYOND_DEBUG.intervalToString(in_loggingData)
        ,in_loggingLevel
    );
END print;

/* Convert INTERVAL YEAR TO MONTH To VARCHAR2 */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN INTERVAL YEAR TO MONTH
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    BEYOND_DEBUG.print(
        in_loggingCaller
        ,in_loggingLine
        ,in_loggingName
        ,BEYOND_DEBUG.intervalToString(in_loggingData)
        ,in_loggingLevel
    );
END print;

/* Convert XMLTYPE To CLOB */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN XMLTYPE
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) AND in_loggingData IS NOT NULL THEN -- getClobVal Could be Expensive, so only call if required
        BEYOND_DEBUG.print(
            in_loggingCaller
            ,in_loggingLine
            ,in_loggingName
            ,in_loggingData.getClobVal()
            ,in_loggingLevel
        );
    END IF;
END print;

/* Convert JSON_OBJECT_T To CLOB */
PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN JSON_OBJECT_T
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) AND in_loggingData IS NOT NULL THEN -- to_clob Could be Expensive, so only call if required
        BEYOND_DEBUG.print(
            in_loggingCaller
            ,in_loggingLine
            ,in_loggingName
            ,in_loggingData.to_clob()
            ,in_loggingLevel
        );
    END IF;
END print;

/********************************************************************************************************************************************************************************************************************************
BeYond WMS Ltd.
–
NAME : encodeList
–
DESCRIPTION : Procedure to Encode a value into a list of values
-
DATE        BY                COMPANY             Reference               VERSION   DESCRIPTION
==========  ================= =================== ======================  =======   ===============================================================
2023-06-23  Kyle Shackleton   BeYond WMS Ltd                              1.0       Initial Version
2024-03-28  Kyle Shackleton   BeYond WMS Ltd                              1.1       Overload With VARCHAR Datatype for loggingList
2024-03-28  Kyle Shackleton   BeYond WMS Ltd                              1.2       Added JSON_OBJECT_T Logging Capability
2025-12-17  Kyle Shackleton   BeYond WMS Ltd                              1.3       Fixed Date/Timestamp Compatibility
********************************************************************************************************************************************************************************************************************************/

/* VARCHAR2 Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN VARCHAR2
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        io_loggingList :=
            io_loggingList || CHR(13) || CHR(10) || '    ' -- Existing List (If Present) + New Line
            || (CASE WHEN in_loggingName IS NOT NULL THEN in_loggingName || ' = ' -- The "Variable" Name being Logged
            || '[' || in_loggingData || ']' ELSE in_loggingData END); -- The Data being Logged
    END IF;
END encodeList;

/* CLOB Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN CLOB
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        io_loggingList :=
            io_loggingList || CHR(13) || CHR(10) || '    ' -- Existing List (If Present) + New Line
            || (CASE WHEN in_loggingName IS NOT NULL THEN in_loggingName || ' = ' -- The "Variable" Name being Logged
            || '[' || in_loggingData || ']' ELSE in_loggingData END); -- The Data being Logged
    END IF;
END encodeList;

/* NUMBER Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN NUMBER
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,TO_CHAR(in_loggingData)
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* DATE Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN DATE
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ss')
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* TIMESTAMP Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF')
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* TIMESTAMP WITH LOCAL TIME ZONE Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH LOCAL TIME ZONE
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF TZR')
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* TIMESTAMP WITH TIME ZONE Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH TIME ZONE
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF TZR')
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* BOOLEAN Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN BOOLEAN
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,(CASE in_LoggingData WHEN TRUE THEN 'True' WHEN FALSE THEN 'False' ELSE 'NULL' END)
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* INTERVAL DAY TO SECOND Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN INTERVAL DAY TO SECOND
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,BEYOND_DEBUG.intervalToString(in_loggingData)
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* INTERVAL YEAR TO MONTH Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN INTERVAL YEAR TO MONTH
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,BEYOND_DEBUG.intervalToString(in_loggingData)
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* XMLTYPE Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN XMLTYPE
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) AND in_loggingData IS NOT NULL THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,in_loggingData.getClobVal()
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* JSON_OBJECT_T Logging Data for CLOB List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN JSON_OBJECT_T
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) AND in_loggingData IS NOT NULL THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,in_loggingData.to_clob()
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* VARCHAR2 Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN VARCHAR2
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        io_loggingList :=
            io_loggingList || CHR(13) || CHR(10) || '    ' -- Existing List (If Present) + New Line
            || (CASE WHEN in_loggingName IS NOT NULL THEN in_loggingName || ' = ' -- The "Variable" Name being Logged
            || '[' || in_loggingData || ']' ELSE in_loggingData END); -- The Data being Logged
    END IF;
END encodeList;

/* CLOB Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN CLOB
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        io_loggingList :=
            io_loggingList || CHR(13) || CHR(10) || '    ' -- Existing List (If Present) + New Line
            || (CASE WHEN in_loggingName IS NOT NULL THEN in_loggingName || ' = ' -- The "Variable" Name being Logged
            || '[' || in_loggingData || ']' ELSE in_loggingData END); -- The Data being Logged
    END IF;
END encodeList;

/* NUMBER Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN NUMBER
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,TO_CHAR(in_loggingData)
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* DATE Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN DATE
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ss')
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* TIMESTAMP Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF')
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* TIMESTAMP WITH LOCAL TIME ZONE Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH LOCAL TIME ZONE
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF TZR')
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* TIMESTAMP WITH TIME ZONE Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH TIME ZONE
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF TZR')
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* BOOLEAN Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN BOOLEAN
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,(CASE in_LoggingData WHEN TRUE THEN 'True' WHEN FALSE THEN 'False' ELSE 'NULL' END)
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* INTERVAL DAY TO SECOND Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN INTERVAL DAY TO SECOND
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,BEYOND_DEBUG.intervalToString(in_loggingData)
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* INTERVAL YEAR TO MONTH Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN INTERVAL YEAR TO MONTH
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,BEYOND_DEBUG.intervalToString(in_loggingData)
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* XMLTYPE Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN XMLTYPE
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) AND in_loggingData IS NOT NULL THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,in_loggingData.getStringVal()
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/* JSON_OBJECT_T Logging Data for VARCHAR2 List */
PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN JSON_OBJECT_T
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF BEYOND_DEBUG.shouldLog(in_loggingLevel) AND in_loggingData IS NOT NULL THEN
        BEYOND_DEBUG.encodeList(
            in_loggingName
            ,in_loggingData.to_string()
            ,io_loggingList
            ,in_loggingLevel
        );
    END IF;
END encodeList;

/********************************************************************************************************************************************************************************************************************************
BeYond WMS Ltd.
–
NAME : printList
–
DESCRIPTION : Procedure to Print an Encoded List of Values and Clear the List
-             Note : printList should Always be Called with a in_loggingLevel less than or equal to the lowest in_loggingLevel used in encodeList
-
DATE        BY                COMPANY             Reference               VERSION   DESCRIPTION
==========  ================= =================== ======================  =======   ===============================================================
2023-06-23  Kyle Shackleton   BeYond WMS Ltd                              1.0       Initial Version
2024-03-28  Kyle Shackleton   BeYond WMS Ltd                              1.1       Overload With VARCHAR Datatype for loggingList
********************************************************************************************************************************************************************************************************************************/

/* Print CLOB List */
PROCEDURE printList(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF io_loggingList IS NOT NULL THEN
        BEYOND_DEBUG.print(
            in_loggingCaller  => in_loggingCaller
            ,in_loggingLine   => in_loggingLine
            ,in_loggingName   => NULL
            ,in_loggingData   => io_loggingList
            ,in_loggingLevel  => in_loggingLevel
        ); -- Call Print Procedure

        io_loggingList := NULL; -- Clear List
    END IF;
EXCEPTION
WHEN OTHERS THEN
    io_loggingList := NULL; -- Clear List
    RAISE;
END printList;

/* Print VARCHAR2 List */
PROCEDURE printList(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
) IS
BEGIN
    IF io_loggingList IS NOT NULL THEN
        BEYOND_DEBUG.print(
            in_loggingCaller  => in_loggingCaller
            ,in_loggingLine   => in_loggingLine
            ,in_loggingName   => NULL
            ,in_loggingData   => io_loggingList
            ,in_loggingLevel  => in_loggingLevel
        ); -- Call Print Procedure

        io_loggingList := NULL; -- Clear List
    END IF;
EXCEPTION
WHEN OTHERS THEN
    io_loggingList := NULL; -- Clear List
    RAISE;
END printList;


/********************************************************************************************************************************************************************************************************************************
BeYond WMS Ltd.
–
NAME : intervalToString
–
DESCRIPTION : Function which converts an INTERVAL YEAR TO MONTH or INTERVAL DAY TO SECOND to a VARCHAR2
-
DATE        BY                COMPANY             Reference               VERSION   DESCRIPTION
==========  ================= =================== ======================  =======   ===============================================================
2023-06-23  Kyle Shackleton   BeYond WMS Ltd                              1.0       Initial Version
********************************************************************************************************************************************************************************************************************************/

/* Convert INTERVAL YEAR TO MONTH To VARCHAR2 */
FUNCTION intervalToString(
    in_interval IN INTERVAL YEAR TO MONTH
) RETURN VARCHAR2 IS
BEGIN
    RETURN TO_CHAR(EXTRACT(YEAR FROM in_interval)) || ' YEARS '
        || TO_CHAR(EXTRACT(MONTH FROM in_interval)) || ' MONTHS';
END intervalToString;

/* Convert INTERVAL DAY TO SECOND To VARCHAR2 */
FUNCTION intervalToString(
    in_interval IN INTERVAL DAY TO SECOND
) RETURN VARCHAR2 IS
BEGIN
    RETURN TO_CHAR(EXTRACT(DAY FROM in_interval)) || ' DAYS '
        || TO_CHAR(EXTRACT(HOUR FROM in_interval)) || ' HOURS '
        || TO_CHAR(EXTRACT(MINUTE FROM in_interval)) || ' MINUTES '
        || TO_CHAR(EXTRACT(SECOND FROM in_interval)) || ' SECONDS';
END intervalToString;

/********************************************************************************************************************************************************************************************************************************
BeYond WMS Ltd.
–
NAME : shouldLog
–
DESCRIPTION : Function which returns a boolean indicating if the logging level is high enough or if dbms_output is enabled
-
DATE        BY                COMPANY             Reference               VERSION   DESCRIPTION
==========  ================= =================== ======================  =======   ===============================================================
2023-06-25  Kyle Shackleton   BeYond WMS Ltd                              1.0       Initial Version
********************************************************************************************************************************************************************************************************************************/
FUNCTION shouldLog(
    in_loggingLevel IN INTEGER
) RETURN BOOLEAN IS
BEGIN
    IF dcsdba.libMqsDebug.getDebugLevel >= in_loggingLevel OR BEYOND_DEBUG.g_dbmsOutput THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END shouldLog;

/********************************************************************************************************************************************************************************************************************************
BeYond WMS Ltd.
–
NAME : setupPackageLogging
–
DESCRIPTION : Procedure to Setup Package Logging
-
DATE        BY                COMPANY             Reference               VERSION   DESCRIPTION
==========  ================= =================== ======================  =======   ===============================================================
2023-06-18  Kyle Shackleton   BeYond WMS Ltd                              1.0       Initial Version
********************************************************************************************************************************************************************************************************************************/
PROCEDURE setupPackageLogging(
    in_loggingName  IN VARCHAR2
    ,in_debugLevel  IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelWarning
    ,in_sessionType IN VARCHAR2 DEFAULT NULL
) IS

/* CONSTANTS */
lc_defaultSessionType CONSTANT dcsdba.package_logging_data.session_type%type := 'BWMS';

BEGIN
    dcsdba.libMqsDebug.setSessionId(USERENV('SESSIONID'), COALESCE(in_sessionType, lc_defaultSessionType), in_loggingName);
    dcsdba.libMqsDebug.setDebugLevel(in_debugLevel);
END setupPackageLogging;

/********************************************************************************************************************************************************************************************************************************
BeYond WMS Ltd.
–
NAME : logException
–
DESCRIPTION : Procedure to Log an Exception to the Error Table + Package Logs
-
DATE        BY                COMPANY             Reference               VERSION   DESCRIPTION
==========  ================= =================== ======================  =======   ===============================================================
2023-09-12  Kyle Shackleton   BeYond WMS Ltd                              1.0       Initial Version
********************************************************************************************************************************************************************************************************************************/
PROCEDURE logException(
    in_loggingName IN VARCHAR2
) IS
    /*CONSTANTS */
    lc_debugName CONSTANT dcsdba.error.program%type := $$PLSQL_UNIT || '.logException';
    lc_sqlCode CONSTANT INTEGER := SQLCODE;
    /* VARIABLES */
    l_session VARCHAR2(16 CHAR);
    l_callStack VARCHAR2(32767);
    l_errorStack VARCHAR2(32767);
    l_errorBacktrace VARCHAR2(32767);

BEGIN
    IF lc_sqlCode <> 0 THEN
        l_session := COALESCE(dcsdba.libSession.sessionSessionID, USERENV('SESSIONID'));
        BEYOND_DEBUG.print(lc_debugName, $$PLSQL_LINE, NULL, 'EXCEPTION OCCURED:', BEYOND_DEBUG.gc_debugLevelError);
        BEYOND_DEBUG.print(lc_debugName, $$PLSQL_LINE, 'SQLCODE', lc_sqlCode, BEYOND_DEBUG.gc_debugLevelError);
        BEYOND_DEBUG.writeErrorLog(in_loggingName, 'Error', 'Session = ['|| l_session ||'] - ' || in_loggingName || ' - SQLCODE = [' || TO_CHAR(lc_sqlCode) || ']');
        l_callStack := DBMS_UTILITY.FORMAT_CALL_STACK;
        l_errorStack := DBMS_UTILITY.FORMAT_ERROR_STACK;
        l_errorBacktrace := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        BEYOND_DEBUG.writeErrorLog(in_loggingName, 'Error', 'Session = [' || l_session || '] - ' || in_loggingName || ' - Call Stack = [' || RTRIM(l_callStack, CHR(10)) ||']');
        BEYOND_DEBUG.writeErrorLog(in_loggingName, 'Error', 'Session = [' || l_session || '] - ' || in_loggingName || ' - Error Stack = [' || RTRIM(l_errorStack, CHR(10)) ||']');
        BEYOND_DEBUG.writeErrorLog(in_loggingName, 'Error', 'Session = [' || l_session || '] - ' || in_loggingName || ' - Error Backtrace = [' || RTRIM(l_errorBacktrace, CHR(10)) ||']');
        BEYOND_DEBUG.print(lc_debugName, $$PLSQL_LINE, 'l_callStack', RTRIM(l_callStack, CHR(10)), BEYOND_DEBUG.gc_debugLevelError);
        BEYOND_DEBUG.print(lc_debugName, $$PLSQL_LINE, 'l_errorStack', RTRIM(l_errorStack, CHR(10)), BEYOND_DEBUG.gc_debugLevelError);
        BEYOND_DEBUG.print(lc_debugName, $$PLSQL_LINE, 'l_errorBacktrace', RTRIM(l_errorBacktrace, CHR(10)), BEYOND_DEBUG.gc_debugLevelError);
    END IF;
EXCEPTION
WHEN OTHERS THEN
    dcsdba.libError.writeErrorLog(SUBSTR(lc_debugName,1,70), 'Error', 'Error Logging Exception For [' || in_loggingName || ']');
    RAISE;
END logException;

/********************************************************************************************************************************************************************************************************************************
BeYond WMS Ltd.
–
NAME : logExceptionHTTP
–
DESCRIPTION : Procedure to Log Additional UTL_HTTP Exception Information
-
DATE        BY                COMPANY             Reference               VERSION   DESCRIPTION
==========  ================= =================== ======================  =======   ===============================================================
2023-09-12  Kyle Shackleton   BeYond WMS Ltd                              1.0       Initial Version
********************************************************************************************************************************************************************************************************************************/
PROCEDURE logExceptionHTTP(
    in_loggingName IN VARCHAR2
) IS
    /*CONSTANTS */
    lc_debugName CONSTANT dcsdba.error.program%type := $$PLSQL_UNIT || '.logExceptionHTTP';
    lc_sqlCode CONSTANT INTEGER := SQLCODE;
    /* VARIABLES */
    l_session VARCHAR2(16 CHAR);
    l_sqlcode VARCHAR2(32767);
    l_sqlerrm VARCHAR2(32767);

BEGIN
    IF lc_sqlCode <> 0 THEN
        l_session := COALESCE(dcsdba.libSession.sessionSessionID, USERENV('SESSIONID'));
        l_sqlcode := RTRIM(utl_http.get_detailed_sqlcode, CHR(10));
        l_sqlerrm := RTRIM(utl_http.get_detailed_sqlerrm, CHR(10));
        BEYOND_DEBUG.writeErrorLog(lc_debugName, 'Error', 'Session = [' || l_session || '] - ' || lc_debugName || ' - get_detailed_sqlcode = [' || l_sqlcode ||']');
        BEYOND_DEBUG.writeErrorLog(lc_debugName, 'Error', 'Session = [' || l_session || '] - ' || lc_debugName || ' - get_detailed_sqlerrm = [' || l_sqlerrm ||']');
        BEYOND_DEBUG.print(lc_debugName, $$PLSQL_LINE, 'get_detailed_sqlcode', l_sqlcode, BEYOND_DEBUG.gc_debugLevelError);
        BEYOND_DEBUG.print(lc_debugName, $$PLSQL_LINE, 'get_detailed_sqlerrm', l_sqlerrm, BEYOND_DEBUG.gc_debugLevelError);
    END IF;
EXCEPTION
WHEN OTHERS THEN
    dcsdba.libError.writeErrorLog(SUBSTR(lc_debugName,1,70), 'Error', 'Error Logging Exception For [' || in_loggingName || ']');
    RAISE;
END logExceptionHTTP;

/********************************************************************************************************************************************************************************************************************************
BeYond WMS Ltd.
–
NAME : writeErrorLog
–
DESCRIPTION : Procedure to Write Errors to Error Table with Support For Larger Error Messages (Chunks Messages Through Buffer)
-
DATE        BY                COMPANY             Reference               VERSION   DESCRIPTION
==========  ================= =================== ======================  =======   ===============================================================
2023-09-12  Kyle Shackleton   BeYond WMS Ltd                              1.0       Initial Version
2025-12-17  Kyle Shackleton   BeYond WMS Ltd                              1.1       Resolved Bug with Error Message Chuncking Logic
********************************************************************************************************************************************************************************************************************************/
PROCEDURE writeErrorLog(
    in_loggingName  IN VARCHAR2,
    in_errorID      IN VARCHAR2,
    in_errorMessage IN VARCHAR2
) IS
    /*CONSTANTS */
    lc_debugName CONSTANT dcsdba.error.program%type := $$PLSQL_UNIT || '.writeErrorLog';
    lc_sqlCode CONSTANT INTEGER := SQLCODE;
    lc_errorMessageSize CONSTANT INTEGER := 360;
    lc_loggingNameLength CONSTANT INTEGER := 70;
    lc_errorIDLength CONSTANT INTEGER := 10;

    /* VARIABLES */
    l_bufferPosition SIMPLE_INTEGER := 1;
    l_bufferLength INTEGER;
    l_dataLength INTEGER;

BEGIN
    l_dataLength := LENGTH(in_errorMessage);
    IF l_dataLength > lc_errorMessageSize THEN
        WHILE (l_bufferPosition < l_dataLength)
        LOOP
            IF l_bufferPosition + lc_errorMessageSize > l_dataLength THEN
                l_bufferLength := l_dataLength - l_bufferPosition + 1;
            ELSE
                l_bufferLength := lc_errorMessageSize;
            END IF;
            dcsdba.libError.writeErrorLog(SUBSTR(in_loggingName, 1, lc_loggingNameLength), SUBSTR(in_errorID, 1, lc_errorIDLength), SUBSTR(in_errorMessage,l_bufferPosition,l_bufferLength));
            l_bufferPosition := l_bufferPosition + l_bufferLength;
        END LOOP;
    ELSE
        dcsdba.libError.writeErrorLog(SUBSTR(in_loggingName, 1, lc_loggingNameLength), SUBSTR(in_errorID, 1, lc_errorIDLength), in_errorMessage);
    END IF;
EXCEPTION
WHEN OTHERS THEN
    dcsdba.libError.writeErrorLog(SUBSTR(lc_debugName,1,lc_loggingNameLength), 'Error', 'Error Writing Error Log');
    RAISE;
END writeErrorLog;

END BEYOND_DEBUG;