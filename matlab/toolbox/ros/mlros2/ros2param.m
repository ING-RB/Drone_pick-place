classdef ros2param < ros.internal.mixin.InternalAccess & ...
        robotics.core.internal.mixin.Unsaveable & handle
%ros2param Create an object to access ROS 2 parameters
%   Create a ros2param object and use its object functions to interact with
%   parameters associated with a specific node on the ROS 2 network. A
%   ros2param object can be creted regardless of the existence of the named
%   node. However, querying or modifying parameters on that node will only
%   be valid if the node is accessible.
%
%   PARAMOBJ = ROS2PARAM(NODENAME) returns a ros2param object PARAMOBJ which
%   you can use interact with parameters associated with the specific ROS 2
%   node, NODENAME. Specify NODENAME as a string.
%
%   PARAMOBJ = ROS2PARAM(___,Name,Value) provides additional options
%   specified by one or more Name,Value pair arguments. You can specify
%   several name-value pair arguments in any order as
%   Name1,Value1,...,NameN,ValueN:
%
%       "DomainID" - Network domain identification. By default, ros2param
%                    will look for specified node name from the domain
%                    specified by the environment variable 'ROS_DOMAIN_ID'.
%                    If this is not specified, it will look for the node
%                    from domain 0. However, one can use this name-value
%                    pair to specify a specific domain to look for. The
%                    acceptable values for the domain identification are
%                    between 0 and 232.
%
%   Once the ros2param object is created, clients for parameter interaction
%   will be present until the object is deleted.
%
%   The following ROS 2 data types are supported as values of parameters.
%   For each ROS 2 data type, the corresponding MATLAB data type is also
%   listed:
%   - 64-bit integers: MATLAB data type 'int64'
%   - booleans: MATLAB data type 'logical'
%   - strings: MATLAB data type 'char'
%   - doubles: MATLAB data type 'double'
%   - lists: MATLAB data type 'cell'
%   Note that elements in the same cell array can only contain the same
%   data type. For parameters within namespaces, you can declare using
%   MATLAB structure.
%
%
%   ros2param methods:
%       get     - Get ROS 2 parameter value
%       set     - Set ROS 2 parameter value
%       list    - List all ROS 2 parameter names
%       has     - Check if ROS 2 parameter name exists
%       search  - Search for ROS 2 parameter names
%
%
%   Example:
%       % Create a ros2node
%       params.double_param = 1.0;
%       params.my_namespace.int_param = int64(3);
%       node = ros2node("/testParameters","Parameters",params);
%
%       % Create a ros2param object associate with the above node
%       nodeParams = ros2param("/testParameters");
%
%       % Check existence of parameter
%       nameExists = has(nodeParams,"double_param");
%
%       % Get the doubleParam in node "/testParameters"
%       data = get(nodeParams,"double_param");
%
%       % Set the doubleParam in node "/testParameters"
%       set(nodeParams,"double_param",2.0);
%
%       % Get the int_param in node "/testParameters"
%       intValue = get(nodeParams, "my_namespace.int_param");

%   Copyright 2022 The MathWorks, Inc.

    properties (Transient, SetAccess = private)
        %GetParamClient - Service client to get parameter
        GetParamClient

        %SetParamClient - Service client to set parameter
        SetParamClient

        %ListParamClient - Service client to list parameters
        ListParamClient
    end

    properties (Constant, Access = ?ros.internal.mixin.InternalAccess)
        %NodeManager - Manage all ros2param objects
        NodeManager = ros.internal.ros2.ParameterNodeManager
    end

    properties (Hidden, Access = ?ros.internal.mixin.InternalAccess)
        %Node - ros2node that all service clients in this object attached to
        Node

        %RemoteNodeName - name of the remote node this object is accessing
        RemoteNodeName
    end

    methods
        function obj = ros2param(nodeName, varargin)
        %ros2param Create an object to access ROS 2 parameters
        %   Create a ros2param object to interact with parameters on
        %   specified node. Please see the class documentation (help
        %   ros2param) for more details.

        % Parse input arguments
            defaultID = ros.internal.utilities.getDefaultDomainID;
            p = inputParser;
            addRequired(p,'nodeName',...
                        @(x) validateattributes(x, ...
                                                {'char', 'string'}, ...
                                                {'nonempty', 'scalartext'}, ...
                                                'ros2param', ...
                                                'nodeName'));
            addParameter(p,'DomainID',defaultID, ...
                         @(x) validateattributes(x, ...
                                                 {'numeric'}, ...
                                                 {'scalar', 'integer', 'nonnegative', '<=', 232}, ...
                                                 'ros2param', ...
                                                 'DomainID'));
            parse(p,nodeName,varargin{:});
            domainID = p.Results.DomainID;

            % Register this ros2param in NodeManager
            obj.NodeManager.addNewParamObj(domainID);
            % Get the node from NodeManager
            obj.Node = obj.NodeManager.getNodeByDomainID(domainID);

            % Check whether the specified node exist in the current domain.
            % An object will be created no matter the specified node exist
            % or not. However, a warning will be thrown if it does not
            % exist.
            nodeName = convertStringsToChars(nodeName);
            % Add "/" before node name if not specify
            if ~isequal(nodeName(1),'/')
                nodeName = ['/' nodeName];
            end

            % Check whether the node name is registered with MATLAB
            nodesNamesMap = ros.ros2.internal.getMATLABROS2NodesMap;
            nodesNamesMapKey = sprintf('%s_%s_%s', nodeName, num2str(domainID), obj.Node.RMWImplementation);
            isExternalNode = false;
            % Persistent dictionary won't be configured with any keys and
            % values if there is an external node and no matlab node
            if ~isConfigured(nodesNamesMap) || ~isKey(nodesNamesMap, nodesNamesMapKey)
                % If the node is not creating using ros2node API, then
                % mark that node as external Node.
                isExternalNode = true;
            end

            % If the node name input is not part of MATLAB registered node,
            % then check if its part of introspection list.
            if isExternalNode && ~any(strcmp(ros2("node","list","DomainID",domainID),nodeName))
                warning(message('ros:mlros2:parameter:NodeDoesNotExist',nodeName,domainID));
            end
            obj.RemoteNodeName = nodeName;

            % As we are creating seperate node for managing the parameters
            % in MATLAB only, we can just check whether the node context is
            % valid and server is in good state by calling isValidNode method
            % instead of introspecting the list of nodes
            if ~isValidNode(obj.Node)
                error(message('ros:mlros2:parameter:NodeDoesNotExist',obj.Node.Name,domainID));
            end
            % Create service clients for this object
            obj.GetParamClient = ros2svcclient(obj.Node,[obj.RemoteNodeName '/get_parameters'],'rcl_interfaces/GetParameters');
            obj.SetParamClient = ros2svcclient(obj.Node,[obj.RemoteNodeName '/set_parameters'],'rcl_interfaces/SetParameters');
            obj.ListParamClient = ros2svcclient(obj.Node,[obj.RemoteNodeName '/list_parameters'],'rcl_interfaces/ListParameters');
        end

        function [data, status] = get(obj, paramName)
        %get Get parameter in the ROS 2 node associated with this object
        %   DATA = GET(OBJ,PNAME) returns the value of the input
        %   parameter if it exists in the associated ROS 2 node. An error
        %   will be displayed on MATLAB command window directly if it
        %   fails to get the parameter value.
        %
        %   [DATA,STATUS] = GET(OBJ,PNAME) returns both parameter
        %   value and status. If it successfully gets the parameter value,
        %   DATA will be the parameter value, and STATUS will be true.
        %   Otherwise, DATA will be an empty double, and STATUS will be
        %   false.
        %
        %   Example:
        %       % Create a ros2node
        %       params.double_param = 1.0;
        %       node = ros2node("/testParameters","Parameters",params);
        %
        %       % Create a ros2param object associate with the above node
        %       nodeParams = ros2param("/testParameters");
        %
        %       % Get the double_param in node "/testParameters"
        %       [data, status] = GET(nodeParams,"double_param");

            narginchk(2,2);
            % Validate the input argument
            paramName = robotics.internal.validation.validateString(paramName, true, 'get', 'paramName');

            % Initialize status as false
            status = false;

            % Create a request message
            request = ros2message(obj.GetParamClient);
            request.names = {paramName};

            % Service client will handle error messages if there is any.
            if ~isServerAvailable(obj.GetParamClient)
                if nargout > 1
                    data = [];
                    return;
                else
                    error(message('ros:mlros2:parameter:NodeDoesNotExist',obj.RemoteNodeName,obj.Node.ID));
                end
            end

            % Get value
            try
                response = call(obj.GetParamClient, request, 'Timeout', 10);
                name = retrieveFieldNameByIndex(response.values.type);
                data = response.values.(name);
                if ~isrow(data)
                    data = data';
                end
            catch ex
                if nargout > 1
                    data = [];
                    return;
                else
                    newEx = MException(message('ros:internal:transport:ParameterNotDeclared', ...
                                               paramName));
                    throw(newEx.addCause(ex));
                end
            end

            status = true;
        end

        function set(obj, paramName, paramValue)
        %set Set parameter value declared in the associated ROS 2 node
        %   SET(OBJ,PNAME,PVALUE) sets a value PVALUE for a parameter with
        %   name PNAME in the associated ROS 2 node. PVALUE can be any of
        %   the following data types: int64, double, logical, character
        %   array, string, byte array (uint8), int64 array, double array,
        %   logical array, and cell of string.
        %
        %   Example:
        %       % Create a node with parameters
        %       params.my_int = int64(3);
        %       params.my_double_array = {1.0 2.0 3.0};
        %       params.my_string = "MathWorks";
        %       node = ros2node("/testParameters","Parameters",params);
        %
        %       % Create ros2param object and set a parameter
        %       nodeParams = ros2param("/testParameters");
        %       SET(nodeParams,"my_int",int64(5));
        %       SET(nodeParams,"my_double_array",[5.0 6.0 7.0]);
        %       SET(nodeParams,"my_string","ROS2");

            narginchk(3,3);
            % Validate the input argument
            % Parameter name cannot be empty, otherwise it may terminate
            % the remote node.
            paramName = robotics.internal.validation.validateString(paramName, false, 'set', 'paramName');

            % Parse parameter value
            if iscell(paramValue)
                % Validate cell input
                firstElementType = class(paramValue{1});
                for elementIndex = 1:numel(paramValue)
                    isHomogeneousInType = strcmp(class(paramValue{elementIndex}), firstElementType);
                    if ~isHomogeneousInType
                        coder.internal.assert(false, 'ros:mlros2:codegen:CellArrayElementDataTypesMismatch');
                    end
                    checkDataType(paramValue{elementIndex});
                end

                if ischar(paramValue{1}) || isstring(paramValue{1})
                    % Cell array of string/character array
                    paramValue = cellfun(@(x) convertStringsToChars(x), paramValue, 'UniformOutput', false);
                    valueType = uint8(9);
                    msgFieldName = 'string_array_value';
                else
                    % Cell array of numerical value or logical value
                    % Convert to numerical array
                    paramValue = cell2mat(paramValue);
                    [valueType, msgFieldName] = retrieveTypeAndFieldFromValue(paramValue);
                end
            else
                validateattributes(paramValue,{'int64','double','logical','uint8','char','string'},{'vector'},'set','paramValue');
                if isstring(paramValue)
                    if numel(paramValue)<2
                        paramValue = convertStringsToChars(paramValue);
                    else
                        % Convert from string array to cell array
                        paramValue = cellstr(paramValue);
                    end
                end
                [valueType, msgFieldName] = retrieveTypeAndFieldFromValue(paramValue);
            end

            % Create a request message
            request = ros2message(obj.SetParamClient);
            request.parameters.name = paramName;
            request.parameters.value.type = valueType;
            request.parameters.value.(msgFieldName) = paramValue;

            % Service client will handle error messages if there is any.
            if ~isServerAvailable(obj.SetParamClient)
                error(message('ros:mlros2:parameter:NodeDoesNotExist',obj.RemoteNodeName,obj.Node.ID));
            end

            % Set value
            try
                response = call(obj.SetParamClient, request, 'Timeout', 10);
            catch ex
                newEx = MException(message('ros:mlros2:parameter:ParamServerTimeout', ...
                                           'set'));
                throw(newEx.addCause(ex));
            end


            % Directly port error log from ROS 2 console to MATLAB error
            % message if it failed to set the parameter.
            if ~response.results.successful
                errorLog = response.results.reason;
                error(message('ros:mlros2:parameter:FailedToSetParam', errorLog));
            end
        end

        function paramList = list(obj)
        %list List out all parameters in the associated node
        %   PARAMLIST = LIST(OBJ) returns a cell array of parameter names
        %   in the associated node.
        %
        %   Example:
        %       % Create a node with parameters
        %       params.my_int = int64(3);
        %       params.my_double_array = {1.0 2.0 3.0};
        %       params.my_string = "MathWorks";
        %       node = ros2node("/testParameters","Parameters",params);
        %
        %       % Create ros2param object and list out parameters
        %       nodeParams = ros2param("/testParameters");
        %       paramList = LIST(nodeParams);

            narginchk(1,1);

            % Create a request message
            request = ros2message(obj.ListParamClient);
            % Remove the line below after addressing g2678068
            request.prefixes = {};

            % Service client will handle error messages if there is any.
            if ~isServerAvailable(obj.ListParamClient)
                error(message('ros:mlros2:parameter:NodeDoesNotExist',obj.RemoteNodeName,obj.Node.ID));
            end

            % Get the list of parameters
            try
                response = call(obj.ListParamClient, request, 'Timeout', 10);
            catch ex
                newEx = MException(message('ros:mlros2:parameter:ParamServerTimeout', ...
                                           'list'));
                throw(newEx.addCause(ex));
            end
            paramList = response.result.names;
        end

        function exists = has(obj, paramName)
        %has Check to see if given parameter name exists
        %   EXISTS = HAS(OBJ,PNAME) checks if the parameter with name
        %   PNAME exists in the node associated with this object OBJ.
        %   EXISTS is a logical "true" if the parameter exists, or "false"
        %   otherwise. This function is case sensitive.
        %
        %   Example:
        %       % Create a node with parameters
        %       params.my_int = int64(3);
        %       params.my_double_array = {1.0 2.0 3.0};
        %       params.my_string = "MathWorks";
        %       node = ros2node("/testParameters","Parameters",params);
        %
        %       % Create ros2param object and check parameter existence
        %       nodeParams = ros2param("/testParameters");
        %       HAS(nodeParams,"my_string");

            narginchk(2,2);
            % Validate input arguments, allows empty string
            paramName = robotics.internal.validation.validateString(paramName, true, 'has', 'paramName');

            % Get a list of all parameters
            paramList = list(obj);
            exists = any(strcmp(paramList,paramName));
        end

        function [pnames, pvalues] = search(obj, paramName)
        %search Search for parameter names
        %   [PNAMES,PVALUES] = SEARCH(OBJ,PNAMESTR) searches within the
        %   node associated with this object OBJ for parameter names that
        %   contains the string PNAMESTR. It returns the matching parameter
        %   names in PNAMES as a cell array of strings. Optionally, you can
        %   retrieve the values of these parameters in PVALUES. PVALUES is
        %   a cell array with the same length as PNAMES.
        %
        %   Example:
        %       % Create a node with parameters
        %       params.my_int = int64(3);
        %       params.my_double_array = {1.0 2.0 3.0};
        %       params.my_string = "MathWorks";
        %       node = ros2node("/testParameters","Parameters",params);
        %
        %       % Create ros2param object and seach for parameter containing "my"
        %       nodeParams = ros2param("/testParameters");
        %       [pnames,pvalues] = SEARCH(nodeParams,"my");

            narginchk(2,2);
            % Validate input arguments, allows empty string
            paramName = robotics.internal.validation.validateString(paramName, true, 'search', 'paramName');

            % Get a list of all parameters
            paramList = list(obj);

            % Return empty if parameter list is empty
            if isempty(paramList)
                pnames = {};
                pvalues = {};
                return;
            end

            % If input is empty, return all parameters
            if isempty(paramName)
                pnames = paramList;
            else
                % Find matching string and return the matching parameter
                % list
                matchIdx = contains(lower(paramList),lower(paramName));
                pnames = paramList(matchIdx);
            end

            % Retrieve values if requested by the user
            if nargout == 2
                pvalues = cell(numel(pnames),1);
                for i=1:numel(pnames)
                    pvalues{i,1} = get(obj,pnames{i});
                end
            end
        end

        function delete(obj)
        %delete delete this object
        % Remove object from NodeManager
            obj.NodeManager.removeParamObj;
        end
    end
end

% Helper functions
function name = retrieveFieldNameByIndex(index)
%retrieveFieldNameByIndex Retrieve field name corresponding to index
%   This function will be used to determine which field to look at in
%   response message.

    allFieldNames = cellstr(["","bool_value","integer_value", ...
                             "double_value","string_value","byte_array_value", ...
                             "bool_array_value","integer_array_value", ...
                             "double_array_value","string_array_value"]);
    name = allFieldNames{1,index+1};
end

function [type, name] = retrieveTypeAndFieldFromValue(value)
%retrieveTypeAndFieldFromValue Retrieve message fields from a parameter value
%   This function will be used to determine which field to assign the
%   parameter value and which type to be specified in the message.

    if ischar(value)
        type = uint8(4);
        name = 'string_value';
        return;
    end

    if iscell(value)
        % Cell of string, this is specifically for input of string array
        type = uint8(9);
        name = 'string_array_value';
        return;
    end

    if length(value) > 1
        if islogical(value)
            type = uint8(6);
            name = 'bool_array_value';
        elseif isa(value,'int64')
            type = uint8(7);
            name = 'integer_array_value';
        elseif isa(value,'double')
            type = uint8(8);
            name = 'double_array_value';
        else
            % This has to be uint8 array
            type = uint8(5);
            name = 'byte_array_value';
        end
    else
        if islogical(value)
            type = uint8(1);
            name = 'bool_value';
        elseif isinteger(value)
            type = uint8(2);
            name = 'integer_value';
        elseif isa(value,'double')
            type = uint8(3);
            name = 'double_value';
        else
            % This has to be uint8 array
            type = uint8(5);
            name = 'byte_array_value';
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
