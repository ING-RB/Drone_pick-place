function javaMap = convertStructToJavaMap(struct)
% Helper Method to convert a struct into a java hash map.
%
% Inputs:
%
%   struct : a structure
%
% Outputs:
%
%   javaMap  : a Java java.util.Map object where the keys are the fields
%              of the struct and the values are its values

% Copyright 2013-2016 The MathWorks, Inc.

% Error Checking
narginchk(1, 1);
validateattributes(struct, ...
    {'struct'}, {});

% get the fields of the struct and loop over
fields = fieldnames(struct);

pvPairs = {};
for idx = 1:length(fields)
    pvPairs = [pvPairs, {fields{idx}, struct.(fields{idx})}]; 
end

javaMap = appdesservices.internal.peermodel.convertPvPairsToJavaMap(pvPairs);

end