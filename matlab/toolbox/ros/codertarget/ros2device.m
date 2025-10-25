classdef ros2device < robotics.core.internal.mixin.Unsaveable & ...
        ros.codertarget.internal.ROS2DeviceInterface
    %ROS2DEVICE Connect to a ROS 2 device
    
    %   Copyright 2020-2023 The MathWorks, Inc.   
    properties (SetAccess = private)
        %DeviceAddress - Hostname or IP address of the Remote device
        %   For example, this can be an IP address or a hostname.
        DeviceAddress
    end
    
    properties (SetAccess = private)
        %Username - Username used to connect to the device
        Username
    end
    
    properties (Dependent, SetAccess = private)
        %AvailableNodes - Nodes that are available to run
        %   This list captures deployed Simulink nodes in the ROS or ROS 2
        %   workspace that are available to run.
        AvailableNodes
    end
    
    properties (Access = {?matlab.unittest.TestCase})
        %Port - SSH port used to connect to the Remote device
        %   Default: 22
        Port = 22
        
        %Password - Password used to connect to the Remote device
        Password
        
        %Parser - Parser object for user inputs
        Parser
        
        %Diagnostic - Diagnostic helper object
        Diagnostic
    end
    
    properties
        %ROS2Folder - Folder where ROS 2 is installed
        %   This is a folder name on the ROS 2 device. By default, this is
        %   initialized from the stored settings.
        ROS2Folder

        %ROS2Workspace - ROS 2 project folder where models are deployed
        %   This is a folder name on the ROS device. By default, this
        %   is initialized from the stored settings.
        ROS2Workspace
    end    
    
    properties (Access = ?ros.slros.internal.InternalAccess)
        SystemExecutor
        NodeExecutor
    end
    
    methods
        function obj = ros2device(varargin)
            %ROSDEVICE Construct an instance of this class

            import ros.codertarget.internal.*
            initDeviceParameters(obj,varargin{:});
            
            % Create executors
            obj.SystemExecutor = createSystemExecutor(obj.DeviceAddress,...
                obj.Username,obj.Password,obj.Port);
            obj.NodeExecutor = createNodeExecutor(obj.DeviceAddress,...
                obj.SystemExecutor,'ros2');
                        
            % Automatically set ROS2Folder and ROS2Workspace variables
            if strcmpi(obj.DeviceAddress,'localhost')
                obj.ROS2Folder = obj.SystemExecutor.fullfile(matlabroot,...
                    'sys','ros2',computer('arch'),'ros2');
                obj.ROS2Workspace = pwd;
            else
                % Derive ROS2Folder and ROS2Workspace from deviceParams
                deviceParams = ros.codertarget.internal.DeviceParameters;
                obj.ROS2Folder = deviceParams.getROS2InstallFolder;
                obj.ROS2Workspace = deviceParams.getROS2Workspace;
            end
        end
        
        %% Getter and setter methods
        function nodeList = get.AvailableNodes(obj)
            % Return list of available nodes
            nodeList = getAvailableNodes(obj.NodeExecutor,getWorkspaceFolder(obj));
        end
        
        function set.ROS2Folder(obj,rosFolder)
            % This class is unsaveable. Hence accessing another property
            % in the set function of ROSFolder is ok
            validateattributes(rosFolder,{'char','string'},{'nonempty','row'},'','ROS2Folder');
            rosFolder = convertStringsToChars(rosFolder);
            obj.ROS2Folder = rosFolder;
        end
        
        %% Implement system calls through system executor
        function output = system(obj,varargin) %command,sudo)
            %SYSTEM execute command on device and return output
            output = system(obj.SystemExecutor,varargin{:});
        end
        
        function putFile(obj,varargin)
            % PUTFILE Copy localFile on the host computer to the remoteFile
            % on device
            %
            % The remoteFile argument is optional. If not specified, the
            % localFile is copied to the user's home directory.
            %
            % See also dir, getFile and putFile.
            putFile(obj.SystemExecutor,varargin{:})
        end
        
        function getFile(obj,varargin)
            % GETFILE Copy remoteFile on device to the localFile on the
            % host computer
            getFile(obj.SystemExecutor,varargin{:});
        end
        
        function deleteFile(obj,varargin)
            % DELETEFILE Delete file on device
            deleteFile(obj.SystemExecutor,varargin{:});
        end
        
        function d = dir(obj,varargin)
            %DIR List contents of a directory
            d = dir(obj.SystemExecutor,varargin{:});
        end
        
        function openShell(obj)
            %OPENSHELL Open a command terminal
            openShell(obj.SystemExecutor);
        end
        
        %% Use node executor to implement node interface
        function runNode(obj,modelName)
            %runNode Start the node on device
            %   runNode(DEVICE, MODELNAME) starts the ROS 2 node associated
            %   with the Simulink model with name MODELNAME on the connected
            %   DEVICE. The node needs to be deployed in the project workspace
            %   folder specified in the workspace property. The node connects
            %   to the same ROS master that MATLAB is connected to and advertises
            %   its address as the property value 'DeviceAddress'.
            %
            %
            %   Example:
            %       device = ros2device
            %
            %       % Run the 'robotROSFeedbackControlExample' node
            %       % This model needs to be deployed to the ROS device
            %       runNode(device, 'robotROSFeedbackControlExample')
            %
            %       % Stop the node
            %       stopNode(device, 'robotROSFeedbackControlExample')
            %
            %   See also stopNode.
            narginchk(2, 4);
            
            % Parse inputs
            validateattributes(modelName, {'char','string'}, {'nonempty','row'}, 'runNode', 'modelName');
            modelName = convertStringsToChars(modelName);
            
            % If node is already running, don't do anything
            if obj.isNodeRunning(modelName)
                disp(message('ros:slros:rosdevice:NodeAlreadyRunning', modelName).getString);
                return;
            end
            % Send empty string for rosMasterURI and nodeHost arguments
            runNode(obj.NodeExecutor,modelName,getWorkspaceFolder(obj),'','');
        end
        
        function stopNode(obj,modelName)
            %stopNode Stop the node on device
            %   stopNode(DEVICE, MODELNAME) stops the node associated
            %   with the Simulink model with name MODELNAME on the connected
            %   DEVICE.
            %
            %   If the node is not running, this function returns right
            %   away.
            %
            %
            %   Example:
            %       device = ros2device
            %
            %       % Run the 'exampleModel' node
            %       % This model needs to be deployed to the ROS device.
            %       runNode(device, 'exampleModel')
            %
            %       % Stop the node
            %       stopNode(device, 'exampleModel')
            %
            %       % Calling stop again has no effect
            %       stopNode(device, 'exampleModel')
            %
            %   See also runNode.
            modelName = convertStringsToChars(modelName);
            stopNode(obj.NodeExecutor,modelName);
        end
        
        function isRunning = isNodeRunning(obj,modelName)
            %isNodeRunning Determine if ROS 2 node is running on device
            %   ISRUNNING = isNodeRunning(DEVICE, MODELNAME) returns TRUE
            %   if the ROS 2 node associated with the Simulink model with
            %   name MODELNAME is running on the DEVICE.
            %   The function returns FALSE if the node is not
            %   running on the device.
            %
            % Se also runNode, stopNode.
            validateattributes(modelName,{'char','string'},{'nonempty','row'},...
                'isNodeRunning','modelName');
            modelName = convertStringsToChars(modelName);
            isRunning = isNodeRunning(obj.NodeExecutor,modelName);
        end
    end
    
    methods (Access = protected)
        function ret = getWorkspaceFolder(obj)
            ret = expandFolder(obj.NodeExecutor,obj.ROS2Workspace);
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
