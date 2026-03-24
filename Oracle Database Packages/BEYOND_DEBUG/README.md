![BeyondWMS Logo](../../assets/beyondwms-logo.png)
# BEYOND_DEBUG (PL/SQL)

BeYondWMS enhanced debugging/logging package for BlueYonder Dispatcher

> **Important:** this package is **not** intended to replace Oracle’s `DBMS_OUTPUT` or standard Oracle logging.  
> It primarily wraps the **Dispatcher Package Logging** `dcsdba.libMqsDebug.print()` and adds consistent formatting, datatype handling, encoded list support, and safer behaviour for long values/error stacks.

---

## What this package does

`BEYOND_DEBUG` provides:

- **A consistent log line format** including calling unit + line number, plus optional key/value formatting.
- **Overloads for many common datatypes**
- **Chunking for long payloads** (notably `CLOB`, `XMLTYPE` and `JSON_OBJECT_T`) so dispatcher logging can handle large values safely.
- **Encoded list building** (`encodeList`) so you can build a structured debug block and print it once (`printList`).
- **Standardised exception logging** (`logException`, `logExceptionHTTP`) and an **error-log chunking wrapper** (`writeErrorLog`) around `dcsdba.libError.writeErrorLog`.
- Optional echoing to `DBMS_OUTPUT` when `g_dbmsOutput = TRUE`, with **defensive handling** of `ORU-10027` buffer overflow.

---

## Validated Dispatcher Versions

The following versions of Dispatcher have been validated for compatibility with BEYOND_DEBUG

- Dispatcher 2019.1.0.1
- Dispatcher 2024 (All Service Packs and Hotfixes)
- Dispatcher 2025 (All Service Packs and Hotfixes)

## Validated Oracle Database Versions

The following versions of Oracle Database have been validated for compatibility with BEYOND_DEBUG

- Oracle 19c

---

## Version / provenance

From package header history:

- 2023-06-18: Initial version
- 2023-09-12: Initial Customer Implementation
- 2024-04-10: Added overloads and JSON logging
- 2025-12-17: Public Release

---

## Debug levels

The package exposes the following constants:

| Name | Value |
|---|---:|
| `gc_debugLevelInfo` | 5 |
| `gc_debugLevelDebug` | 4 |
| `gc_debugLevelWarning` | 3 |
| `gc_debugLevelError` | 2 |
| `gc_debugLevelCritical` | 1 |

These map directly to the dispatcher debug level (`dcsdba.libMqsDebug.getDebugLevel`) and are used to determine if processing should occur by `shouldLog()`.

---

## Installation

- It is recommended that all BeYondWMS Database Packages are installed to their own database schema rather than the schema that Dispatcher is installed too
    - When making calls to this package from another schema then the package name will either need to be prefixed with the schema name for example `<beyond_package_schema>.BEYOND_DEBUG.print` or this package will need to be registered as a Public Synonym
    - Assumption is that Dispatcher is installed to the standard schema (DCSDBA)
        - If this assumption is incorrect then the code will need to be updated replacing "dcsdba" with the schema name that Dispatcher is installed to.
    - The Following Grants are required from the Dispatcher schema for BEYOND_DEBUG installation
        - Package `libMqsDebug` (`GRANT EXECUTE on libMqsDebug TO <beyond_package_schema>;`)
        - Package `libSession` (`GRANT EXECUTE on libSession TO <beyond_package_schema>;`)
        - Package `libError` (`GRANT EXECUTE on libError TO <beyond_package_schema>;`)
        - Table `package_logging_data` (`GRANT SELECT on package_logging_data TO <beyond_package_schema>;`)
        - Table `error` (`GRANT SELECT on error TO <beyond_package_schema>;`)
    - The Following Oracle Grants are required for BEYOND_DEBUG installation (May be Granted As Standard)
        - Package `SYS.UTL_HTTP` (`GRANT EXECUTE on SYS.UTL_HTTP TO <beyond_package_schema>;`) - Optionally remove `logExceptionHTTP` from the Package
        - PROCEDURE `SYS.DBMS_OUTPUT` (`GRANT EXECUTE on SYS.DBMS_OUTPUT TO <beyond_package_schema>;`) - This is usually available publically and doesnt need an explicit GRANT
        - PROCEDURE `SYS.DBMS_LOB` (`GRANT EXECUTE on SYS.DBMS_LOB TO <beyond_package_schema>;`) - This is usually available publically and doesnt need an explicit GRANT
        - PROCEDURE `SYS.DBMS_UTILITY` (`GRANT EXECUTE on SYS.DBMS_UTILITY TO <beyond_package_schema>;`) - This is usually available publically and doesnt need an explicit GRANT



---

## Configuration

### Enable/disable DBMS_OUTPUT echoing

```plsql
BEYOND_DEBUG.g_dbmsOutput := TRUE;  -- echo log lines to DBMS_OUTPUT (best-effort)
BEYOND_DEBUG.g_dbmsOutput := FALSE; -- default
```

When enabled, `print(VARCHAR2)` attempts `dbms_output.put_line(...)`.
This is very useful for reading the package logging during development and debugging from an Oracle SQL Client such as SQL Developer.

#### DBMS_OUTPUT overflow behaviour (ORU-10027)

If DBMS_OUTPUT buffer overflows (typically raised as `ORA-20000: ORU-10027 ...`), the base `print` procedure:

- sets `BEYOND_DEBUG.g_dbmsOutput := FALSE;` Disabling Further DBMS_OUTPUT for the Session
- writes an error log via `BEYOND_DEBUG.writeErrorLog(...)`
- continues to log via `dcsdba.libMqsDebug.print()` so logging continues even if DBMS_OUTPUT fails (So long as the logging Level is set Sufficiently)

---

## Core formatting

### Contextual format

Log lines are formatted as:

```
<caller>[Line <line>] - <message>
```
For Example
```
BEYOND_DEBUG.TEST[Line 40] - Print With Key Value Examples
```

If `in_loggingName` is provided, it becomes a consistent key/value format:

```
<caller>[Line <line>] - <name> = [<value>]
```
For Example
```
BEYOND_DEBUG.TEST[Line 41] - KEYEXAMPLE = [VALUE EXAMPLE]
```

---

## API overview

### `print` procedures

#### Base print

This Procedure is not intended for Direct calls and is instead the core which calls the Standard Dispatcher Logging Procedure and also outputs to DBMS_OUTPUT if enabled.

```plsql
PROCEDURE print(
    in_loggingData   IN VARCHAR2,
    in_loggingLevel  IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);
```

- Best-effort to echo to `DBMS_OUTPUT` (if enabled via `BEYOND_DEBUG.g_dbmsOutput`)
- Always calls the standard dispatcher package logging print `dcsdba.libMqsDebug.print(in_loggingData, in_loggingLevel)`

#### Contextual print overloads

```plsql
PROCEDURE print(
    in_loggingCaller IN VARCHAR2,
    in_loggingLine   IN INTEGER,
    in_loggingName   IN VARCHAR2,
    in_loggingData   IN <datatype>,
    in_loggingLevel  IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);
```

Supported datatypes in the package spec:

- `VARCHAR2`
- `CLOB`
- `NUMBER`
- `DATE`
- `TIMESTAMP`
- `TIMESTAMP WITH LOCAL TIME ZONE`
- `TIMESTAMP WITH TIME ZONE`
- `BOOLEAN`
- `INTERVAL DAY TO SECOND`
- `INTERVAL YEAR TO MONTH`
- `XMLTYPE`
- `JSON_OBJECT_T`

#### Datatype conversions used (package body)

- `CLOB` → Chunked into 4000 character chunks
- `DATE` → `TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ss')`
- `TIMESTAMP` → `TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF')`
- `TIMESTAMP WITH LOCAL TIME ZONE` → `TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF TZR')`
- `TIMESTAMP WITH TIME ZONE` → `TO_CHAR(in_loggingData,'YYYY-MM-DD hh24:mi:ssXFF TZR')`
- `BOOLEAN` → `'True' | 'False'`
- `INTERVAL ...` → `intervalToString(...)`
- `XMLTYPE` → `getClobVal()` (guarded by `shouldLog` and null check)
- `JSON_OBJECT_T` → `to_clob()` (guarded by `shouldLog` and null check)

---

## Handling long values (dispatcher logging)

### CLOB chunking

Because the dispatcher logger may not handle very large payloads well, the `print(..., in_loggingData IN CLOB, ...)` implementation:

- Builds a formatted CLOB (caller + line + optional key/value wrapper)
- Uses `DBMS_LOB.GETLENGTH` and `DBMS_LOB.SUBSTR` to emit chunks of **4000 characters**
- Calls the base `print(VARCHAR2)` for each chunk

This keeps payloads readable and prevents a single oversized call to the dispatcher logger.

---

## Encoded list logging

Encoded list logging is designed for structured “dump blocks” (multiple values printed together).

A primary use case for `Encoded Lists` is to log lists of Parameters / Variables for example
- Parameters at the start of a Procedure or on Exception
- Key Variables / Fields after Executing a block of SQL

There are two families of `encodeList` overloads:

- `io_loggingList IN OUT NOCOPY CLOB`
- `io_loggingList IN OUT NOCOPY VARCHAR2`

This is to allow the Use of VARCHAR2 or CLOB List Variables (VARCHAR2 should be preferred unless there is a risk of Logging Data Exceeding the VARCHAR Length Limits)

### Behaviour

Each `encodeList` call appends:

- Carriage Return + Line Feed (`CHR(13)||CHR(10)`)
- Indent (`'    '`)
- either:
  - `key = [value]`, or
  - just `value` if no name provided

Example final output shape:

```
TEST[Line 71] - 
    List:
    KEY1 = [VALUE1]
    KEY2 = [VALUE2]
    ...
```

### Important note about log levels

From the body header:

> `printList` should always be called with a logging level **<= the lowest logging level used in encodeList**

Reason: `encodeList` only appends when `shouldLog(level)` is true; if you call `printList` at a stricter level, you can end up not printing what you built (or printing inconsistently).

### `printList`

Two overloads exist:

```plsql
PROCEDURE printList(
    in_loggingCaller IN VARCHAR2,
    in_loggingLine   IN INTEGER,
    io_loggingList   IN OUT NOCOPY CLOB,
    in_loggingLevel  IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);

PROCEDURE printList(
    in_loggingCaller IN VARCHAR2,
    in_loggingLine   IN INTEGER,
    io_loggingList   IN OUT NOCOPY VARCHAR2,
    in_loggingLevel  IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelInfo
);
```

Both:

- call `BEYOND_DEBUG.print(... io_loggingList ...)`
- then clear the list (`io_loggingList := NULL;`)
- also clear it on exception before re-raising

This is to allow the Printing of VARCHAR2 or CLOB List Variables

---

## Utility functions

### `intervalToString`

```plsql
FUNCTION intervalToString(in_interval IN INTERVAL YEAR TO MONTH) RETURN VARCHAR2;
FUNCTION intervalToString(in_interval IN INTERVAL DAY TO SECOND) RETURN VARCHAR2;
```

Outputs human-readable strings such as:

- `1 YEARS 3 MONTHS`
- `2 DAYS 5 HOURS 30 MINUTES 15 SECONDS`

### `shouldLog`

```plsql
FUNCTION shouldLog(in_loggingLevel IN INTEGER) RETURN BOOLEAN;
```

Returns `TRUE` when:

- `dcsdba.libMqsDebug.getDebugLevel >= in_loggingLevel`, **or**
- `BEYOND_DEBUG.g_dbmsOutput = TRUE`

This is used to avoid expensive formatting/conversion work when logging won’t be emitted.

---

## Package logging setup

### `setupPackageLogging`

This procedure can be used by Custom Developments where a session is not setup by Dispatcher.
- This should not be used in any PL/SQL which is called from a standard Dispatcher session such as
    - RDT Rules
    - Merge Rules
    - Database triggers which are fired by standard Dispatcher sessions
    - etc.
- This Procedure can be used where a standard Dispatcher session is not initiated such as:
    - Scheduler Jobs/Programs
    - Calls from third party applications / middleware
    - etc.

```plsql
PROCEDURE setupPackageLogging(
    in_loggingName  IN VARCHAR2,
    in_debugLevel   IN INTEGER DEFAULT BEYOND_DEBUG.gc_debugLevelWarning,
    in_sessionType  IN VARCHAR2 DEFAULT NULL
);
```

Behaviour (package body):

- sets session id via `dcsdba.libMqsDebug.setSessionId(USERENV('SESSIONID'), <session_type>, in_loggingName)`
- sets debug level via `dcsdba.libMqsDebug.setDebugLevel(in_debugLevel)`
- default session type constant is `'BWMS'` if `in_sessionType` is null

---

## Exception logging

### `logException`

This is a standardised exception logging procedure intended where the desired outcome is to log that an exception has occured and information to help diagnose the issue.

```plsql
PROCEDURE logException(in_loggingName IN VARCHAR2);
```

When `SQLCODE <> 0`, it:

- prints “EXCEPTION OCCURED:” (as in body)
- logs `SQLCODE`
- captures:
  - `DBMS_UTILITY.FORMAT_CALL_STACK`
  - `DBMS_UTILITY.FORMAT_ERROR_STACK`
  - `DBMS_UTILITY.FORMAT_ERROR_BACKTRACE`
- writes chunk-safe error rows via `BEYOND_DEBUG.writeErrorLog(...)`
- prints the captured call stack / error stack / backtrace via `BEYOND_DEBUG.print(...)`

If logging fails inside this routine, it falls back to:

```plsql
dcsdba.libError.writeErrorLog(..., 'Error Logging Exception For [...]');
```

### `logExceptionHTTP`

```plsql
PROCEDURE logExceptionHTTP(in_loggingName IN VARCHAR2);
```

Adds UTL_HTTP-specific diagnostics when `SQLCODE <> 0`:

- `utl_http.get_detailed_sqlcode`
- `utl_http.get_detailed_sqlerrm`

Both are written via `BEYOND_DEBUG.writeErrorLog`, then printed via `BEYOND_DEBUG.print`.

### `writeErrorLog` (chunk-safe)

```plsql
PROCEDURE writeErrorLog(
    in_loggingName  IN VARCHAR2,
    in_errorID      IN VARCHAR2,
    in_errorMessage IN VARCHAR2
);
```

Wraps `dcsdba.libError.writeErrorLog` with chunking support:

- target chunk size: **360 characters** (`lc_errorMessageSize`)
- `in_loggingName` truncated to **70**
- `in_errorID` truncated to **10**
- if the message is longer than 360, it loops and writes multiple rows

if this wrapper fails, it writes a final fallback error row:

```plsql
dcsdba.libError.writeErrorLog(..., 'Error Writing Error Log');
```

---

## Example usage

### Basic logging

```plsql
DECLARE
  lc_debugName VARCHAR2(70) := 'Test';
BEGIN
  BEYOND_DEBUG.g_dbmsOutput := TRUE;

  BEYOND_DEBUG.print(lc_debugName, $$PLSQL_LINE, NULL, 'Found Order:', BEYOND_DEBUG.gc_debugLevelInfo);
  BEYOND_DEBUG.print(lc_debugName, $$PLSQL_LINE, 'ORDER_ID', 1001, BEYOND_DEBUG.gc_debugLevelInfo);
  BEYOND_DEBUG.print(lc_debugName, $$PLSQL_LINE, 'START_TS', SYSTIMESTAMP, BEYOND_DEBUG.gc_debugLevelInfo);
END;
/
```

### Encoded list dump

```plsql
DECLARE
  lc_debugName VARCHAR2(70) := 'Test';
  l_loggingList CLOB;
BEGIN
  BEYOND_DEBUG.encodeList(NULL, 'Found Order:', l_loggingList, BEYOND_DEBUG.gc_debugLevelInfo);
  BEYOND_DEBUG.encodeList('ORDER_ID', 1001, l_loggingList, BEYOND_DEBUG.gc_debugLevelInfo);
  BEYOND_DEBUG.encodeList('CUSTOMER', 'Acme Corp', l_loggingList, BEYOND_DEBUG.gc_debugLevelInfo);
  BEYOND_DEBUG.encodeList('REQUEST_JSON', JSON_OBJECT_T.parse('{"x":1}'), l_loggingList, BEYOND_DEBUG.gc_debugLevelInfo);

  BEYOND_DEBUG.printList(lc_debugName, $$PLSQL_LINE, l_loggingList, BEYOND_DEBUG.gc_debugLevelInfo);
END;
/
```

---

## Notes

- `XMLTYPE.getClobVal()` and `JSON_OBJECT_T.to_clob()` can be expensive; this library guards them with `shouldLog(...)` and null checks.
- `encodeList` uses CRLF (`CHR(13)||CHR(10)`) + 4-space indentation for readability.
- `printList` **clears** the list after printing (and also clears it on exception).
- Tests / Example Usage can be found in the `Tests` Directory
    - `Tests.sql` contains examples or printing all compatible Datatypes via both print and encodeList
    - `Expected Output.sql` contains the expected DBMS_OUTPUT which should be printed when running `Tests.sql`
---

## License

Copyright (c) 2025 BeyondWMS Ltd.

Licensed under the MIT License. See the repository LICENSE file:
`https://github.com/BeYondWMS/dispatcher-extension-libs-public`
