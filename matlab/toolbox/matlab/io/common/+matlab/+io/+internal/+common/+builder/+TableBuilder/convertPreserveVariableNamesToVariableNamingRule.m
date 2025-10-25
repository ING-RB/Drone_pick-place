function vnr = convertPreserveVariableNamesToVariableNamingRule(tf)
%convertPreserveVariableNamesToVariableNamingRule   Validates PreserveVariableNames
%   and converts it to VariableNamingRule.

%   Copyright 2022 The MathWorks, Inc.

    classes = ["logical" "double"];
    attributes = ["scalar" "binary"];
    validateattributes(tf, classes, attributes, string(missing), "PreserveVariableNames");

    if tf
        vnr = "preserve";
    else
        vnr = "modify";
    end
end