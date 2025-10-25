classdef ros2node < robotics.core.internal.mixin.Unsaveable & handle
%ros2node Create a ROS 2 node on the specified network
%   The ros2node object represents a ROS 2 node, and provides a foundation
%   for communication with the rest of the ROS 2 network.
%
%   N = ros2node("NAME") initializes the ROS 2 node with the given NAME.
%   The node connects with the default domain identification 0 unless
%   otherwise specified by the ROS_DOMAIN_ID environment variable.
%
%   The node uses default ROS Middleware implementation 'rmw_fastrtps_cpp'
%   unless otherwise specified by the RMW_IMPLEMENTATION environment variable.
%
%   N = ros2node("NAME",ID) initializes the ROS 2 node with NAME and
%   connects it to the network using the given domain ID. The acceptable
%   values for the domain identification are between 0 and 232.
%
%   N = ros2node(___,Name,Value) provides additional options specified by
%   one or more Name,Value pair arguments. You can specify several
%   name-value pair arguments in any order as
%   Name1,Value1,...,NameN,ValueN:
%
%      "Parameters" - Parameters to be declared during node startup.
%                     Specify a structure containing parameters to be declared
%                     in the generated node. Parameters can be scalars or arrays
%                     of int64, logical, string, or double datatype. For
%                     parameters that are arrays, specify their values as cell
%                     array.
%
%   Node properties:
%      Name         - (Read-only) Name of the node
%      ID           - (Read-only) Network domain identification
%
%   Node methods:
%      resolveName  - Check and resolve ROS 2 name
%      delete       - Shut down node and attached ROS 2 objects
%      getParameter - Get parameter declared in the ROS 2 node
%      setParameter - Set parameter declared in the ROS 2 node
%
%   Example:
%      % Initialize the node "/node_1" on the default network
%      node1 = ros2node("/node_1");
%
%      % Create a separate node that connects to a different network
%      % identified with domain 2
%      node2 = ros2node("/node_2",2);
%
%      % Declare parameters while creating a node
%      parameters.my_double = 2.0;
%      parameters.my_namespace.my_int = int64(1);
%      parameters.my_double_array = {1.1 2.2 3.3};
%      node3 = ros2node("/node_3","Parameters",parameters);
%
%      % Set parameter with a new value
%      setParameter(node3,"my_double",3.0);
%
%      % Get the new value from this node
%      doubleParam = getParameter(node3,"my_double","DataType","double");

%   Copyright 2019-2023 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        %Name - Name of the node
        %   This needs to be unique in the ROS 2 network
        Name
    end

    properties (SetAccess = private)
        %ID - Domain identification of the network
        %   Default: 0
        ID
    end

    properties (Transient, Access = ?ros.internal.mixin.InternalAccess)
        %InternalNode - Internal representation of the node object
        InternalNode = []

        %ServerNodeHandle - Designation of the node on the server
        ServerNodeHandle = []

        %Parameters - Parameters to be declared during node creation
        Parameters

        %ServerPath - Path to the out-of-process server executable
        ServerPath

        %LogPath - Path to store log files
        LogPath

        %ServerStartPath - Path in which to start the server
        ServerStartPath

        %EnvApplicablePath - Environment variable set to use the server
        EnvApplicablePath

        %DataArrayLibPath - Path to MATLAB data array dynamic library
        DataArrayLibPath

        %ServerMode - Indicates if the server uses ROS or "echo" mode
        %   0 - Communication over ROS possible
        %   1 - Communication only reflected back by server
        ServerMode

        %LogLevel - Indicates types of logs created during operations
        %   0 - Trace (most logging)
        %   1 - Debug
        %   2 - Info
        %   3 - Warning
        %   4 - Error
        %   5 - Fatal (least logging)
        LogLevel

        %RMWImplementation - To use the ROS Middleware Implementation based on DDS
        RMWImplementation

        %ListofNodeDependentHandles - List of weak handles to objects attached to the node
        ListofNodeDependentHandles =  {}
    end

    properties (Constant, Access = ?ros.internal.mixin.InternalAccess)
        %EnvDomainId - Environment variable that stores domain ID
        EnvDomainId = 'ROS_DOMAIN_ID'

        %EnvRMW - Environment variable that indicates middleware to use
        EnvRMW = 'RMW_IMPLEMENTATION'

        %DefaultServerMode - Default to using ROS 2 network
        DefaultServerMode = 0

        %DefaultLogLevel - Default to logging only fatal exceptions
        DefaultLogLevel = 5

        %DefaultLogPath - Default to logging in temporary directory
        DefaultLogPath = fullfile(tempdir, [ 'ros2_log_' char(datetime('now','Format','ddMMyyyyHHmmssSSS'))]);


        %DefaultParameters - Default to not declare any parameters
        DefaultParameters = struct.empty

        %DebugMode - Do not debug in release
        DebugMode = false

        %MinimumWinVer - Minimum Windows version number supported by ROS 2
        MinimumWinVer = 10
    end

    methods
        function obj = ros2node(name, varargin)
        %ros2node Create a ROS 2 node object
        %   The "name" argument is required and specifies a node name to be
        %   used on the ROS 2 network.

        % Parse and assign input
            narginchk(1, inf)
            name = convertStringsToChars(name);
            parser = getParser(obj);
            parse(parser, name, varargin{:});
            obj.ID = parser.Results.id;
            obj.Parameters = parser.Results.Parameters;
            obj.ServerMode = parser.Results.ServerMode;
            obj.LogLevel = parser.Results.LogLevel;
            obj.LogPath = parser.Results.LogPath;
            obj.RMWImplementation = parser.Results.RMWImplementation;

            % Create node
            setupPaths(obj)
            createNode(obj, parser.Results.name, parser.Results.id);
            nodesNamesMapKey = sprintf('%s_%s_%s', obj.Name, num2str(obj.ID), obj.RMWImplementation);
            nodesNamesMap = ros.ros2.internal.getMATLABROS2NodesMap('add',nodesNamesMapKey,obj.Name); %#ok<NASGU>

            function parser = getParser(obj)
            % Domain ID can be set by environment variable but input is given priority

                defaultId = ros.internal.utilities.getDefaultDomainID;
                defaultRMWImplementation = ros.internal.utilities.getCurrentRMWImplementation;

                % Set up parser
                parser = inputParser;
                addRequired(parser, 'name', ...
                            @(x) validateattributes(x, ...
                                                    {'char', 'string'}, ...
                                                    {'nonempty', 'scalartext'}, ...
                                                    'ros2node', ...
                                                    'name'));
                addOptional(parser, 'id', defaultId, ...
                            @(x) validateattributes(x, ...
                                                    {'numeric'}, ...
                                                    {'scalar', 'integer', 'nonnegative', '<=', 232}, ...
                                                    'ros2node', ...
                                                    'id'))
                addParameter(parser,'Parameters', obj.DefaultParameters, ...
                             @(x) validateattributes(x, ...
                                                     {'struct'}, ...
                                                     {'scalar'}, ...
                                                     'ros2node', ...
                                                     'Parameters'))
                addParameter(parser, 'ServerMode', obj.DefaultServerMode, ...
                             @(x) validateattributes(x, ...
                                                     {'numeric', 'logical'}, ...
                                                     {'scalar', '>=', 0, '<=', 2}, ...
                                                     'ros2node', ...
                                                     'ServerMode'))
                addParameter(parser, 'LogLevel', obj.DefaultLogLevel, ...
                             @(x) validateattributes(x, ...
                                                     {'numeric'}, ...
                                                     {'scalar', '>=', 0, '<=', 5}, ...
                                                     'ros2node', ...
                                                     'LogLevel'))
                addParameter(parser, 'LogPath', obj.DefaultLogPath, ...
                             @(x) validateattributes(x, ...
                                                     {'char', 'string'}, ...
                                                     {'nonempty', 'scalartext'}, ...
                                                     'ros2node', ...
                                                     'LogPath'))
                addParameter(parser, 'RMWImplementation', defaultRMWImplementation, ...
                             @(x) validateattributes(x, ...
                                                     {'char', 'string'}, ...
                                                     {'scalartext'}, ...
                                                     'ros2node', ...
                                                     'RMWImplementation'))
            end
        end

        function [paramValue, status] = getParameter(obj, paramName)
        %getParameter Get parameter declared in the ROS 2 node
        %   [paramValue] = getParameter(nodeObj,paramName) returns
        %   paramValue, that has the value of specified parameter paramName,
        %   associated with the ros2node object, nodeObj. If it failed to
        %   return a parameter value, the function displays an error message.
        %
        %   [paramValue,STATUS] = getParameter(nodeObj,paramName) returns
        %   paramValue and the final status. If it successfully gets the
        %   parameter value, paramValue will be the parameter value, and
        %   STATUS will be true. Otherwise, DATA will be an empty double, and
        %   STATUS will be false.
        %
        %   [paramValue, STATUS] = getParameter(___,Name,Value) provide
        %   additional to properly generate C++ code.
        %
        %       "DataType" - Expected data type of the returned parameter.
        %                    By default, the returned data type will be
        %                    double. User can use this name-value pair to
        %                    declare other types. Supported data types
        %                    includes: logical, uint8, int64, double, char,
        %                    string.

            narginchk(2,2);
            % Validate the input argument
            paramName = robotics.internal.validation.validateString(paramName, false, 'getParameter', 'name');

            % Initialize status as false
            status = false;

            % Get value
            try
                rawParamValue = getParam(obj.InternalNode, obj.ServerNodeHandle, paramName);
            catch ex
                if nargout > 1
                    paramValue = [];
                    return;
                else
                    newEx = MException(message('ros:mlros2:parameter:FailedToGetParam', ...
                                               paramName));
                    throw(newEx.addCause(ex));
                end
            end
            % Only convert cell array to numerical array if such cell array
            % contains numerical values or logical values
            if iscell(rawParamValue) && (isnumeric(rawParamValue{1,1}) || islogical(rawParamValue{1,1}))
                paramValue = zeros([1,length(rawParamValue)],class(rawParamValue{1,1}));
                for paramIndex = 1:length(rawParamValue)
                    paramValue(1,paramIndex) = rawParamValue{1,paramIndex};
                end
            else
                paramValue = rawParamValue;
            end

            status = true;
        end

        function setParameter(obj, paramName, paramValue)
        %setParameter Set parameter declared in the ROS 2 node
        %   setParameter(nodeObj,paramName,paramValue) set the value paramValue
        %   for declared parameter named paramName in the ros2node object, nodeObj.
        %   If such parameter does not exist in the ROS 2 node, an error message
        %   will be thrown.

            narginchk(3,3);
            % Validate the input argument
            paramName = robotics.internal.validation.validateString(paramName, true, 'setParameter', 'paramName');
            % Considering the default ROS 2 Parameter behavior, we will
            % only allow setting parameters that have been declared during
            % node creation. Refer to the following webpage for more
            % information:
            % https://docs.ros.org/en/rolling/Concepts/About-ROS-2-Parameters.html
            listOfParams = getParamNames(obj.InternalNode, obj.ServerNodeHandle);
            if ~any(strcmp(listOfParams,paramName))
                error(message('ros:internal:transport:ParameterNotDeclared', ...
                              paramName));
            end

            % Convert string to character vector or cell array of character
            % vector. Leave other types unchanged. Backend code will handle
            % invalid types.
            if isstring(paramValue)
                if length(paramValue)==1
                    % Syntax: "ABC"
                    paramValue = convertStringsToChars(paramValue);
                else
                    % Syntax: ["ABC" "DEF"]
                    paramValue = cellstr(paramValue);
                end
            elseif iscell(paramValue)
                % Syntax: {"ABC" "DEF"}; {'A' 'B' 'C'}
                paramValue = cellfun(@(x) convertStringsToChars(x), paramValue, 'UniformOutput', false);
            else
                % Do nothing for other data types
            end

            % Set value, throw error message directly if anything failed
            setParam(obj.InternalNode, obj.ServerNodeHandle, paramName, paramValue);
        end

        function delete(obj)
        %delete Remove reference to ROS 2 node
        %   delete(NODE) removes the reference in NODE to the ROS 2 node on
        %   the network. If no further references to the node exist, such
        %   as would be in publishers and subscribers, the node is shut
        %   down.

            try
                if ~isempty(obj.ServerNodeHandle) && (~isempty(obj.InternalNode) && isvalid(obj.InternalNode))
                    nodesNamesMapKey = sprintf('%s_%s_%s', obj.Name, num2str(obj.ID), obj.RMWImplementation);
                    nodesNamesMap = ros.ros2.internal.getMATLABROS2NodesMap('remove',nodesNamesMapKey); %#ok<NASGU>
                end

                % Delete objects associated with node, such as publishers
                % and subscribers
                for nodeDepHandle = obj.ListofNodeDependentHandles
                    if ~isempty(nodeDepHandle{1})
                        delete(nodeDepHandle{1}.get());
                    end
                end
                % Delete reference to node, without deleting internal node
                obj.InternalNode = [];

                if strcmp(obj.RMWImplementation, 'rmw_iceoryx_cpp')
                   ros.ros2.internal.RouDiExecutor.manageRouDiApplication("removeNode");
                end
            catch ex
                warning(message('ros:mlros2:node:ShutdownError', ...
                                ex.message))
            end
        end
    end

    methods (Hidden, Access = ...
             {?ros.slros2.internal.block.GetParameter, ...
              ?matlab.unittest.TestCase})
        function setSingleParameter(obj, paramName, paramValue)
        %setSingleParameter Set one single parameter given name and value
        %   This function takes one parameter name and value and set to the
        %   node. With this function, undeclared parameters can also be set
        %   to an existed node. Note that this function will try to set the
        %   parameter directly. All parameter value type verification shall
        %   be done before calling this function.
        %   Supported types include: int64, double, logical, string, int64
        %   array, double array, logical array, and uint8 array.

            % String need to be converted to char to write to backend
            paramValue = convertStringsToChars(paramValue);
            if ~ischar(paramValue)
                % numerical array need to be converted to cell array to
                % write to backend
                paramValue = num2cell(paramValue);
            end

            setParam(obj.InternalNode, obj.ServerNodeHandle, paramName, paramValue);
        end
    end

    % All dependent properties are read from the server
    methods
        function name = get.Name(obj)
        %get.Name Custom getter for Name property

        % Allow errors to be thrown from getServerInfo
            nodeInfo = getServerInfo(obj);
            name = strcat(nodeInfo.namespace, '/', nodeInfo.name);
        end
    end

    methods (Access = ?ros.internal.mixin.InternalAccess)
        function rosName = resolveName(obj, name)
        %resolveName Check and resolve ROS 2 name
        %   ROSNAME = resolveName(NODE, NAME) resolves the ROS 2 name, NAME
        %   that is associated with a particular node object, NODE.
        %   This function returns a ROS 2 name with properly applied
        %   namespace in ROSNAME.
        %
        %   This function will take the relevant namespace into account if
        %   the name is defined as relative name without a leading slash.
        %   A relative name, e.g. 'testName', will be resolved relative to
        %   this node's root namespace. A private name, e.g. '~/testName'
        %   will be resolved relative to this node's namespace. A leading
        %   forward slash indicates a global name, e.g. '/testName'.
        %
        %   This function does not check the name against the ROS 2
        %   naming standard - it only resolves valid namespace indicators
        %   to be relative to the appropriate node-related namespace.

            rosName = name;                 % Default to no change
            if startsWith(name, '~/')       % Private namespace
                                            % Replace private token with full node name
                                            % (using full node namespace and name as the new namespace)
                rosName = strrep(name, '~', obj.Name);
            elseif ~startsWith(name, '/')   % Relative namespace
                nodeInfo = getServerInfo(obj);
                rosName = strcat(nodeInfo.namespace, '/', name);
            end
        end
    end

    methods (Hidden)
        function ret = isValidNode(obj)
            ret = isValidNode(obj.InternalNode, obj.ServerNodeHandle, {'isvalidnode'});
        end
    end
    
    methods (Access = private)
        function setupPaths(obj)
        %setupPaths Set paths for out-of-process server, logging, and
        %   starting directory

        % System architecture keys
            archKeys = {'win64', 'glnxa64', 'maci64','maca64'};
            arch = computer('arch');

            % MCR separates toolbox MATLAB files from library files
            % Use matlabroot to find correct path even in compiled code
            mlRoot = matlabroot;

            % Server executable
            serverPathBase = ...
                fullfile(mlRoot, 'toolbox', 'ros', 'bin', arch);
            serverPathMap = ...
                containers.Map(archKeys, ...
                               {'libmwros2server.exe', ...   % win64
                                'libmwros2server', ...       % glnxa64
                                'libmwros2server',...        % maci64
                                'libmwros2server'});         % maca64
            obj.ServerPath = fullfile(serverPathBase, serverPathMap(arch));

            % Server start directory suggestion
            startPathBase = fullfile(mlRoot, 'sys', 'ros2', ...
                                     arch, 'ros2');
            startPathMap = ...
                containers.Map(archKeys, ...
                               {'bin', ...    % win64
                                'lib', ...    % glnxa64
                                'lib', ...    % maci64
                                'lib'});      % maca64
            obj.ServerStartPath = fullfile(startPathBase, ...
                                           startPathMap(arch));

            % Architecture-applicable load path environment variable
            envPathMap = ...
                containers.Map(archKeys, ...
                               {'PATH', ...             % win64
                                'LD_LIBRARY_PATH', ...  % glnxa64
                                'DYLD_LIBRARY_PATH',... % maci64
                                'DYLD_LIBRARY_PATH'});  % maca64
            obj.EnvApplicablePath = envPathMap(arch);

            obj.DataArrayLibPath = fullfile(mlRoot,'extern','bin',arch);
        end

        function createNode(obj, name, id)
        %createNode Create node on ROS 2 network

            try
                % Split fully qualified name into namespace and base name
                [baseName, namespace] = nodeNameParts(name);

                % Create internal node representation
                obj.InternalNode = ros.internal.Node;

                % Set domain ID correctly and remove it after node creation
                domainIdCurrentValue = getenv(obj.EnvDomainId);
                setenv(obj.EnvDomainId, num2str(id, '%.0f'));
                cleanDomainId = onCleanup(...
                    @() setenv(obj.EnvDomainId, domainIdCurrentValue));

                % Set path correctly and remove it after node creation
                % The path environment variable needs the server start
                % directory on it, and the custom message libraries in case
                % they are required later in the node process
                customMsgRegistry = ros.internal.CustomMessageRegistry.getInstance('ros2');
                customMsgDirList = getBinDirList(customMsgRegistry);
                pathCurrentValue = getenv(obj.EnvApplicablePath);
                pathEnvOrgValue = getenv('PATH');
                setenv(obj.EnvApplicablePath, ...
                       strjoin([customMsgDirList obj.ServerStartPath obj.DataArrayLibPath pathCurrentValue], pathsep))
                cleanPath = onCleanup(...
                    @() setenv(obj.EnvApplicablePath, pathCurrentValue));

                [clearRMW, resetDDSEnv, resetPath, cleanPlatformPath] = ros.ros2.internal.setRMWImplPathEnv(...
                    obj.RMWImplementation, ...
                    pathEnvOrgValue, ...
                    obj.EnvApplicablePath, ...
                    pathCurrentValue); %#ok<ASGLU>

                resetEnv = ros.ros2.internal.setUserMiddlewareEnvironment(obj.RMWImplementation); %#ok<NASGU>

                % Start node on ROS 2 network
                returnCall = create(obj.InternalNode, baseName, ...
                                    namespace, obj.ServerPath, ...
                                    obj.ServerStartPath, obj.ServerMode, ...
                                    obj.LogLevel, obj.LogPath, ...
                                    obj.DebugMode);

                % Check output and error if node not created
                if isempty(returnCall) || ~isstruct(returnCall)
                    error(message('ros:mlros2:node:InvalidReturnCallError'))
                elseif ~isfield(returnCall, 'handle') || ...
                        isempty(returnCall.handle)
                    error(message('ros:mlros2:node:InvalidReturnCallHandleError'))
                end

                obj.ServerNodeHandle = returnCall.handle;

                % Declare parameters if specified
                if ~isempty(obj.Parameters)
                    % Recursively traverse the structure and set parameters
                    recursiveParameterDeclaration('',obj.Parameters,obj.InternalNode, obj.ServerNodeHandle);
                end
            catch ex
                if strcmp(ex.identifier, ...
                          'ros:internal:transport:ServerNotUpError')
                    error(message('ros:mlros2:node:CreationServerError', ...
                                  name));
                elseif strcmp(ex.identifier,'ros:internal:transport:ServerFailedToStart') && ...
                        ~checkMinimumWinVer(obj.MinimumWinVer)
                    error(message('ros:mlros2:node:UnsupportedWindowsVersion', ...
                                  name));
                elseif strcmp(ex.identifier,'ros:internal:transport:ROS2InvalidParameterDataType')
                    rethrow(ex);
                elseif strcmp(ex.identifier,'ros:mlros2:parameter:InvalidParamStruct')
                    rethrow(ex);
                else
                    newEx = MException(message('ros:mlros2:node:CreationGenericError', ...
                                               name));
                    throw(newEx.addCause(ex));
                end
            end
        end

        function nodeInfo = getServerInfo(obj)
        %getServerInfo Get node properties from server

        % Ensure properties are valid
            if isempty(obj.InternalNode) || ~isvalid(obj.InternalNode)
                error(message('ros:mlros2:node:InvalidInternalNodeError'))
            elseif isempty(obj.ServerNodeHandle)
                error(message('ros:mlros2:node:InvalidServerHandleError'))
            end

            % Extract node information
            try
                nodeInfo = nodeinfo(obj.InternalNode, ...
                                    obj.ServerNodeHandle, []);
            catch ex
                newEx = MException(message('ros:mlros2:node:GetInfoError'));
                throw(newEx.addCause(ex));
            end
        end
    end

    methods (Static = true, Access = private)
        function name = matlabCodegenRedirect(~)
        % MATLAB codegen
            name = 'ros.internal.codegen.ros2node';
        end
    end
end

% Helper functions
function [baseName, namespace] = nodeNameParts(name)
%nodeNameParts Split name into namespace and node name
%   Requires fully qualified name as input
%   Assumes name is a character vector and non-empty

% Extract name as last text block separated by slash
    nameSplit = strsplit(name, '/', 'CollapseDelimiters', false);
    namespace = strjoin(nameSplit(1:end-1), '/');
    baseName = nameSplit{end};
end

function ret = checkMinimumWinVer(minVerNum)
    ret = true;
    if ispc
        [status, result] = system('ver');
        if status == 0
            % Example result on Windows 10  --> Microsoft Windows [Version 10.0.17763.720]
            % Example result on Windows 7   --> Microsoft Windows [Version 6.1.7601]
            % The result string is consistent across machines with different locales
            % Pattern match to extract the leading version number, e.g. 10 or 6
            version = regexp(result, '(?<=.*Version )\d*(?=\..*)', 'match','once');
            if ~isempty(version) && ~isnan(str2double(version)) && (str2double(version) < minVerNum)
                ret = false;
            end
        end
    end
end

function recursiveParameterDeclaration(baseString, ParamStruct, internalNode, serverNodeHandle)
% Ensure ParamStruct is scalar
    if ~isscalar(ParamStruct)
        error(message('ros:mlros2:parameter:InvalidParamStruct'));
    end

    fs = fieldnames(ParamStruct);
    % length must be greater than 0
    fslen = length(fs);
    for i = 1:fslen
        if isempty(baseString)
            newStr = fs{i};
        else
            % Only need the dot notation for nested parameters
            newStr = [baseString '.' fs{i}];
        end

        nextLayer = ParamStruct.(fs{i});
        if isstruct(nextLayer)
            recursiveParameterDeclaration(newStr, nextLayer, internalNode, serverNodeHandle);
        else
            % nextLayer is the actual value if it is not a structure
            if isstring(nextLayer)
                if length(nextLayer)==1
                    % Syntax: "ABC"
                    nextLayer = convertStringsToChars(nextLayer);
                else
                    % Syntax: ["ABC" "DEF"]
                    nextLayer = cellstr(nextLayer);
                end
            elseif iscell(nextLayer)
                % Syntax: {"ABC" "DEF"}; {1 2 3}; {'A' 'B' 'C'}
                nextLayer = cellfun(@(x) convertStringsToChars(x), nextLayer, 'UniformOutput', false);
            else
                if (numel(nextLayer)>1 && ~ischar(nextLayer)) || isa(nextLayer,'uint8')
                    % Syntax: [1 2 3]; uint8(1) etc.
                    nextLayer = num2cell(nextLayer);
                else
                    % Syntax: ['a' 'b' 'c']; 1; true. This can be passed directly to
                    % backend.
                end
            end
            % Set parameter with valid name and value
            setParam(internalNode, serverNodeHandle, newStr, nextLayer);
        end
    end
end

% LocalWords:  ROSNAME
