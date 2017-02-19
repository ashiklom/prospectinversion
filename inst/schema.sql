CREATE TABLE results(
    resultid integer PRIMARY KEY,
    samplecode text,
    /*SampleCode text REFERENCES samples(SampleCode),*/
    modelname text,
    parameter text,
    parametermean numeric,
    parametersd numeric,
    parameterq025 numeric,
    parameterq500 numeric,
    parameterq975 numeric
);
