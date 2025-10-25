function nodeParameters = nodeParameterParser(varargin)
%This function is for internal use only. It may be removed in the future.

%nodeParameterParser parse parameter structure for ROS 2 node.
% This function returns a structure with Name and Value fields for MATLAB
% and Simulink code generation template.

%   Copyright 2022 The MathWorks, Inc.

% Parse input arguments
    opArgs = {};
    NVPairNames = {'Parameters'};
    % Select parsing options
    pOpts = struct( ...
        'CaseSensitivity', false, ...
        'PartialMatching', 'unique', ...
        'StructExpand', false, ...
        'IgnoreNulls', true, ...
        'SupportOverrides', false);
    pStruct = coder.internal.parseInputs(opArgs,NVPairNames,pOpts,varargin{:});
    defaultEmptyStruct.mlEmptyStruct = [];
    parameters = coder.internal.getParameterValue(pStruct.Parameters,defaultEmptyStruct,varargin{:});

    % Initialize output argument as an empty structure with fields
    nodeParameters = struct('Name','','Value','');
    % Recursively parse parameter structure
    nodeParameters = recursiveParameterExtraction('',parameters, nodeParameters);
end

function paramValueSubString = processCellArray(inputCellArray)
% Parse cell array and return a C++ syntax for parameter value
    typeStr = class(inputCellArray{1,1});

    if isequal(typeStr, 'string')
        % cell of string: {"ABC" "DEF"} --> 'std::vector<std::string>{"ABC", "DEF"}'
        typeStr = 'std::string';
        memCharSet = ['"' convertStringsToChars(inputCellArray{1,1}) '"'];
        cellLength = length(inputCellArray);
        if cellLength>1
            for k = 2:cellLength
                memCharSet = [memCharSet ', "' convertStringsToChars(inputCellArray{1,k}) '"']; %#ok<AGROW>
            end
        end
    elseif isequal(typeStr, 'char')
        % cell of char: {'ABC' 'DEF'} --> 'std::vector<std::string>{"ABC", "DEF"}'
        typeStr = 'std::string';
        memCharSet = ['"' inputCellArray{1,1} '"'];
        cellLength = length(inputCellArray);
        if cellLength>1
            for k = 2:cellLength
                memCharSet = [memCharSet ', "' inputCellArray{1,k} '"']; %#ok<AGROW>
            end
        end
    else
        % Cell array of numerical members
        if isequal(typeStr, 'int64')
            % cell of int64: {1 2 3} --> 'std::vector<int64_t>{1, 2, 3}'
            typeStr = 'int64_t';
        elseif isequal(typeStr, 'logical')
            % cell of logical: {true false} --> 'std::vector<bool>{true, false}'
            typeStr = 'bool';
        elseif isequal(typeStr, 'uint8')
            % cell of uint8: {1 2 3} --> 'std::vector<unsigned char>{1,2,3}'
            typeStr = 'unsigned char';
        else
            % cell of double: {1.0 2.0 3.0} --> 'std::vector<double>{1.0, 2.0, 3.0}'
        end

        if isequal(typeStr, 'double')
            memCharSet = sprintf('%f',inputCellArray{1,1});
            cellLength = length(inputCellArray);
            if cellLength>1
                for k = 2:cellLength
                    memCharSet = [memCharSet ', ' sprintf('%f',inputCellArray{1,k})]; %#ok<AGROW>
                end
            end
        else
            memCharSet = sprintf('%d',inputCellArray{1,1});
            cellLength = length(inputCellArray);
            if cellLength>1
                for k = 2:cellLength
                    memCharSet = [memCharSet ', ' sprintf('%d',inputCellArray{1,k})]; %#ok<AGROW>
                end
            end
        end

    end

    % Combine pieces to generate sub string for parameter value
    paramValueSubString = [typeStr '>{' memCharSet '}'];
end


function nodeParameters = recursiveParameterExtraction(baseString, ParamStruct, nodeParameters)
    validateattributes(ParamStruct,{'struct'},{'scalar'},'ros2node','Parameters');
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
            nodeParameters = recursiveParameterExtraction(newStr, nextLayer, nodeParameters);
        else
            % nextLayer is the actual value if it is not a structure,
            % newStr is the parameter name including namespaces.
            prefixString = 'std::vector<';

            if isstring(nextLayer)
                if length(nextLayer)==1
                    % Syntax: string: "ABC" --> '"ABC"'
                    paramValueChar = ['"' convertStringsToChars(nextLayer) '"'];
                else
                    % Syntax: string array: ["ABC" "DEF"] -->
                    % 'std::vector<std::string>{"ABC", "DEF"}'
                    memCharSet = ['"' convertStringsToChars(nextLayer(1)) '"'];
                    for k = 2:length(nextLayer)
                        memCharSet = [memCharSet ', "' convertStringsToChars(nextLayer(k)) '"']; %#ok<AGROW>
                    end
                    paramValueChar = [prefixString 'std::string>{' memCharSet '}'];
                end
            elseif iscell(nextLayer)
                % Syntax:
                % cell of string: {"ABC" "DEF"} --> 'std::vector<std::string>{"ABC", "DEF"}'
                % cell of char: {'ABC' 'DEF'} --> 'std::vector<std::string>{"ABC", "DEF"}'
                % cell of int64: {1 2 3} --> 'std::vector<int64_t>{1, 2, 3}'
                % cell of double: {1.0 2.0 3.0} --> 'std::vector<double>{1.0, 2.0, 3.0}'
                % cell of logical: {true false} --> 'std::vector<bool>{true, false}'
                % cell of uint8: {1 2 3} --> 'std::vector<unsigned char>{1,2,3}'
                paramValueSubString = processCellArray(nextLayer);
                paramValueChar = [prefixString paramValueSubString];
            else
                if length(nextLayer)>1 && ~ischar(nextLayer)
                    % Syntax:
                    % int64 array: [1 2 3] --> 'std::vector<int64_t>{1, 2, 3}'
                    % double array: [1.0 2.0 3.0] --> 'std::vector<double>{1.0, 2.0, 3.0}'
                    % logical array: [true false] --> 'std::vector<bool>{1, 0}'
                    % uint8 array: [1 2 3] ---> 'std::vector<unsigned char>{1,2,3}'
                    typeStr = class(nextLayer);
                    if isequal(typeStr, 'int64')
                        typeStr = 'int64_t';
                    elseif isequal(typeStr, 'logical')
                        typeStr = 'bool';
                    elseif isequal(typeStr, 'uint8')
                        typeStr = 'unsigned char';
                    else
                        % do nothing
                    end

                    if isequal(typeStr,'double')
                        memCharSet = sprintf('%f',nextLayer(1,1));
                        for k = 2:length(nextLayer)
                            memCharSet = [memCharSet ', ' sprintf('%f',nextLayer(1,k))]; %#ok<AGROW>
                        end
                        paramValueChar = [prefixString typeStr '>{' memCharSet '}'];
                    else
                        memCharSet = sprintf('%d',nextLayer(1,1));
                        for k = 2:length(nextLayer)
                            memCharSet = [memCharSet ', ' sprintf('%d',nextLayer(1,k))]; %#ok<AGROW>
                        end
                        paramValueChar = [prefixString typeStr '>{' memCharSet '}'];
                    end

                else
                    % Syntax:
                    % char and char array: 'ABC' --> '"ABC"'
                    % int64: 1 --> '1'
                    % double: 1.1 --> '1.1'
                    % logical: true --> 'true'
                    % uint8: 1 --> '1' (note: this will be treated as an
                    % int64 as what ROS 2 did)
                    if ischar(nextLayer)
                        paramValueChar = ['"' nextLayer '"'];
                    elseif isequal(class(nextLayer),'double')
                        paramValueChar = sprintf('%f',nextLayer);
                    elseif islogical(nextLayer)
                        if nextLayer
                            paramValueChar = 'true';
                        else
                            paramValueChar = 'false';
                        end
                    else
                        paramValueChar = sprintf('%d',nextLayer);
                    end
                end
            end
            % add to formattedStruct
            currentParamStruct.Name = newStr;
            currentParamStruct.Value = paramValueChar;
            if isempty(nodeParameters(1).Name)
                nodeParameters(1) = currentParamStruct;
            else
                nodeParameters(end+1) = currentParamStruct; %#ok<AGROW>
            end
        end
    end
end
