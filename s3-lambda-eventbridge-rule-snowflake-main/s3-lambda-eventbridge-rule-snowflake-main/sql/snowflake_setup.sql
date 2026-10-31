-- =============================================================================
-- Currency Exchange Rate Pipeline - Snowflake Setup
-- =============================================================================
-- Run as a role with privileges to create databases, schemas, tables, and
-- procedures (e.g. SYSADMIN). Adjust warehouse/role to your environment.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Database & Schema
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS CURRENCY_DB;
CREATE SCHEMA   IF NOT EXISTS CURRENCY_DB.CURRENCY;

USE DATABASE CURRENCY_DB;
USE SCHEMA   CURRENCY;

-- -----------------------------------------------------------------------------
-- 2. Tables
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE CURRENCY.EXCHANGE_RATES_RAW (
    id              STRING       DEFAULT UUID_STRING(),
    load_timestamp  TIMESTAMP_NTZ,
    response_raw    VARIANT
);

CREATE OR REPLACE TABLE CURRENCY.EXCHANGE_RATES_STG (
    timestamp_utc   TIMESTAMP_NTZ,   -- UTC timestamp of the exchange rate
    base_currency   VARCHAR(10),     -- Base currency (e.g. USD)
    target_currency VARCHAR(10),     -- Target currency (e.g. EUR, BTC)
    exchange_rate   FLOAT            -- Exchange rate value
);

CREATE OR REPLACE TABLE CURRENCY.EXCHANGE_RATES (
    timestamp_utc   TIMESTAMP_NTZ,
    base_currency   VARCHAR(10),
    target_currency VARCHAR(10),
    exchange_rate   FLOAT
);

-- -----------------------------------------------------------------------------
-- 3. Loading Procedure
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE CURRENCY_DB.CURRENCY.SP_EXCHANGE_RATE_LOADING(
    p_json_data STRING,
    p_datetime  TIMESTAMP_NTZ
)
RETURNS NUMBER(8, 0)
LANGUAGE SQL
AS
$$
BEGIN
    -- Reset raw landing zone
    TRUNCATE TABLE CURRENCY.EXCHANGE_RATES_RAW;

    INSERT INTO CURRENCY.EXCHANGE_RATES_RAW (load_timestamp, response_raw)
    SELECT :p_datetime, PARSE_JSON(:p_json_data);

    -- Reset staging
    TRUNCATE TABLE CURRENCY.EXCHANGE_RATES_STG;

    INSERT INTO CURRENCY.EXCHANGE_RATES_STG (
        timestamp_utc, base_currency, target_currency, exchange_rate
    )
    SELECT
        TO_TIMESTAMP_NTZ(r.response_raw:timestamp::NUMBER) AS timestamp_utc,
        r.response_raw:base::STRING                        AS base_currency,
        f.key::STRING                                      AS target_currency,
        f.value::FLOAT                                     AS exchange_rate
    FROM CURRENCY.EXCHANGE_RATES_RAW r,
         LATERAL FLATTEN(input => r.response_raw:rates) f
    WHERE TO_TIMESTAMP_NTZ(r.response_raw:timestamp::NUMBER) = :p_datetime;

    -- Upsert into the curated table
    MERGE INTO CURRENCY.EXCHANGE_RATES AS target
    USING CURRENCY.EXCHANGE_RATES_STG AS source
        ON  target.timestamp_utc   = source.timestamp_utc
        AND target.base_currency   = source.base_currency
        AND target.target_currency = source.target_currency
    WHEN NOT MATCHED THEN
        INSERT (timestamp_utc, base_currency, target_currency, exchange_rate)
        VALUES (
            source.timestamp_utc,
            source.base_currency,
            source.target_currency,
            source.exchange_rate
        );

    RETURN 1;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. Validation helpers (run manually as needed)
-- -----------------------------------------------------------------------------
-- TRUNCATE TABLE CURRENCY.EXCHANGE_RATES_RAW;
-- TRUNCATE TABLE CURRENCY.EXCHANGE_RATES_STG;
-- TRUNCATE TABLE CURRENCY.EXCHANGE_RATES;

-- SELECT * FROM CURRENCY.EXCHANGE_RATES_RAW;
-- SELECT * FROM CURRENCY.EXCHANGE_RATES_STG;
-- SELECT * FROM CURRENCY.EXCHANGE_RATES;

-- SELECT timestamp_utc, COUNT(*)
-- FROM   CURRENCY.EXCHANGE_RATES
-- GROUP  BY timestamp_utc
-- ORDER  BY timestamp_utc;
