classdef PluginProviderData
    % This class is undocumented and may change in a future release.
    
    %   PluginProviderData Methods:
    %       PluginProviderData - Class constructor
    %       optionWasProvided - Query if an option was provided
    %
    %   PluginProviderData Properties:
    %       Options - Struct containing the name-value pairs provided
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties(SetAccess=immutable)
        % Options - Struct containing the name-value pairs provided
        Options (1,1) struct;
        TestSuite;
    end
    
    methods
        function data = PluginProviderData(options, testsuite)
            %PluginProviderData - Class constructor
            %
            %   DATA = PluginProviderData(OPTIONS) constructs a PluginProviderData
            %   object. This object holds on to an OPTIONS struct which contains the
            %   provided name-value pairs that help determine how plugins should be
            %   constructed.
            arguments
                options (1,1) struct = struct
                testsuite = [];
            end
            data.Options = options;
            data.TestSuite = testsuite;
        end
        
        function bool = optionWasProvided(data,optionName,optionValue)
            % optionWasProvided - Query if an option was provided
            %
            %   BOOL = optionWasProvided(PLUGINPROVIDERDATA,NAME) returns true if the
            %   specified option NAME was provided.
            %
            %   BOOL = optionWasProvided(PLUGINPROVIDERDATA,NAME,VALUE) returns true if
            %   an option was provided with the specified value.
            bool = isfield(data.Options,optionName) && ...
                (nargin < 3 || isequaln(data.Options.(optionName),optionValue));
        end
    end
end

% LocalWords:  plugins isequaln
