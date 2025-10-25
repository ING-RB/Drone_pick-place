function vnr = validateVariableNamingRule(vnr)
%validateVariableNamingRule   Property/arguments validation for VariableNamingRule.
%
%   Also does partial matching for "preserve" and "modify".

%   Copyright 2022 The MathWorks, Inc.

    vnr = validatestring(vnr, ["preserve" "modify"], string(missing), "VariableNamingRule");
end
