classdef AcceptsDateLocale < matlab.io.internal.FunctionInterface
    %ACCEPTSDATELOCALE An interface for functions which accept a DATELOCALE.

    % Copyright 2018 The MathWorks, Inc.
    properties (Parameter)
       DateLocale = matlab.internal.datetime.getDefaults('locale');
    end
    
    methods
        function obj = set.DateLocale(obj,val)
            temp = matlab.io.DatetimeVariableImportOptions('DatetimeLocale',val);
            obj.DateLocale = temp.DatetimeLocale;
        end
    end
end

