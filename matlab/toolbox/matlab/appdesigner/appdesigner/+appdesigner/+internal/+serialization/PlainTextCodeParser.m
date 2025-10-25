classdef PlainTextCodeParser < handle
    %PLAINTEXTCODEPARSER Parses MATLAB Code from an plain-text file

    properties
        FileContent
        CodeData
    end

    properties (Access = private)
        CodeMTree
    end

    methods
        function obj = PlainTextCodeParser(fileContent)
            arguments
                fileContent (:,1) string
            end

            obj.FileContent = fileContent;
            obj.CodeMTree = mtree(obj.FileContent, '-com');
            obj.validate();
        end

        function codeData = parseCodeData(obj, componentCallbackAssignments, startupName, isSingleton)
            arguments
                obj
                componentCallbackAssignments struct
                startupName string = ""
                isSingleton logical = false
            end

            className = obj.findClassName();

            callbacks = obj.buildCallbackData(componentCallbackAssignments);

            editableSectionCode = obj.findEditableSectionCode(~isempty(callbacks));

            [startupCallback, inputParams] = obj.parseStartUpFcn(startupName);

            appTypeData = [];

            codeData = struct( ...
                'ClassName', className, ...
                'EditableSectionCode', [], ...
                'Callbacks', callbacks, ...
                'StartupFcn', startupCallback, ...
                'InputParameters', inputParams, ...
                'AppTypeData', appTypeData ...
                );
            
            codeData.EditableSectionCode = editableSectionCode;

            if isSingleton
                codeData.singletonMode = 'FOCUS';
            end
        end


        function [startupFcn, inputParams] = parseStartUpFcn(obj, startupName)
            startupFcn = [];
            inputParams = [];

            if ~strlength(startupName)
                return;
            end

            [callbackCode, funcNode] = obj.getCallbackCode(startupName);

            startupFcn = struct;
            startupFcn.Name = startupName;
            startupFcn.Code = callbackCode;

            inputParams = {};

            argNode = funcNode.Ins;

            if (argNode.stringval ~= 'app')
                % TODO - ERROR or auto add #fix
                % use artifact generator API for 'app' var?
            end

            while ~isempty(argNode.Next)
                argNode = argNode.Next;
                inputParams = [inputParams argNode.stringval];
            end

            inputParams = strjoin(inputParams, ', ');


        end

        function editableSectionCode = findEditableSectionCode(obj, hasCallbacks)
            % #fix - IMPORTANT LIMITATION - assumes properties and methods 
            % blocks are all in default AD order with default spacing and default comments. 
            % This makes this get editable section fragile to user changes.
            % 

            if hasCallbacks
                minMethodsBlocks = 1;
                endLinesToRemove = 3; %accounts for extra whitespace and comments
            else
                minMethodsBlocks = 0;
                endLinesToRemove = 1;
            end

            minPropsBlocks = 1;

            propsBlocks = mtfind(obj.CodeMTree, 'Kind', 'PROPERTIES');
            methodsBlocks = mtfind(obj.CodeMTree, 'Kind', 'METHODS');

            if propsBlocks.count == minPropsBlocks && methodsBlocks.count == minMethodsBlocks
                editableSectionCode = [];
            else
                propsBlocksIndices = indices(propsBlocks);
                appComponentsPropsBlock = select(propsBlocks, propsBlocksIndices(1));

                % position of last node in app components property block
                startIndex = righttreepos(appComponentsPropsBlock);

                methodsBlocksIndices = indices(methodsBlocks);
                callbacksMethodsBlock = select(methodsBlocks, methodsBlocksIndices(end));

                endIndex = lefttreepos(callbacksMethodsBlock);
                editableSectionCode = extractBetween(obj.FileContent, startIndex, endIndex);
                editableSectionCode = splitlines(char(editableSectionCode))';

                % first three lines are 'end' and whitespace from app
                % components prop block above
                editableSectionCode = editableSectionCode(4:end - endLinesToRemove);
            end
        end

        function className = findClassName(obj)
            node = mtfind(obj.CodeMTree, 'Kind', 'CLASSDEF');
            node = node.Cexpr;
            className = node.Left.stringval;
        end

        function callbacks = buildCallbackData(obj, componentData, callbacks)
            % TODO - consider adding the component data here instead of
            % Loader handling later
            arguments
                obj
                componentData
                callbacks = []
            end

            if ~isempty(componentData.AssignedCallbacks)
                if isempty(callbacks) || ...
                        ~any(strcmp({callbacks.Name}, componentData.AssignedCallbacks.Name))

                    componentCallback.Name = componentData.AssignedCallbacks.Name;
                    componentCallback.Code = obj.getCallbackCode(componentCallback.Name);

                    if ~isempty(componentCallback.Code)
                        callbacks = [callbacks componentCallback];
                    end
                end
            end

            if ~isempty(componentData.Children)
                for m = 1:numel(componentData.Children)
                    callbacks = obj.buildCallbackData(componentData.Children(m), callbacks);
                end
            end
        end

        function [callbackCode, funcNode] = getCallbackCode(obj, callbackName)

            callbackCode = '';

            funcNode = mtfind(obj.CodeMTree, 'Kind', 'FUNCTION', 'Fname.String', callbackName);

            if ~isempty(funcNode)
                startNode = funcNode;
                endNode = funcNode.Body;

                while ~isempty(endNode) && ~isempty(endNode.Next)
                    endNode = endNode.Next;
                end

                callbackCode = extractBetween(obj.FileContent, lefttreepos(startNode), righttreepos(endNode));

                callbackCode = splitlines(char(callbackCode));

                callbackCode = callbackCode(2:end);
            end
        end

        function validate(obj)

        end

        function indentedCode = indentCode(obj, code)
            if ~iscell(code)
                code = strsplit(code, newline);
            end
            indentedCode = cellfun(@(line) [blanks(12) strtrim(line)], code, 'UniformOutput', false);
        end

    end
end
