classdef (Abstract, AllowedSubclasses = {?matlab.internal.coder.timerange, ...
        ?matlab.internal.coder.withtol}) subscripter %#codegen
%SUBSCRIPTER Internal class for tabular subscripting.
% This class is for internal use only and will change in a
% future release.  Do not use this class.

%    An abstract class to create subclasses that wrap around subscripts to a table
%    to handle them specially.

    %   Copyright 2019 The MathWorks, Inc.
    
    methods(Abstract, Access={?matlab.internal.coder.timerange, ?matlab.internal.coder.withtol, ...
            ?matlab.internal.coder.tabular.private.tabularDimension, ...
            ?matlab.internal.coder.tabular})
        % The getSubscripts method is called by table subscripting to get the matches
        % for whatever subscripted are specified in the object's properties. It needs to
        % know (from the table's subscripter for that dimension) the size of the
        % dimension and what (if any) are the "labels" along the dimension.
        subs = getSubscripts(obj,subscripter)
    end
end

