classdef (Hidden) EquivalentCarbondioxide < handle
    %Base class for gas sensor modules

    %  Copyright 2021 The MathWorks, Inc.
    %#codegen

    properties(Abstract, Access = protected, Constant)
        EquivalentCarbondioxideDataRegister; % output data register
    end

    methods(Abstract, Access = protected)
        data = readEquivalentCarbondioxideImpl(obj,varargin);
        initEquivalentCarbondioxideImpl(obj);
    end

    methods
        function obj = EquivalentCarbondioxide()
            coder.allowpcode('plain');
        end
    end

    methods(Access = public)
        function [data, varargout] = readEquivalentCarbondioxide(obj,varargin)
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            nargoutchk(0,2);
            data = readEquivalentCarbondioxideImpl(obj,varargin{:});
            if nargout == 2
                varargout{1} = getCurrentTime(obj.Parent);
            end
        end
    end
end