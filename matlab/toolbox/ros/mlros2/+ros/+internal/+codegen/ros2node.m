classdef ros2node < ros.internal.mixin.InternalAccess & ...
        coder.ExternalDependency
%ros2node Initialize ROS 2 node on specified network
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
%   Node properties:
%      Name         - (Read-only) Name of the node
%      ID           - (Read-only) Network domain identification
%
%   Node methods:
%      resolveName  - Check and resolve ROS 2 name
%
%   Example:
%      % Initialize the node "/node_1" on the default network
%      node1 = ros2node("/node_1");
%
%      % Create a separate node that connects to a different network
%      % identified with domain 2
%      node2 = ros2node("/node_2",2);

%   Copyright 2021-2022 The MathWorks, Inc.
%#codegen
    properties (SetAccess = private)
        %Name - Name of the node
        %   This needs to be unique in the ROS 2 network
        Name

        %ID - Domain identification of the network
        %   Default: 0
        ID

        %Parameters - Parameters to be declared during node creation
        Parameters
    end

    properties (SetAccess = private, GetAccess = ?ros.internal.mixin.InternalAccess)
        %NodeHandle - Opaque variable representing C++ node handle
        NodeHandle

        %Namespace - Namespace of the node
        Namespace
    end

    methods
        function obj = ros2node(name,varargin)
        %ros2node Create a ROS 2 node object
        %   The "name" argument is required and specifies a node name to be
        %   used on the ROS 2 network.
            coder.extrinsic('ros.codertarget.internal.locAddNode')
            coder.extrinsic('ros.codertarget.internal.nodeParameterParser')
            coder.extrinsic('ros.codertarget.internal.writeParamToCodegenInfo')
            coder.internal.prefer_const(name); % Specialize ros2node class based on name

            % Parse and assign inputs
            narginchk(1, inf)
            parseInputs(obj,name,varargin{:});

            % Check and verify we have a single node defined
            coder.const(@ros.codertarget.internal.locAddNode,obj.Name); % Check multiple nodes in onAfterCodegen

            % Register node parameters
            if ~(isfield(obj.Parameters,'mlEmptyStruct') && isempty(obj.Parameters.mlEmptyStruct))
                startIndex = 1;
                if isnumeric(varargin{1})
                    startIndex = 2;
                end
                formattedParameters = coder.const(@ros.codertarget.internal.nodeParameterParser, varargin{startIndex:end});
                coder.const(@ros.codertarget.internal.writeParamToCodegenInfo, formattedParameters);
            end

            % Create NodeHandle which is an opaque variable representing
            % global node handle. This variable should be passed to
            % coder.ceval.
            obj.NodeHandle = coder.opaque('rclcpp::Node::SharedPtr','HeaderFile','mlros2_node.h');
            obj.NodeHandle = coder.ceval('MATLAB::getGlobalNodeHandle');
            coder.ceval('UNUSED_PARAM',obj.NodeHandle);
        end

        function [paramValue, status] = getParameter(~, paramName, varargin)
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

            coder.cinclude("mlros2_node.h");
            % Parse and assign inputs
            narginchk(2,4);
            % Validate the input argument
            paramName = robotics.internal.validation.validateString(paramName, false, 'getParameter', 'name');
            paramNameC = cString(paramName);

            coder.internal.prefer_const(varargin{:});
            opArgs = {};
            NVPairNames = {'DataType'};
            % Select parsing options
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            % Parse the inputs
            pStruct = coder.internal.parseInputs(opArgs, NVPairNames, pOpts, varargin{:});
            % Retrive name-value pairs
            mlDataType = coder.internal.getParameterValue(pStruct.DataType,'',varargin{:});
            coder.internal.assert(~isempty(mlDataType),'ros:mlros2:parameter:MissingDataType','getParameter');
            validatestring(mlDataType, {'int64', 'double',...
                                        'logical','char','string'},'getParameter','DataType',4);

            % Initialize status
            status = false;

            % Get data from node
            if strcmpi(mlDataType, 'string') || strcmpi(mlDataType, 'char')
                outDataLength = uint32(0);
                outDataLength = coder.ceval('MATLAB::getStringParameterLength',paramNameC);
                outData = char(zeros(1,outDataLength));
                status = coder.ceval('MATLAB::getStringParameter', ...
                                     paramNameC, coder.wref(outData));
            else
                [cppType, outData] = coder.const(@mapToCppType, mlDataType);
                outData = coder.ceval(['MATLAB::getParameter<' cppType '>'], ...
                                      paramNameC, coder.wref(status));
            end

            statusIndicator = ~status;
            if ~statusIndicator && nargout<2
                coder.internal.error('ros:mlros2:parameter:FailedToGetParam',paramName);
            end
            paramValue = outData;
        end

        function setParameter(~, paramName, paramValue)
        %setParameter Set parameter declared in the ROS 2 node
        %   setParameter(nodeObj,paramName,paramValue) set the value paramValue
        %   for declared parameter named paramName in the ros2node object, nodeObj.
        %   If such parameter does not exist in the ROS 2 node, an error message
        %   will be thrown.

            coder.cinclude("mlros2_node.h");
            narginchk(3,3);
            % Validate the input argument
            paramName = robotics.internal.validation.validateString(paramName, true, 'setParameter', 'paramName');
            paramNameC = cString(paramName);

            validateattributes(paramValue, {'logical','uint8','int64','double','char','string','cell','struct'},...
                               {},'setParameter','paramValue');

            if isnumeric(paramValue) || islogical(paramValue)
                % Set scalar numeric or logical value
                validateattributes(paramValue,{'logical','uint8','int64','double'},...
                                   {'nonempty','scalar'},'setParameter','paramValue');
                cppType = coder.const(mapToCppType(class(paramValue)));
                if strcmp(cppType, 'int64_T')
                    coder.ceval('MATLAB::setIntParameter', ...
                                paramNameC, paramValue);
                else
                    coder.ceval(['MATLAB::setParameter<' cppType '>'], ...
                                paramNameC, paramValue);
                end
            elseif ischar(paramValue) || isstring(paramValue)
                % Set a string
                paramValueChar = robotics.internal.validation.validateString(paramValue, true, 'setParameter', 'paramValue');
                % Legal characters are tab, carriage return, line feed, and the legal characters of Unicode and ISO/IEC 10646.
                %
                % Char ::= 0x9 | 0xA | 0xD | [0x20-0xD7FF] | [0xE000-0xFFFD] | [0x10000-0x10FFFF]
                % [0x10000-0x10FFFF] are out of range of MATLAB char which
                % is uint16
                for k = 1:numel(paramValueChar)
                    c = paramValueChar(k);
                    % Must be in range [0x9, 0xA, 0xD] | [0x20 - 0xD7FF] [0xE000 - 0xFFFD]
                    if ~( ((c == 0x9) || (c == 0xA) || (c == 0xD)) ...
                          || ((c >= 0x20) && (c <= 0xD7FF)) ...
                          || ((c >= 0xE000) && (c <= 0xFFFD)) )
                        coder.internal.assert(false, 'ros:mlros:param:SetStringParamError',paramName,k);
                    end
                end
                paramValueCharC = cString(paramValueChar);
                cppType = coder.const(mapToCppType(class(paramValueChar)));
                coder.ceval(['MATLAB::setParameter<' cppType '*>'], ...
                            paramNameC, paramValueCharC);
            elseif iscell(paramValue)
                % Recursive validation of each element
                validateCellInput(paramValue);

                mlDataType = class(paramValue{1});
                if ischar(paramValue{1}) || isstring(paramValue{1})
                    coder.cinclude("<string>");
                    arrSize = uint32(numel(paramValue));

                    for strIndex = 1:arrSize
                        paramValueCharForm = convertStringsToChars(paramValue{strIndex});
                        [nRows,nCols] = size(paramValueCharForm);
                        formattedParamValue = cast(zeros([nRows nCols+1]), 'char');
                        coder.varsize('formattedParamValue');
                        strLen = numel(paramValueCharForm);
                        for charIndex = 1:strLen
                            formattedParamValue(charIndex) = paramValueCharForm(charIndex);
                        end
                        coder.ceval('-layout:rowMajor','MATLAB::setStringValues', formattedParamValue);
                    end
                    coder.ceval('-layout:rowMajor','MATLAB::setStringArrayParameter', paramNameC);
                elseif isequal(mlDataType, 'uint8')
                    arrSize = uint32(numel(paramValue));
                    for uIndex = 1:arrSize
                        coder.ceval('-layout:rowMajor','MATLAB::setUint8Values', paramValue{uIndex});
                    end
                    coder.ceval('-layout:rowMajor','MATLAB::setUint8ArrayParameter', paramNameC);
                else
                    cppType = coder.const(mapToCppType(mlDataType));
                    formattedParamValue = cast(zeros(size(paramValue)), mlDataType);
                    arrSize = uint32(numel(paramValue));
                    for arrIndex = 1:numel(paramValue)
                        formattedParamValue(arrIndex) = paramValue{arrIndex};
                    end
                    if strcmp(cppType, 'int64_T')
                        coder.ceval('-layout:rowMajor','MATLAB::setIntArrayParameter', ...
                                    paramNameC, formattedParamValue, arrSize);
                    else
                        coder.ceval('-layout:rowMajor',['MATLAB::setArrayParameter<' cppType '>'], ...
                                    paramNameC, formattedParamValue, arrSize);
                    end
                end
            elseif isstruct(paramValue)
                % Setting struct fields of parameter is not supported in
                % codegen
                coder.internal.assert(false, 'ros:mlros2:codegen:UnsupportedDataElementStruct', 'setParameter', 'struct');
            end
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
                rosName = [obj.Namespace, '/', name];
            end
        end

        function parseInputs(obj,name,varargin)
            coder.extrinsic('ros.internal.utilities.getDefaultDomainID')
            % Validate & set obj.Name
            name = convertStringsToChars(name);
            validateattributes(name,{'char'},{'nonempty','scalartext'}, ...
                               'ros2node','name');
            obj.Name = name;

            % Validate and set obj.ID as well as obj.Parameters
            % Domain IDs are typically between 0 and 232
            opArgs = {'id'};
            NVPairNames = {'Parameters'};
            % Select parsing options
            pOpts = struct( ...
                'CaseSensitivity', false, ...
                'PartialMatching', 'unique', ...
                'StructExpand', false, ...
                'IgnoreNulls', true, ...
                'SupportOverrides', false);
            pStruct = coder.internal.parseInputs(opArgs,NVPairNames,pOpts,varargin{:});
            defaultDomainID = coder.const(ros.internal.utilities.getDefaultDomainID);
            id = coder.internal.getParameterValue(pStruct.id, defaultDomainID, varargin{:});
            validateattributes(id, {'numeric'}, ...
                               {'scalar','integer','nonnegative','<=', 232}, ...
                               'ros2node','id');
            obj.ID = id;
            defaultEmptyStruct.mlEmptyStruct = [];
            parameters = coder.internal.getParameterValue(pStruct.Parameters,defaultEmptyStruct,varargin{:});
            validateattributes(parameters, {'struct'}, ...
                               {'scalar'}, 'ros2node', 'Parameters');
            obj.Parameters = parameters;

            % Set namespace
            obj.Namespace = loc_getNodeNamespace(obj.Name);
        end
    end

    methods (Static)
        function props = matlabCodegenNontunableProperties(~)
            props = {'Name','ID'};
        end

        function ret = getDescriptiveName(~)
            ret = 'ROS 2 Node';
        end

        function ret = isSupportedContext(ctx)
            ret = ctx.isCodeGenTarget('rtw');
        end

        function updateBuildInfo(buildInfo,ctx)
            if ctx.isCodeGenTarget('rtw')
                srcFolder = fullfile(toolboxdir('ros'),'codertarget','src');
                addIncludeFiles(buildInfo,'mlros2_node.h',srcFolder);
            end
        end
    end
end

% Helper functions
function namespace = loc_getNodeNamespace(name)
% Extract namespace as last text block separated by slash
    for k = length(name):-1:1
        if name(k) == '/'
            break;
        end
    end
    namespace = name(1:k-1);
end

function [cppDataType, defaultInitialValue] = mapToCppType(mlDataType)
%mapToCppType Return corresponding cpp data type and default value given MATLAB type

    switch(coder.const(mlDataType))
      case 'logical'
        cppDataType = coder.internal.const('bool');
        defaultInitialValue = false;
      case 'uint8'
        cppDataType = coder.internal.const('unsigned char');
        defaultInitialValue = uint8(0);
      case 'int64'
        cppDataType = coder.internal.const('int64_T');
        defaultInitialValue = int64(0);
      case 'double'
        cppDataType = coder.internal.const('double');
        defaultInitialValue = double(0);
      case 'char'
        cppDataType = coder.internal.const('char');
        defaultInitialValue = '';
      case 'string'
        cppDataType = coder.internal.const('char*');
        defaultInitialValue = char(zeros(1,256));
      otherwise
        coder.internal.assert(false, 'ros:mlros2:codegen:UnsupportedDataType',mlDataType);
    end
end

% Put a C termination character '\0' at the end of MATLAB character vector
function out = cString(in)
    out = [in char(0)];
end

function validateCellInput(cellArray)
%validateCellInput Validate elements of cell
%   This funcrtion is used for recursively validating every element
%   of the input cell array. The elements of the cell array need to
%   be to same type and can only be 'int64', 'uint8', 'double',
%   'logical', 'char', 'string'.

    if ~isempty(cellArray)
        % Validate if cell array is a vector (row or column)
        validateattributes(cellArray, {'cell'}, {'vector'}, 'setParameter', 'paramValue');

        % Check data type for every element
        firstElementType = class(cellArray{1});
        for elementIndex = 1:numel(cellArray)
            isHomogeneousInType = strcmp(class(cellArray{elementIndex}), firstElementType);
            if ~isHomogeneousInType
                coder.internal.assert(false, 'ros:mlros2:codegen:CellArrayElementDataTypesMismatch');
            end
            checkDataType(cellArray{elementIndex});
        end
    end
end

function checkDataType(inputData)
%checkDataType Check data type
%   This function is used for recursively checking the input
%   data type for each element of the cell array

% If cell array, then call this function recursively
    if iscell(inputData)
        coder.internal.assert(false, 'ros:mlros2:codegen:UnsupportedDataElementCell');
    end

    if isstruct(inputData)
        coder.internal.assert(false, 'ros:mlros2:codegen:UnsupportedDataElementStruct', 'setParameter', 'struct');
    end

    if isnumeric(inputData)
        % Check if numeric data is scalar
        validateattributes(inputData,{'numeric'},{'scalar'},2)
    end

    % Check if data belongs to supported types
    validateattributes(inputData,{'int64','uint8', 'double',...
                                  'logical','char','string'},{},2)
end
% LocalWords:  ROSNAME
