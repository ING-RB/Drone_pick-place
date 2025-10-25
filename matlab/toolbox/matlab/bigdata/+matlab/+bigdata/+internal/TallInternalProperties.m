%TallInternalProperties
% Internal properties of tall.
%
% Holding these properties here instead of tall directly is slight more
% performant with respect to cycle detection.

%   Copyright 2018-2021 The MathWorks, Inc.

classdef (Abstract, AllowedSubclasses={?tall}) TallInternalProperties
    properties (GetAccess = protected, SetAccess = immutable)
        ValueImpl;
    end
    
    properties (Access = protected, Dependent = true)
        Adaptor;
    end

    properties (Access = private)
        AdaptorImpl;
    end
    
    methods
        function obj = TallInternalProperties(valueImpl, adaptor)
            obj.ValueImpl = valueImpl;
            obj.Adaptor = adaptor;
        end
        
        function obj = set.Adaptor(obj, adaptor)
            obj.AdaptorImpl = adaptor;
            hSetMetadata(obj.ValueImpl, buildMetadata(adaptor));
        end

        function out = get.Adaptor(obj)
            out = obj.AdaptorImpl;
        end
    end
end
