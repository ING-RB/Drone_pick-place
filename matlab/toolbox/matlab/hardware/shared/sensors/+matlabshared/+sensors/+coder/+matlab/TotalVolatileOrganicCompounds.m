classdef (Hidden) TotalVolatileOrganicCompounds < handle
   %Base class for TVOC gas sensor modules
    
    %  Copyright 2021 The MathWorks, Inc.
    %#codegen
    
    properties(Abstract, Access = protected, Constant)
        TVOCDataRegister; % output data register
    end
    
    methods(Abstract, Access = protected)
        data = readTotalVolatileOrganicCompoundsImpl(obj,varargin);
        initTotalVolatileOrganicCompoundsImpl(obj);
    end
    
    methods
        function obj = TotalVolatileOrganicCompounds()
            coder.allowpcode('plain');
        end
    end
    
    methods(Access = public)
        function [data, varargout] = readTotalVolatileOrganicCompounds(obj,varargin)
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            nargoutchk(0,2);
            data = readTotalVolatileOrganicCompoundsImpl(obj,varargin{:});
            if nargout == 2
                varargout{1} = getCurrentTime(obj.Parent);
            end
        end
    end
end