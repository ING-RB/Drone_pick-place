classdef rosdevice < robotics.core.internal.mixin.Unsaveable & ...
        ros.codertarget.internal.ROSDeviceInterface
    %
    
    %ROSDEVICE Connect to a ROS device
    
    %   Copyright 2020-2023 The MathWorks, Inc.
    properties (SetAccess = private)
        DeviceAddress = ''
    end
    
    properties (SetAccess = private)
        Username = ''
    end
    
    properties (Dependent, SetAccess = private)
        AvailableNodes
    end
    
    properties (Access = {?matlab.unittest.TestCase})
        Port = 22
        
        Password = ''
        
        Parser
        
        Diagnostic
    end
    
    properties
        ROSFolder

        CatkinWorkspace
    end
    
    properties (Access = ?ros.slros.internal.InternalAccess)
        SystemExecutor
        CoreExecutor
        NodeExecutor
    end
    
    methods
        function obj = rosdevice(varargin)

            import ros.codertarget.internal.*
            initDeviceParameters(obj,varargin{:});
            
            % Create executors
            obj.SystemExecutor = createSystemExecutor(obj.DeviceAddress,...
                obj.Username,obj.Password,obj.Port);
            obj.CoreExecutor = createCoreExecutor(obj.DeviceAddress,...
                obj.SystemExecutor);
            obj.NodeExecutor = createNodeExecutor(obj.DeviceAddress,...
                obj.SystemExecutor,'ros');     
                        
            % Automatically set ROSFolder and CatkinWorkspace variables
            if isequal(obj.DeviceAddress,'localhost')
                obj.ROSFolder = obj.SystemExecutor.fullfile(matlabroot,...
                    'sys','ros1',computer('arch'),'ros1');
                obj.CatkinWorkspace = pwd;
            else
                % Derive ROS folder and CatkinWorkspace from deviceParams
                deviceParams = ros.codertarget.internal.DeviceParameters;
                obj.ROSFolder = deviceParams.getROSInstallFolder;
                obj.CatkinWorkspace = deviceParams.getCatkinWorkspace;
            end
        end
        
        function nodeList = get.AvailableNodes(obj)
            nodeList = getAvailableNodes(obj.NodeExecutor,getWorkspaceFolder(obj));
        end
        
        function set.ROSFolder(obj,rosFolder)
            validateattributes(rosFolder,{'char','string'},{'nonempty','row'},'','ROSFolder');
            rosFolder = convertStringsToChars(rosFolder);
            obj.ROSFolder = rosFolder;
        end
        
        function output = system(obj,varargin)
            output = system(obj.SystemExecutor,varargin{:});
        end
        
        function putFile(obj,varargin)
            putFile(obj.SystemExecutor,varargin{:})
        end
        
        function getFile(obj,varargin)
            getFile(obj.SystemExecutor,varargin{:});
        end
        
        function deleteFile(obj,varargin)
            deleteFile(obj.SystemExecutor,varargin{:});
        end
        
        function d = dir(obj,varargin)
            d = dir(obj.SystemExecutor,varargin{:});
        end
        
        function openShell(obj)
            openShell(obj.SystemExecutor);
        end
        
        function runCore(obj)
            runCore(obj.CoreExecutor,getROSFolder(obj),getWorkspaceFolder(obj));
        end
        
        function stopCore(obj)
            stopCore(obj.CoreExecutor);
        end
        
        function isRunning = isCoreRunning(obj)
            isRunning = isCoreRunning(obj.CoreExecutor);
        end
        
        function runNode(obj,modelName,rosMasterURI,nodeHost)
            narginchk(2, 4);
            
            % Parse inputs
            validateattributes(modelName, {'char','string'}, {'nonempty','row'}, 'runNode', 'modelName');
            modelName = convertStringsToChars(modelName);
            
            % If node is already running, don't do anything
            if obj.isNodeRunning(modelName)
                disp(message('ros:slros:rosdevice:NodeAlreadyRunning', modelName).getString);
                return;
            end
            
            if nargin < 3
                % Use default MasterURI
                rosMaster = ros.slros.internal.sim.ROSMaster;
                verifyReachable(rosMaster);
                rosMasterURI = rosMaster.MasterURI;
            else
                % Parse user input. The function displays an error if
                % the URI is not valid.
                rosMasterURI = ros.internal.Net.canonicalizeURI(rosMasterURI);
            end
            
            if nargin < 4
                nodeHost = '';
            else
                % Parse user input. The function displays an error if
                % the hostname or IP address is not valid.             
                if ~ros.internal.Net.isValidHost(nodeHost)
                    error(message('ros:mlros:util:HostnameInvalid',nodeHost));
                end
            end
            runNode(obj.NodeExecutor,modelName,...
                getWorkspaceFolder(obj),rosMasterURI,nodeHost);
        end
        
        function stopNode(obj,modelName)
            modelName = convertStringsToChars(modelName);
            stopNode(obj.NodeExecutor,modelName);
        end
        
        function isRunning = isNodeRunning(obj,modelName)
            validateattributes(modelName,{'char','string'},{'nonempty','row'},...
                'isNodeRunning','modelName');
            modelName = convertStringsToChars(modelName);
            isRunning = isNodeRunning(obj.NodeExecutor,modelName);
        end
    end
    
    methods (Access = protected)
        function ret = getWorkspaceFolder(obj)
            ret = expandFolder(obj.NodeExecutor,obj.CatkinWorkspace);
        end

        function ret = getROSFolder(obj)
            ret = expandFolder(obj.NodeExecutor,obj.ROSFolder);
        end
        
        function initDeviceParameters(obj,hostname,username,password,port)
            parser = ros.slros.internal.DeviceParameterParser;
            deviceParams = ros.codertarget.internal.DeviceParameters;
            
            % Parse the user input and initialize the object
            % Since all inputs are optional, parse them progressively.
            if nargin < 2
                hostname = deviceParams.getHostname;
                assert(~isempty(hostname),message('ros:slros:rosdevice:InvalidDeviceAddress'));
            else
                % Validate provided host name
                hostname = convertStringsToChars(hostname);
                parser.validateHostname(hostname,'rosdevice','hostname');
            end
            obj.DeviceAddress = hostname;
            
            if ~isequal(obj.DeviceAddress,'localhost')
                % Initialize the username
                if nargin < 3
                    username = deviceParams.getUsername;
                    assert(~isempty(username), message('ros:slros:rosdevice:InvalidUsername'));
                else
                    % Validate provided username
                    username = convertStringsToChars(username);
                    parser.validateUsername(username,'rosdevice','username');
                end
                obj.Username = username;

                % Initialize the password
                if nargin < 4
                    password = deviceParams.getPassword;
                    assert(~isempty(password),message('ros:slros:rosdevice:InvalidPassword'));
                else
                    % Validate provided password
                    password = convertStringsToChars(password);
                    parser.validatePassword(password,'rosdevice','password');
                end
                obj.Password = password;

                % Initialize the SSH port
                if nargin < 5
                    obj.Port = deviceParams.getSSHPort;
                else
                    % Validate provided SSH port
                    obj.Port = parser.validateSSHPort(port,'rosdevice','port');
                end
            end
        end
    end
end
