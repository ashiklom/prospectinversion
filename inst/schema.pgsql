CREATE TABLE results(
    ResultID bigserial PRIMARY KEY,
    SampleCode text,
    /*SampleCode text REFERENCES samples(SampleCode),*/
    ModelName text,
    Parameter text,
    ParameterMean numeric,
    ParameterSD numeric,
    ParameterQ025 numeric,
    ParameterQ500 numeric,
    ParameterQ975 numeric
);

GRANT INSERT ON TABLE results TO PUBLIC;
