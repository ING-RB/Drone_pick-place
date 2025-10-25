function uniqueValidFieldNames = makeH5CmpdFieldNamesValid(h5CmpdFieldNames)
%MAKEH5CMPDFIELDNAMESVALID Convert a list of text into valid MATLAB struct
%field identifiers.
%   VALIDFIELDNAMES = MAKEH5CMPDFIELDNAMESVALID(H5CMPDFIELDNAMES) returns a
%   cell array of character vectors that are valid MATLAB identifiers. The
%   input H5CMPDFIELDNAMES can be a string array or a cellstr.
%   Note: This is a helper function that is used to convert the fields of a
%   HDF5 Compound type into valid MATLAB identifiers

%   Copyright 2018-2021 The MathWorks Inc.

h5CmpdFieldNames = convertStringsToChars(h5CmpdFieldNames);

% Convert the field names into valid MATLAB identifiers. This involves
% replacing unsupported characters and also truncating the fields to be of
% length NAMELENGTHMAX
validFieldNames = matlab.lang.makeValidName( h5CmpdFieldNames, ...
                                            'ReplacementStyle', 'hex');

% If the names are all unique already, then there is no need to do anything
% further.
if numel(validFieldNames) == numel(unique(validFieldNames))
    uniqueValidFieldNames = validFieldNames;
    return
end

% Make all the field names unique and of a length not exceeeding NAMELENGTHMAX
uniqueValidFieldNames = matlab.lang.makeUniqueStrings(validFieldNames, {}, namelengthmax);

assert(~any(cellfun(@(x) strlength(x) > namelengthmax, uniqueValidFieldNames)), 'Variable names are greater than namelengthmax in length.');
assert(numel(validFieldNames) == numel(unique(uniqueValidFieldNames)), 'Variable names are not all unique.');
