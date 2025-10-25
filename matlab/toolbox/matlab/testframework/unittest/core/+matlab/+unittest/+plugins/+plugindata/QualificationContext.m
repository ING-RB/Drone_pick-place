classdef QualificationContext
    % QualificationContext - Context for QualifyingPlugins.
    %   The QualificationContext is constructed by the test framework to
    %   provide the context for QualifyingPlugins to perform qualifications.
    %
    %   See Also: matlab.unittest.plugins.QualifyingPlugin
    
    % Copyright 2015-2022 The MathWorks, Inc.
    
    
    properties (Hidden, SetAccess=immutable, GetAccess=?matlab.unittest.plugins.QualifyingPlugin)
        Qualifiable_;
    end
    
    methods (Hidden, Access=?matlab.unittest.plugins.plugindata.PluginData)
        function context = QualificationContext(content)
            context.Qualifiable_ = content;
        end
    end
end

% LocalWords:  plugindata
