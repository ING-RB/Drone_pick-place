classdef AcceptsUseExcel < matlab.io.internal.FunctionInterface
    %
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    
    properties (Parameter)
        UseExcel = false;
    end
    
    properties (Parameter, Hidden, Dependent)
        Basic;
    end
    
    methods
        function obj = set.Basic(obj,rhs)
            obj.UseExcel = rhs;
            obj.UseExcel = ~obj.UseExcel;
        end
        
        function Basic = get.Basic(obj)
            Basic = ~obj.UseExcel; % consider erroring here.
        end
        
        function obj = set.UseExcel(obj,rhs)
            if ~(isnumeric(rhs) || islogical(rhs)) || ~isscalar(rhs)
                error(message('MATLAB:table:InvalidLogicalVal','UseExcel'))
            end
            obj.UseExcel = logical(rhs);
            if obj.UseExcel && isWebServerCheck
                warning(message("MATLAB:spreadsheet:book:webserviceExcelWarn"));
            end
        end
    end
end

function webAppStatus = isWebServerCheck()
    persistent WebSessionUseExcel
    if isempty(WebSessionUseExcel) && builtin('_is_web_app_server')
        WebSessionUseExcel = true;
        webAppStatus = WebSessionUseExcel;
    else
        webAppStatus = false;
    end
end