classdef ResponseWrapper < matlab.mixin.SetGet & ...
        controllib.chart.internal.foundation.MixInListeners & ...
        matlab.mixin.Heterogeneous & ...
        dynamicprops
    % ResponseWrapper provides a read-only copy of the response for
    % the response view classes. Ensure that ResponseWrapper has GetAccess
    % to a response property for it to be accessible.

    % Copyright 2023-2024 The MathWorks, Inc.
    properties (Hidden, SetAccess={?controllib.chart.internal.view.wave.BaseResponseView,...
                                   ?controllib.chart.internal.view.wave.data.ResponseWrapper})
        NColumns = 1
        NRows = 1
        NResponses
    end

    properties (Hidden,Dependent,SetAccess=private)
        IsResponseValid
    end

    properties (GetAccess=private,SetAccess=immutable,WeakHandle)
        Response (1,1) controllib.chart.internal.foundation.BaseResponse
    end

    methods
        function this = ResponseWrapper(Response)
            arguments
                Response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            this.Response = Response;
            mc = metaclass(Response);            
            propResponse = mc.PropertyList;
            for ii = 1:length(propResponse)
                mp = propResponse(ii);
                propName = mp.Name;
                if ischar(mp.GetAccess) && ~strcmpi(mp.GetAccess,'public')
                    continue; % protected or private
                elseif iscell(mp.GetAccess) && ...
                        ~any(cellfun(@(x) strcmpi(x.Name,'controllib.chart.internal.view.wave.data.ResponseWrapper'), ...
                        mp.GetAccess))
                    continue; % not listed in meta array
                elseif isa(mp.GetAccess,'meta.class') && ~strcmpi(mp.GetAccess.Name,class(this))
                    continue; % not the only meta object
                end
                if strcmpi(propName,'NRows') || strcmpi(propName,'NColumns') || strcmpi(propName,'NResponses') ||...
                        strcmpi(propName,'NInputs') || strcmpi(propName,'NOutputs')
                    continue; % retained after response deleted
                end
                p = addprop(this,propName);
                p.Dependent = true;
                p.SetAccess = 'private';
                p.Hidden = mp.Hidden;
                if iscell(mp.GetAccess)
                    p.Hidden = true; % Friend properties appear hidden - cannot add friends to dynamic properties
                end
                p.GetMethod = @(this) getResponseProp(this,propName);
            end
            for ii = 1:length(this.DynamicProperties)
                propName = this.DynamicProperties(ii);
                dp = findprop(Response,propName);
                if ischar(dp.GetAccess) && ~strcmpi(dp.GetAccess,'public')
                    continue; % protected or private
                elseif iscell(dp.GetAccess) && ...
                        ~any(cellfun(@(x) strcmpi(x.Name,'controllib.chart.internal.view.wave.data.ResponseWrapper'), ...
                        dp.GetAccess))
                    continue; % not listed in meta array
                elseif isa(dp.GetAccess,'meta.class') && ~strcmpi(dp.GetAccess.Name,class(this))
                    continue; % not the only meta object
                end
                p = addprop(this,propName);
                p.Dependent = true;
                p.SetAccess = 'private';
                p.Hidden = mp.Hidden;
                if iscell(mp.GetAccess)
                    p.Hidden = true; % Friend properties appear hidden - cannot add friends to dynamic properties
                end
                p.GetMethod = @(this) getResponseProp(this,propName);
            end
            this.NResponses = Response.NResponses;
        end

        function IsResponseValid = get.IsResponseValid(this)
            IsResponseValid = ~isempty(this.Response) && isvalid(this.Response);
        end
    end
    
    methods (Access=private)
        function value = getResponseProp(this,propName)
            value = this.Response.(propName);
        end

        function setProp(this,prop,value)
            this.(prop) = value;
        end
    end

    methods (Hidden)
        function response = getResponse(this)
            response = this.Response;
        end
    end
end