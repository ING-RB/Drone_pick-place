function mcodeConstructor(obj,code)
%MCODECONSTRUCTOR Constructor code generation

%   Copyright 2024 The MathWorks, Inc.

setConstructorName(code,'violinplot')
plotutils('makemcode',obj,code)
ignoredProps = {'SourceTable','XVariable','YVariable',...
    'XData','YData','EvaluationPoints','DensityValues'};

hPeers = obj.ViolinPeers;
hasPeers = ~isempty(hPeers);
if hasPeers
    hPeerMomentoList = [];
    % Get a list of the all the momento objects
    hPeerMomentoList = get(code,'MomentoRef');
    hParentMomento = up(hPeerMomentoList(1));
    if ~isempty(hParentMomento)
        hPeerMomentoList = findobj(hParentMomento,'-depth',1);

        % Loop through peer momento objects
        for n = 2:length(hPeerMomentoList)
            hPeerMomento = hPeerMomentoList(n);
            hPeerObj = get(hPeerMomento,'ObjectRef');

            % Mark momento object ignore so that no code gets generated
            if ~isempty(hPeerObj) && any(find(hPeers==hPeerObj)) && ...
                    hPeerObj ~= obj
                set(hPeerMomento,'Ignore',true);
            end
        end
    end
end

if obj.EvaluationPointsMode == "manual" || obj.DensityValuesMode == "manual"
    % Using pdf input:
    % violinplot('EvaluationPoints',evalPts,'DensityValues',densVals)

    % EvaluationPoints:
    arg = codegen.codeargument('Name','EvaluationPoints','Value','EvaluationPoints',...
        'IsParameter',false);
    addConstructorArgin(code,arg);
    arg = codegen.codeargument('Name','evalPts','Value',obj.EvaluationPoints,...
        'IsParameter',true, 'Comment','violinplot evaluation points');
    addConstructorArgin(code,arg);

    % DensityValues:
    arg = codegen.codeargument('Name','DensityValues','Value','DensityValues',...
        'IsParameter',false);
    addConstructorArgin(code,arg);
    arg = codegen.codeargument('Name','densVals',...
        'IsParameter',true, 'Comment','violinplot density values');
    addConstructorArgin(code,arg);

    % 'GroupByColor' not supported, following has no effect on the object:
    ignoredProps = [ignoredProps(:)' {'ColorGroupLayout','ColorGroupWidth'}];

elseif obj.isDataComingFromDataSource('Y')
    % Table input:
    % violinplot(tbl, xvar, yvar)
    % violinplot(tbl, yvar)

    % Source table:
    arg = codegen.codeargument('Name','tbl','Value',obj.SourceTable,...
        'IsParameter',true, 'Comment','violinplot source table');
    addConstructorArgin(code,arg);

    % x-variable, if provided:
    hasXVar = obj.isDataComingFromDataSource('X');
    if hasXVar
        xvarComment = 'violinplot x variable';
        if hasPeers
            xvarComment = [xvarComment,' (scalar or vector)'];
        end
        arg = codegen.codeargument('Name','xvar','Value',obj.XVariable,...
            'IsParameter',true, 'Comment',xvarComment);
        addConstructorArgin(code,arg);
    end

    % y-variable:
    yvarComment = 'violinplot y variable';
    if hasPeers
        if hasXVar
            yvarComment = [yvarComment,' (scalar or vector)'];
        else
            yvarComment = [yvarComment,' (vector)'];
        end
    end
    arg = codegen.codeargument('Name','yvar','Value',obj.YVariable,...
        'IsParameter',true, 'Comment',yvarComment);
    addConstructorArgin(code,arg);

    % 'GroupByColor' not supported, following has no effect on the object:
    ignoredProps = [ignoredProps(:)' {'ColorGroupLayout','ColorGroupWidth'}];

else
    % Data input:
    % violinplot(xgrouping, ydata)
    % violinplot(ydata)
    % violinplot(xgroupdata,ydata,'GroupByColor',cgroupdata)
    % violinplot(ydata,'GroupByColor',cgroupdata)

    grpByCol = obj.GroupByColorMode == "manual";

    % Process XData
    hasXData = obj.XDataMode == "manual";
    if hasXData
        xDataComment = 'violinplot x grouping';
        if grpByCol || ~hasPeers 
            xDataComment = [xDataComment,' (vector)'];
        else
            xDataComment = [xDataComment,' (vector or matrix)'];
        end
        arg = codegen.codeargument('Name','xgroupdata','Value',obj.XData, ...
            'IsParameter',true, 'Comment',xDataComment);
        addConstructorArgin(code,arg);
    end
    % process YData
    yDataComment = 'violinplot y sample data';
    if grpByCol || ~hasPeers
        yDataComment = [yDataComment,' (vector)'];
    else
        if hasXData
            yDataComment = [yDataComment,' (vector or matrix)'];
        else
            yDataComment = [yDataComment,' (matrix)'];
        end
    end
    arg = codegen.codeargument('Name','ydata','Value',obj.YData, ...
        'IsParameter',true, 'Comment',yDataComment);
    addConstructorArgin(code,arg);

    if grpByCol
        % Add 'GroupByColor' as NV-pair:
        arg = codegen.codeargument('Name','GroupByColor','Value','GroupByColor',...
            'IsParameter',false);
        addConstructorArgin(code,arg);
        arg = codegen.codeargument('Name','cgroupdata',...
            'IsParameter',true, 'Comment','violinplot color grouping data (vector)');
        addConstructorArgin(code,arg);
    else
        ignoredProps = [ignoredProps(:)' {'ColorGroupLayout','ColorGroupWidth'}];
    end

end

% Ignore properties:
ignoreProperty(code,ignoredProps);

% Generate code
generateDefaultPropValueSyntax(code);

end

