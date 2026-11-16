
-- i used ACCOUNTADMIN because it's a trial account, wouldn't do that on a real one

create warehouse if not exists olist_wh
    warehouse_size = 'XSMALL'
    auto_suspend = 60          --
    auto_resume = true
    initially_suspended = true;

create database if not exists olist;
use database olist;

create schema if not exists raw;     
create schema if not exists staging;  
create schema if not exists marts;     

-- the reviews file has free text comments with commas and line breaks in them, so the quotes setting matters
create or replace file format raw.csv_fmt
    type = csv
    skip_header = 1
    field_optionally_enclosed_by = '"'
    null_if = ('')
    empty_field_as_null = true;

create stage if not exists raw.olist_stage
    file_format = raw.csv_fmt;
