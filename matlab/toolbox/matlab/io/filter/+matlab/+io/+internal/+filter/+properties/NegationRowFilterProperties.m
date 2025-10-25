classdef NegationRowFilterProperties < matlab.io.internal.filter.properties.ComposedRowFilterProperties
%NegationRowFilterProperties   Properties object for NegationRowFilter.
%
%   See also: rowfilter

%   Copyright 2021 The MathWorks, Inc.

    methods
        function props = NegationRowFilterProperties(filter)
            props = props@matlab.io.internal.filter.properties.ComposedRowFilterProperties(filter);
        end
    end
end