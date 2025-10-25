classdef ClassFileInformation < matlab.unittest.internal.fileinformation.FileInformation
    %

    %  Copyright 2017-2021 The MathWorks, Inc.
    
    properties (SetAccess = private)
        MethodList  matlab.unittest.internal.fileinformation.CodeSegmentInformation = matlab.unittest.internal.fileinformation.MethodInformation.empty(1,0)
    end
    
    properties (Access = private)
        SetMethodList = false;
    end
     
    methods(Access = ?matlab.unittest.internal.fileinformation.FileInformation)
        function info = ClassFileInformation(parseTree)
            info = info@matlab.unittest.internal.fileinformation.FileInformation(parseTree);
        end
    end
    
    methods
        function methodInformation = get.MethodList(info)
            import matlab.unittest.internal.fileinformation.MethodInformation
            if ~info.SetMethodList
                classExecutableLines = info.ExecutableLines;
                methodFcnNodes = getMethodFunctionNodes(info);
                nodeIndices = indices(methodFcnNodes);
                numMethods = numel(nodeIndices);
                methodInfoArray = cell(1,numMethods);
                for idx = 1:numMethods
                    currentNode = methodFcnNodes.select(nodeIndices(idx));
                    methodInfoArray{idx} = MethodInformation(currentNode,classExecutableLines);
                end
                info.MethodList = [MethodInformation.empty(1,0) methodInfoArray{:}];
                info.SetMethodList = true;
            end
            methodInformation = info.MethodList;
        end
    end
    
    methods (Access = private)      
        function methodFcnNodes = getMethodFunctionNodes(info)
            methodNodes = mtfind(info.FileTree,'Kind','METHODS');
            methodFcnNodes = mtfind(methodNodes.Body.List,'Kind',{'FUNCTION','PROTO'});
        end
    end
end