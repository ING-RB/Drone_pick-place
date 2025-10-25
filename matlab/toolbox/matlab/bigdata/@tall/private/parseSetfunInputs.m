function flagsOut = parseSetfunInputs(a, b, adaptorA, numOutputs, fcnName, varargin)
% PARSESETFUNINPUTS Parse and validate input and flag arguments for tall
% set methods.
%   Limitations:
%   1. 'stable' flag is not supported.
%   2. 'legacy' flag is not supported.
%   3. Inputs of type 'char' are not supported.
%
% The flags in varargin are found and their indices noted.
% Then, validateSyntax is called to check for any invalid flags or other 
% invalid inputs that would throw errors in the in-memory function. The
% flags and the flag indices are returned to the main function. The
% possible flags out are "rows", "sorted" and "r2012a".

%   Copyright 2018 The MathWorks, Inc.

% Flags must not be tall.
tall.checkNotTall(fcnName, 2, varargin{:});

% Character vector inputs are not supported.
errMsg = message("MATLAB:bigdata:array:SetFcnUnsupportedChar", fcnName);
a = tall.validateNotTypeWithError(a, fcnName, 1, "char", errMsg);
b = tall.validateNotTypeWithError(b, fcnName, 2, "char", errMsg);

% Find flags and note the index where it was found in varargin.
flagVals = ["rows" "sorted" "stable" "legacy" "r2012a"];
nFlagVals = numel(flagVals);
flagInds = zeros(1, nFlagVals);
for ii = 1:numel(varargin(:))
    flag = string(varargin{ii});
    foundFlag = startsWith(flagVals, flag, "IgnoreCase", true);
    if sum(foundFlag) ~= 1
        break;
    end
    flagInds(foundFlag) = ii;
end

% tall.validateSyntax will throw the same errors as the in-memory set
% method. The error messages thrown for unknown input or unknown flag are
% different for tall set methods because the 'legacy' flag is not
% supported, and so is not listed as a valid flag.
try
    tall.validateSyntax(str2func(fcnName), {a, b, varargin{:}}, ...
        "DefaultType", "double", "InputGroups", [1 1], "NumOutputs", numOutputs); %#ok<CCAT>
catch E
    % Rephrase error messages. Only enumerate the supported flags for tall.
    if strcmpi(E.identifier, strcat("MATLAB:", fcnName, ":UnknownInput"))
        error(message("MATLAB:bigdata:array:SetFcnUnknownInput"));
    elseif strcmpi(E.identifier, strcat("MATLAB:", fcnName, ":UnknownFlag"))
        error(message("MATLAB:bigdata:array:SetFcnUnknownFlag", flag));
    else
        rethrow(E);
    end
end

% 'stable' flag is not supported for tall-tall set methods.
if flagInds(3)
    error(message("MATLAB:bigdata:array:SetFcnStableNotSupported"));
end

% 'legacy' flag not supported for tall-tall set methods
if flagInds(4)
    error(message("MATLAB:bigdata:array:SetFcnLegacyNotSupported"));
end

% The 'rows' flag is ignored for table and timetable inputs.
if flagInds(1) && (adaptorA.Class == "table" || adaptorA.Class == "timetable")
   flagInds(1) = 0; 
end

% The possible flags out are "rows", "sorted" and "r2012a".
flagsOut = cellstr(flagVals(flagInds>0));

end