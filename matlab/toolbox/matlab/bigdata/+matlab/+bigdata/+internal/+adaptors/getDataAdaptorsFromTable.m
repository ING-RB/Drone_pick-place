function varAdaptors = getDataAdaptorsFromTable(tAdap)
% Recursively extract the adaptors for table variables, expanding out
% subtables until we reach non-tabular types. Input can be either a table
% or a tabular adaptor.
%
% Example:
%   >> t = table([1;2;3],[4;5;6]);
%   >> t.Var3 = table(single([7;8;9]),[10;11;12]);
%   >> matlab.bigdata.internal.adaptors.getDataAdaptorsFromTable(t)
%   ans = 1×4 cell array

% Copyright 2022 The MathWorks, Inc.

if ~isa(tAdap, "matlab.bigdata.internal.adaptors.TabularAdaptor")
    assert(istabular(tAdap), "Called getDataAdaptorsFromTable with something that isn't tabular.")
    tAdap = matlab.bigdata.internal.adaptors.getAdaptor(tAdap);
end

varAdaptors = {};
for ii=1:width(tAdap)
    a = tAdap.getVariableAdaptor(ii);
    if isa(a, "matlab.bigdata.internal.adaptors.TabularAdaptor")
        % Variable is itself a table so get the adaptors for its variables.
        varAdaptors = [varAdaptors, matlab.bigdata.internal.adaptors.getDataAdaptorsFromTable(a)]; %#ok<AGROW>
    else
        varAdaptors{1,end+1} = a; %#ok<AGROW>
    end
end
end
