%StringAdaptor Adaptor for string data.

% Copyright 2017-2018 The MathWorks, Inc.
classdef StringAdaptor < ...
        matlab.bigdata.internal.adaptors.AbstractAdaptor & ...
        matlab.bigdata.internal.adaptors.GeneralArrayParenIndexingMixin & ...
        matlab.bigdata.internal.adaptors.GeneralArrayDisplayMixin

    methods (Access = protected)
        
        function m = buildMetadataImpl(obj)
            m = matlab.bigdata.internal.adaptors.NumericishMetadata(obj.TallSize);
        end
        
    end
    
    methods
        
        function obj = StringAdaptor()
            obj@matlab.bigdata.internal.adaptors.AbstractAdaptor('string');
        end

        function varargout = subsrefBraces(~, ~, ~, ~) %#ok<STOUT>
            error(message('MATLAB:bigdata:array:SubsrefBracesNotSupported'));
        end
        function obj = subsasgnBraces(~, ~, ~, ~, ~) %#ok<STOUT>
            error(message('MATLAB:bigdata:array:SubsasgnBracesNotSupported'));
        end
        
        function names = getProperties(~)
            names = cell(0,1);
        end

    end

    methods (Access = protected)
        % Build a sample of the underlying data.
        function sample = buildSampleImpl(~, defaultType, sz, ~)
            if isequal(defaultType,'double')
                % The other types use '1', but double('1') is not equal to
                % double("1"). We need them to match for joinNamedTable to
                % work if one key is string and the other is double, e.g.,
                % to work for join(table("1",2),table(1,3),'Keys','Var1').
                sample = repmat(string(double('1')), sz);
            else
                sample = repmat("1", sz);
            end
        end
    end
end
