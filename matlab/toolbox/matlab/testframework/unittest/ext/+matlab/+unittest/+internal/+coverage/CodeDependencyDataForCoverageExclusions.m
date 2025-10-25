classdef CodeDependencyDataForCoverageExclusions < handle
    % Class is undocumented and may change in a future release.

    %  Copyright 2023 The MathWorks, Inc.

    properties (Hidden)
        Filename
        Tree
    end

    properties(Access=private)
        CoveredNodeIndices=[]  % Avoid duplicate nodes being counted twice. Especially nested switch cases, etc.
    end

    methods
        function obj = CodeDependencyDataForCoverageExclusions(filename)
            obj.Filename = filename;
        end

        function dataArray = getDependencyData(obj)
            obj.Tree = mtree(obj.Filename,'-file');
            dataArray = obj.getDependencyDataForIfConditionalBlock;
            dataArray = dataArray.append(obj.getDependencyDataForLoopBlock('FOR'));
            dataArray = dataArray.append(obj.getDependencyDataForLoopBlock('WHILE'));
            dataArray = dataArray.append(obj.getDependencyDataForTryCatchBlock);
            dataArray = dataArray.append(obj.getDependencyDataForFunctionBlock);
            dataArray = dataArray.append(obj.getDependencyDataForSwitchCaseBlock);
        end
    end

    methods(Access=private)
        function data= getDependencyDataForIfConditionalBlock(obj)
            tree = obj.Tree;
            ifNodes = tree.mtfind('Kind','IF');
            if isempty(ifNodes)
                data = matlab.unittest.internal.coverage.StatementDependencyMap.empty;
                return
            end

            nodeIndices = indices(ifNodes);
            numIfNodes = numel(nodeIndices);
            mapObjCell = cell(1,numIfNodes);
            for idx = 1:numIfNodes
                currentNodeIdx = nodeIndices(idx);
                if ~ismember(currentNodeIdx,obj.CoveredNodeIndices)
                    currentIfNode = ifNodes.select(currentNodeIdx);
                    mapObjCell{idx} = obj.buildMapObjForIFNode(currentIfNode);
                end
            end
            obj.updateCoveredIndices(nodeIndices);
            data = [mapObjCell{:}];
        end

         function data= getDependencyDataForSwitchCaseBlock(obj)
            tree = obj.Tree;
            switchNodes = tree.mtfind('Kind','SWITCH');            
            if isempty(switchNodes)
                data = matlab.unittest.internal.coverage.StatementDependencyMap.empty;
                return
            end
            nodeIndices = indices(switchNodes);
            numSwitchNodes = numel(nodeIndices);
            mapObjCell = cell(1,numSwitchNodes);
            for idx = 1:numSwitchNodes
                currentNodeIdx = nodeIndices(idx);
                if ~ismember(currentNodeIdx,obj.CoveredNodeIndices)
                    currentSwitchNode = switchNodes.select(currentNodeIdx);
                    mapObjCell{idx} = obj.buildMapObjForSwitchNode(currentSwitchNode);
                end
            end
            obj.updateCoveredIndices(nodeIndices);
            data = [mapObjCell{:}];
        end

        function data= getDependencyDataForLoopBlock(obj, loopKind)
            tree = obj.Tree;
            loopNodes = tree.mtfind('Kind',loopKind);

            if isempty(loopNodes)
                data = matlab.unittest.internal.coverage.StatementDependencyMap.empty;
                return
            end

            nodeIndices = indices(loopNodes);
            numLoopNodes = numel(nodeIndices);
            mapObjCell = cell(1,numLoopNodes);
            for idx = 1:numLoopNodes
                currentNodeIdx = nodeIndices(idx);
                if ~ismember(currentNodeIdx,obj.CoveredNodeIndices)
                    currentLoopNode = loopNodes.select(currentNodeIdx);
                    trueLines = unique(currentLoopNode.Body.Full.lineno');
                    falseLines = []; % FalseLines are empty for all non-conditional statements.
                    mapObjCell{idx} = StatementDependencyMap(currentLoopNode, string(loopKind), getNodeLineNumbers(currentLoopNode) ,trueLines,falseLines);
                end
            end
            obj.updateCoveredIndices(nodeIndices);
            data = [mapObjCell{:}];
        end

        function data= getDependencyDataForTryCatchBlock(obj)
            tree = obj.Tree;
            tryNodes = tree.mtfind('Kind','TRY');

            if isempty(tryNodes)
                data = matlab.unittest.internal.coverage.StatementDependencyMap.empty;
                return
            end

            nodeIndices = indices(tryNodes);
            numTryNodes = numel(nodeIndices);
            mapObjCell = cell(2,numTryNodes);
            for idx = 1:numTryNodes
                currentNodeIdx = nodeIndices(idx);
                if ~ismember(currentNodeIdx,obj.CoveredNodeIndices)
                    currentTryNode = tryNodes.select(currentNodeIdx);
                    tryLinesCurrentNode = unique(currentTryNode.Try.Full.lineno');
                    mapObjCell{1,idx} = StatementDependencyMap(currentTryNode, "TRY", getNodeLineNumbers(currentTryNode) ,tryLinesCurrentNode,[]);
                    mapObjCell{2,idx} = obj.buildMapObjForCatchNode(currentTryNode);
                end
            end
            obj.updateCoveredIndices(nodeIndices);
            data = [mapObjCell{:}];
        end

        function data= getDependencyDataForFunctionBlock(obj)
            tree = obj.Tree;

            funcNodes = tree.mtfind('Kind','FUNCTION');

            if isempty(funcNodes)
                data = matlab.unittest.internal.coverage.StatementDependencyMap.empty;
                return
            end

            nodeIndices = indices(funcNodes);
            numFuncNodes = numel(nodeIndices);
            mapObjCell = cell(1,numFuncNodes);
            for idx = 1:numFuncNodes
                currentNodeIdx = nodeIndices(idx);
                if ~ismember(currentNodeIdx,obj.CoveredNodeIndices)
                    currentFuncNode = funcNodes.select(currentNodeIdx);
                    trueLines = unique(currentFuncNode.Body.Full.lineno');
                    mapObjCell{idx} = StatementDependencyMap(currentFuncNode,"FUNCTION", getNodeLineNumbers(currentFuncNode) ,trueLines,[]);
                end
            end
            obj.updateCoveredIndices(nodeIndices);
            data = [mapObjCell{:}];
        end

        function mapObj = buildMapObjForIFNode(obj,ifNode)
            % if part
            ifHead = ifNode.Tree.mtfind('Kind','IFHEAD') ;
            ifHeadIndices = indices(ifHead);
            ifHead = ifHead.select(ifHeadIndices(1)); % Just operate on the current if node, exclude any nested ifs.

            % all statement nodes in the if block
            ifBodyNodes = ifHead.Body;

            % line numbers of statements in the if block
            ifBodyLineNumbers = unique(ifBodyNodes.Full.lineno)';
            allIfBlockLineNumbers = unique(ifHead.Full.lineno)';
            ifStatementLineNumbers = getNodeLineNumbers(ifHead);

            trueLines = ifBodyLineNumbers;
            falseLines = setdiff(allIfBlockLineNumbers,[ifBodyLineNumbers,ifStatementLineNumbers]);

            ifMapObj = StatementDependencyMap(ifNode, "IF", ifStatementLineNumbers ,trueLines,falseLines);
            elseIFMapObj = obj.buildMapObjForELSEIFNode(ifNode);
            mapObj = [ifMapObj,elseIFMapObj];
        end

        function mapObj = buildMapObjForSwitchNode(obj,switchNode)
            % Case nodes
            caseNodes = switchNode.Body.Full.mtfind('Kind','CASE') ;

            if isempty(caseNodes)
                mapObj = matlab.unittest.internal.coverage.StatementDependencyMap.empty;
                return
            end

            % An if conditional block could have multiple elseifs
            nodeIndices = indices(caseNodes);
            numCaseNodes = numel(nodeIndices);
            mapObjCell = cell(1,numCaseNodes);
            for idx = 1:numCaseNodes
                currentNodeIdx = nodeIndices(idx);
                if ~ismember(currentNodeIdx,obj.CoveredNodeIndices)
                    currentCaseNode = caseNodes.select(currentNodeIdx);
                    currentNodeBodyNodes = currentCaseNode.Body;
                    caseBodyLineNumbers = unique(currentNodeBodyNodes.Full.lineno)';
                    allCaseLineNumbers = unique(currentCaseNode.Full.lineno)';

                    trueLines = caseBodyLineNumbers;
                    falseLines = setdiff(allCaseLineNumbers,[caseBodyLineNumbers, getNodeLineNumbers(currentCaseNode)]);
                    mapObjCell{idx} = StatementDependencyMap(currentCaseNode, "SWITCH-CASE", getNodeLineNumbers(currentCaseNode) ,trueLines,falseLines);
                end
            end
            obj.updateCoveredIndices(nodeIndices);
            mapObj = [mapObjCell{:}];
        end


        function mapObj = buildMapObjForELSEIFNode(obj,ifNode)
            % elseif part
            elseifHeadNode = ifNode.Tree.mtfind('Kind','ELSEIF') ;

            if isempty(elseifHeadNode)
                mapObj = matlab.unittest.internal.coverage.StatementDependencyMap.empty;
                return
            end

            % An if conditional block could have multiple elseifs
            nodeIndices = indices(elseifHeadNode);
            numElseIfNodes = numel(nodeIndices);
            mapObjCell = cell(1,numElseIfNodes);
            for idx = 1:numElseIfNodes
                currentNodeIdx = nodeIndices(idx);
                if ~ismember(currentNodeIdx,obj.CoveredNodeIndices)
                    currentElseIfNode = elseifHeadNode.select(nodeIndices(idx));
                    currentNodeBodyNodes = currentElseIfNode.Body;
                    elseifBodyLineNumbers = unique(currentNodeBodyNodes.Full.lineno)';
                    allElseIfLineNumbers = unique(currentElseIfNode.Full.lineno)';

                    trueLines = elseifBodyLineNumbers;
                    falseLines = setdiff(allElseIfLineNumbers,[elseifBodyLineNumbers, getNodeLineNumbers(currentElseIfNode)]);
                    mapObjCell{idx} = StatementDependencyMap(currentElseIfNode, "ELSEIF", getNodeLineNumbers(currentElseIfNode) ,trueLines,falseLines);
                end
            end
            obj.updateCoveredIndices(nodeIndices);
            mapObj = [mapObjCell{:}];
        end

        function mapObj = buildMapObjForCatchNode(~,tryNode)
            % Its strange but we have access the current catch node via the first node
            % in the catch block;
            firstNodeInsideCatchNode = tryNode.Catch;
            if isempty(firstNodeInsideCatchNode)
                mapObj = matlab.unittest.internal.coverage.StatementDependencyMap.empty;
                return
            end

            currentCatchNode = firstNodeInsideCatchNode.Parent;

            catchLinesCurrentNode = unique(currentCatchNode.Body.Full.lineno');
            mapObj = StatementDependencyMap(currentCatchNode, "CATCH", getNodeLineNumbers(currentCatchNode) ,catchLinesCurrentNode,[]);
        end

        function updateCoveredIndices(obj,newNodeIndices)
            obj.CoveredNodeIndices = unique([obj.CoveredNodeIndices,newNodeIndices]);
        end
    end
end

function mapObj = StatementDependencyMap(varargin)
mapObj = matlab.unittest.internal.coverage.StatementDependencyMap(varargin{:});
end

function lineNo = getNodeLineNumbers(node)
if strcmp(node.kind, 'FOR')
    lineNo = unique([node.lineno', node.Index.Full.lineno', node.Vector.Full.lineno']);
elseif strcmp(node.kind, 'FUNCTION')
    lineNo = unique([node.lineno', node.Fname.Full.lineno', node.Ins.Full.lineno']);
else
    lineNo = unique([node.lineno', node.Left.Full.lineno']);
end
end




