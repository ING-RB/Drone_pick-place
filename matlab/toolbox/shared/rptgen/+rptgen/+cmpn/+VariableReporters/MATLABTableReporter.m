classdef MATLABTableReporter < ... 
    rptgen.cmpn.VariableReporters.VariableReporter & ...
    rptgen.cmpn.VariableReporters.HierarchicalObjectReporter    
% MATLABTableReporter generates a report for MATLAB table objects.

% Copyright 2015-2023 The MathWorks, Inc.

% To adhere to capitalized MATLAB acronym and according to coding standards
% allowing the use of capitalized names for variables if they are acronyms,
% suitable functions and variables start here capitals like MT

  properties
      VariableLinkIDs = [];
  end %  properties

  methods

    function moReporter = MATLABTableReporter(moOpts, joReport, varName, ...
        varValue)
          moReporter@rptgen.cmpn.VariableReporters.VariableReporter(moOpts, ...
              joReport, varName, varValue);
    end
    
    function joVarReport = makeAutoReport(moReporter)
        joVarReport = makeTabularReport(moReporter);
    end %function makeAutoReport()    
    
    function joVarReport = makeTabularReport(moReporter)
        isPropsSectRequired = ~isempty(moReporter.VarValue.Properties.Description)...
            || ~isempty(moReporter.VarValue.Properties.VariableUnits)...
            || ~isempty(moReporter.VarValue.Properties.VariableDescriptions)...
            || ~isempty(moReporter.VarValue.Properties.UserData);
        
        joVarReport = moReporter.makeArrayTable(isPropsSectRequired);

        if isPropsSectRequired
            joVarReport = reportMATLABTableProperties(moReporter, joVarReport);
        end
    end %function makeTabularReport()
    
 
    function joArrayReport = makeArrayTable(moReporter, areSectionsRequired)
        import rptgen.cmpn.VariableReporters.*;
        
        %Create section if necessary
        if areSectionsRequired
            sectNode =  moReporter.uddReport.createElement('simplesect');
            sectTitle =  moReporter.uddReport.createElement('title');
            textNode = moReporter.uddReport.createTextNode(rptgen.cmpn.VariableReporters.msg('MATLABTableDataSectTitle'));
            sectTitle.appendChild(textNode);
            sectNode.appendChild(sectTitle);

            % We need following ID because otherwise we'd get unfunctional
            %  links if we report on the same variable twice (dev tested)-M.M.

            objString = string(evalc('sectNode'));
            hashValue = mlreportgen.utils.hash(objString);
            prefixToId = char(hashValue);

        else
            sectNode = [];
            rng('shuffle');
            prefixToId = num2str(randi(intmax));
        end
        
        %Get data and properties from MATLAB table       
        columns = moReporter.VarValue.Properties.VariableNames; %cell, isrow()=true. This is never empty. Even if we create a Matlab table 
          % as T=array2table([1 12 30.48; 2 24 60.96; 3 36 91.44]); we'll get T.Properties.VariableNames='Var1' 'Var2' 'Var3'
          
        %Add links
        if ~isempty(moReporter.VarValue.Properties.VariableUnits) ...
            || ~isempty(moReporter.VarValue.Properties.VariableDescriptions)
            links = struct();
            MTColsCount = length(columns);
            for c = 1 : MTColsCount
                colName = columns{c};
                linkID = locCreateEntryID(prefixToId, colName);
                link = makeLink(moReporter.uddReport, linkID, colName, 'link');
                links.(colName) = linkID;
                columns{c} = link;
            end
            if ~isempty(fieldnames(links))
                moReporter.VariableLinkIDs = links;
            end
        end
        
        rowNames = moReporter.VarValue.Properties.RowNames; %cell, iscolumn=true. This and all the other except the columns above may be empty.
        if ~isempty(rowNames)
            cMTDataStart = 2;
            colsCount = length(columns) + 1;
        else
            cMTDataStart = 1;
            colsCount = length(columns);
        end
        
        MTData = table2cell(moReporter.VarValue);
        rowsCount = size(MTData, 1) + 1;
        rMTDataStart = 2;
          
        % Initialize cell array of proper size then populate it
        caTable = cell(rowsCount, colsCount);
        
        %Populate the first row
        for c = cMTDataStart : colsCount
            cellValue = columns{c - cMTDataStart + 1};
            joCellEntry = moReporter.uddReport.createElement('emphasis', cellValue);
            joCellEntry.setAttribute('xml:space', 'preserve');
            joCellEntry.setAttribute('role', 'bold');
            caTable{1, c} = joCellEntry;
        end
        
        %Populate the first column (no need if ~(cMTDataStart > 1))
        if cMTDataStart > 1
            for r = 1 : rowsCount
                if r == 1
                    if ~isempty(moReporter.VarValue.Properties.DimensionNames) %may only be 1x2 cell
                        cellValue = [moReporter.VarValue.Properties.DimensionNames{1} ' \ ' moReporter.VarValue.Properties.DimensionNames{2}];
                    else
                        cellValue = '';
                    end
                else
                    cellValue = rowNames{r - rMTDataStart + 1};
                end    
                joCellEntry = moReporter.uddReport.createElement('emphasis', cellValue);
                joCellEntry.setAttribute('xml:space', 'preserve');
                joCellEntry.setAttribute('role', 'italic');
                caTable{r, 1} = joCellEntry;
            end
        end
        
        %Populate the body of the data table
        for r = rMTDataStart : rowsCount
            rSource = r - rMTDataStart + 1;
            for c = cMTDataStart : colsCount
                cSource = c - cMTDataStart + 1;
                cellValue = MTData{rSource, cSource};
                cellReportTitleSuffix = sprintf('(%d,%d)', rSource, cSource);
                caTable{r, c} = moReporter.makeCellEntry(cellReportTitleSuffix, cellValue);
            end 
        end 
      
        if ~isempty(caTable)
            joArrayReport = moReporter.makeValueTable(caTable);
            if ~isempty(sectNode)
                while joArrayReport.hasChildNodes()
                    sectNode.appendChild(joArrayReport.getFirstChild());
                end
                joArrayReport.appendChild(sectNode);
            end
        else
            joArrayReport = [];
        end          
    end %function makeArrayTable()

    
    function joCellEntry = makeCellEntry(moReporter, cellReportTitleSuffix, cellValue)
        import rptgen.cmpn.VariableReporters.*;
        saveTitleMode = moReporter.moOpts.TitleMode;
             
        if isempty(cellValue)
            joCellEntry = moReporter.uddReport.createTextNode('');
        else
            if isempty(moReporter.ReportTitle)
                cellReportTitleRoot = class(moReporter.VarValue);
            else
                cellReportTitleRoot = moReporter.ReportTitle;
            end
            cellReportTitle = [cellReportTitleRoot cellReportTitleSuffix];
            moReporter.moOpts.TitleMode = 'auto';
            moCellReporter = ReporterFactory.makeReporter(moReporter.moOpts, ...
                moReporter.uddReport, cellReportTitle, cellValue);
            if isa(moCellReporter, ...
                'rptgen.cmpn.VariableReporters.HierarchicalObjectReporter') && ...
                    moReporter.ReportLevel < moReporter.moOpts.DepthLimit
                forwardLink = moReporter.makeLink(moCellReporter.ReportId, ...
                    cellReportTitle);
            
                joCellEntry = forwardLink;
                moReporter.makeBackLink(moCellReporter, cellReportTitleSuffix);
                moCellReporter.ReportLevel = moCellReporter.ReportLevel + 1;
                ReporterQueue.getTheQueue().add(moCellReporter);
            else
                moCellReporter.moOpts.TitleMode = 'none';
                joCellEntry = moCellReporter.makeTextReport();
            end
            moReporter.moOpts.TitleMode = saveTitleMode;
        end
    end %function makeCellEntry()
    
           
    function joVarReport = reportMATLABTableProperties(moReporter, joVarReport)
        sectNode =  moReporter.uddReport.createElement('simplesect');
        sectTitle =  moReporter.uddReport.createElement('title');
        textNode = moReporter.uddReport.createTextNode(rptgen.cmpn.VariableReporters.msg('MATLABTablePropsSectTitle'));
        sectTitle.appendChild(textNode);
        sectNode.appendChild(sectTitle);

        %Report on present properties one by one
        if ~isempty(moReporter.VarValue.Properties.Description)
            makeTableDescriptionReport(moReporter, sectNode);
        end

        if ~isempty(moReporter.VarValue.Properties.VariableUnits)...
            || ~isempty(moReporter.VarValue.Properties.VariableDescriptions)
            makeVariablePropertiesReport(moReporter, sectNode);
        end

        if ~isempty(moReporter.VarValue.Properties.UserData)
            makeUserDataReport(moReporter, sectNode)
        end
        joVarReport.appendChild(sectNode);
        
    end %function reportMATLABTableProperties()
    
    
    function makeTableDescriptionReport(moReporter, sectNode)
        descrTransl = rptgen.cmpn.VariableReporters.msg('MATLABTableVarDescription');
        descr = [descrTransl ': ' moReporter.VarValue.Properties.Description];
        joReportDescr = moReporter.uddReport.createElement('para', descr);
        appendChild(sectNode, joReportDescr);
    end %function makeTableDescriptionReport
    
    
    function makeVariablePropertiesReport(moReporter, sectNode)
        fNames(2 : length(moReporter.VarValue.Properties.VariableNames)+1) = ...
            moReporter.VarValue.Properties.VariableNames; %Always present. cell, isrow()=true
        fNames{1} = rptgen.cmpn.VariableReporters.msg('MATLABTableVarName'); %'Name';
        varPropNamesVect = transpose(fNames);
        MTVarPropsBody = varPropNamesVect;
        for row = 2 : length(MTVarPropsBody)
            varPropName = varPropNamesVect{row};
            if isfield(moReporter.VariableLinkIDs, varPropName)
                anchId = moReporter.VariableLinkIDs.(varPropName);
                anchor = makeLink(moReporter.uddReport, anchId, varPropName, 'anchor');
                MTVarPropsBody{row} = anchor;
            end
        end
        
        if ~isempty(moReporter.VarValue.Properties.VariableUnits)
            fValues(2:length(moReporter.VarValue.Properties.VariableUnits)+1) = ...
                moReporter.VarValue.Properties.VariableUnits; %cell, isrow()=true
            fValues{1} = rptgen.cmpn.VariableReporters.msg('MATLABTableVarUnit'); %'Unit';
            unitsVect = transpose(fValues);
            MTVarPropsBody = horzcat(MTVarPropsBody, unitsVect);
        end
               
        if ~isempty(moReporter.VarValue.Properties.VariableDescriptions)
            fValues(2:length(moReporter.VarValue.Properties.VariableDescriptions)+1) = ...
                moReporter.VarValue.Properties.VariableDescriptions; %cell, isrow()=true
            fValues{1} = rptgen.cmpn.VariableReporters.msg('MATLABTableVarDescription'); %'Description';
            descrsVect = transpose(fValues);
            MTVarPropsBody = horzcat(MTVarPropsBody, descrsVect);
        end
                     
        tableMaker = makeNodeTable(moReporter.uddReport, MTVarPropsBody);
        tableMaker.setTitle(rptgen.cmpn.VariableReporters.msg('MATLABTableVarPropsTableTitle')); %'Variable properties';
        if isprop(moReporter.moOpts, 'MakeTablePageWide')
            tableMaker.setPageWide(moReporter.moOpts.MakeTablePageWide);
        else
            tableMaker.setPageWide(false);            
        end
        
        if isprop(moReporter.moOpts, 'ShowTableGrids') && ~moReporter.moOpts.ShowTableGrids
            tableMaker.setBorder(false);
        end
        
        tableMaker.setNumHeadRows(1);
        MTvarPropsTable = createTable(tableMaker);
        appendChild(sectNode, MTvarPropsTable);
        
    end %function makeVariablePropertiesReport
    
    
    function makeUserDataReport(moReporter, sectNode)
        uDataTitleText = [moReporter.ReportTitle '.' 'User Data' ':'];
        moUDataReporter = rptgen.cmpn.VariableReporters.ReporterFactory.makeReporter(...
            moReporter.moOpts, moReporter.uddReport, uDataTitleText, moReporter.VarValue.Properties.UserData);

        uDataReport = moUDataReporter.makeAutoReport();
        appendChild(sectNode, uDataReport);
    end

  end % of dynamic methods
end

function id = locCreateEntryID(sectNodeId, colName)
    origStrId = [sectNodeId colName];
    id = char(mlreportgen.utils.normalizeLinkID(origStrId));
end %function locCreateEntryID
