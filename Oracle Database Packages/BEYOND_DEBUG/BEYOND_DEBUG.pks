create or replace PACKAGE BEYOND_DEBUG AS
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

DATE        BY                COMPANY             Reference               VERSION   DESCRIPTION
==========  ================= =================== ======================  =======   ===============================================================
2023-06-18  Kyle Shackleton   BeYondWMS Ltd                               0.1       Initial Version
2023-09-12  Kyle Shackleton   BeYondWMS Ltd                               1.0       Initial Customer Implementation
2024-04-10  Kyle Shackleton   BeYondWMS Ltd                               1.1       Overload encode/print List With VARCHAR2 Datatype + Added JSON_OBJECT_T Logging Capability
2025-12-17  Kyle Shackleton   BeYondWMS Ltd.                              1.2       Rewritten for Public Release (Better Handling Of Date/Timestamps etc.)
********************************************************************************************************************************************************************************************************************************/

/* Constants */
gc_debugLevelInfo     CONSTANT INTEGER := 5;
gc_debugLevelDebug    CONSTANT INTEGER := 4;
gc_debugLevelWarning  CONSTANT INTEGER := 3;
gc_debugLevelError    CONSTANT INTEGER := 2;
gc_debugLevelCritical CONSTANT INTEGER := 1;

/* Variables */
g_dbmsOutput BOOLEAN := FALSE;

/* Print Functions */

PROCEDURE print(
    in_loggingData   IN VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN NUMBER
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN DATE
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH LOCAL TIME ZONE
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH TIME ZONE
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN BOOLEAN
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN INTERVAL DAY TO SECOND
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN INTERVAL YEAR TO MONTH
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN XMLTYPE
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE print(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,in_loggingName  IN VARCHAR2
    ,in_loggingData  IN JSON_OBJECT_T
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

/* ENCODE LIST WITH CLOB loggingList Type */

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN VARCHAR2
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN CLOB
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN NUMBER
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN DATE
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH LOCAL TIME ZONE
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH TIME ZONE
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN BOOLEAN
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN INTERVAL DAY TO SECOND
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN INTERVAL YEAR TO MONTH
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN XMLTYPE
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN JSON_OBJECT_T
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

/* ENCODE LIST WITH VARCHAR2 loggingList Type */

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN VARCHAR2
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN CLOB
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN NUMBER
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN DATE
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH LOCAL TIME ZONE
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN TIMESTAMP WITH TIME ZONE
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN BOOLEAN
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN INTERVAL DAY TO SECOND
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN INTERVAL YEAR TO MONTH
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN XMLTYPE
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE encodeList(
    in_loggingName   IN VARCHAR2
    ,in_loggingData  IN JSON_OBJECT_T
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

/* printList Functions */

PROCEDURE printList(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,io_loggingList  IN OUT NOCOPY CLOB
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE printList(
    in_loggingCaller IN VARCHAR2
    ,in_loggingLine  IN INTEGER
    ,io_loggingList  IN OUT NOCOPY VARCHAR2
    ,in_loggingLevel IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

/* Utility Functions */

FUNCTION intervalToString(
    in_interval IN INTERVAL YEAR TO MONTH
) RETURN VARCHAR2;

FUNCTION intervalToString(
    in_interval IN INTERVAL DAY TO SECOND
) RETURN VARCHAR2;

FUNCTION shouldLog(
    in_loggingLevel IN INTEGER
) RETURN BOOLEAN;

PROCEDURE setupPackageLogging(
    in_loggingName  IN VARCHAR2
    ,in_debugLevel  IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelWarning
    ,in_sessionType IN VARCHAR2 DEFAULT NULL
);

/* Exception Logging Functions */

PROCEDURE logException(
    in_loggingName IN VARCHAR2
);

PROCEDURE logExceptionHTTP(
    in_loggingName IN VARCHAR2
);

PROCEDURE writeErrorLog(
    in_loggingName  IN VARCHAR2,
    in_errorID      IN VARCHAR2,
    in_errorMessage IN VARCHAR2
);

END BEYOND_DEBUG;