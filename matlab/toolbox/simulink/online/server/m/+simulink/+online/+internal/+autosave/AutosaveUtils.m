% Copyright 2021 The MathWorks, Inc.

classdef AutosaveUtils

    methods (Static, Access = public)
        function extWithDot = getAutosaveExt()
            extWithDot = Simulink.internal.AutoSaveHelper.autosaveext;
        end  % getAutosaveExt
    end

    % protected methods, accessible by unit tests
    methods (Access = protected)
        function obj = AutosaveUtils()
        end  % AutosaveUtils
    end

    properties (Access = protected)
    end
end
