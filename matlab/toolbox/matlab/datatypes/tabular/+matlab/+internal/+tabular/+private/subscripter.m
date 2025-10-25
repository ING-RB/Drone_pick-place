classdef (Abstract, AllowedSubclasses = {?timerange, ?vartype, ?withtol, ?matlab.io.RowFilter}) subscripter < matlab.mixin.internal.Scalar & matlab.internal.datatypes.saveLoadCompatibility
%SUBSCRIPTER Internal class for tabular subscripting.
% This class is for internal use only and will change in a
% future release.  Do not use this class.

%    An abstract class to create subclasses that wrap around subscripts to a table
%    to handle them specially.

    %   Copyright 2016-2022 The MathWorks, Inc.
    
    methods(Abstract, Access={?withtol, ?timerange, ?vartype, ?matlab.io.RowFilter, ?matlab.internal.tabular.private.tabularDimension, ?tabular})
        % The getSubscripts method is called by table subscripting to get the matches
        % for whatever subscripted are specified in the object's properties.
        % Different subscripters require information from different components
        % of the tabular object to do this task. It can use the public interface
        % or the special exposed methods and properties. The getSubscripts
        % method takes the tabular and a char row vector telling the dimension
        % along which the subscripter is being applied. It is the subscritper's
        % responsibility to error if it does not support a given type of tabular
        % or if it cannot be applied along a given dimension.
        subs = getSubscripts(obj,t,operatingDim)
    end
end

