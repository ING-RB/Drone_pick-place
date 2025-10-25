classdef (CaseInsensitiveProperties,TruncatedProperties) timeseriesArray < matlab.mixin.SetGet & matlab.mixin.Copyable
    %tsdata.timeseriesArray class
    %    tsdata.timeseriesArray properties:
    %       LoadedData - Property is of type 'MATLAB array'
    %
    %    tsdata.timeseriesArray methods:

    properties (SetObservable)
        LoadedData = [];
    end

    methods (Static) % static methods
        %----------------------------------------
        function h = loadobj(s)
            h = tsdata.timeseriesArray;
            if isstruct(s)
                if ~isfield(s,'Data') % Loaded @timeseriesArray may be empty
                    s.Data = [];
                end
                if ~isfield(s,'GridFirst') % Loaded @timeseriesArray may be empty
                    s.GridFirst = true;
                end
                h.LoadedData = s;
            else
                h = s;
            end
        end
    end
end

