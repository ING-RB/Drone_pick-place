classdef ContextMenuProvider < handle
    %CONTEXTMENUPROVIDER This class creates a structure for context menus
    % that are to be displayed on the client side by scanning through an
    % XML file containing a list of all the context menu options. 
    % Given below is a sample xml structure from the XML file. 
    % <ContextMenu ID="ContextMenu">        
    %   <Context MatchContext="component1,row" ID="Context1">
    %     <ActionGroup Expanded="True" ID="copyAction" >
    %        <Action ID="Action1" MessageID="Copy Action"/
    %     </ActionGroup>  
    %     <MenuSeparator/>
    %   </Context>    
    % </ContextMenu>
    
    % Copyright 2019 The MathWorks, Inc.
  
    
    properties(Access=private)
        ContextMenuXML
    end
    
    methods
        % xmlFile is the file to be scanned for creating context menu
        % options
        % xmlRootProps contains a list of all startup properties to be
        % specified on the root of the XML node. (i.e struct parent to ContextMenu option) 
        function this = ContextMenuProvider(xmlFile, xmlRootProps)            
            if (nargin < 2)
                xmlRootProps = struct;
            end
            contextMenuXML = internal.matlab.datatoolsservices.contextmenuservice.XMLParser.parseXML(xmlFile);
            this.initXMLStruct(contextMenuXML, xmlRootProps);
        end  
        
        % Gets the contextMenuXML option that was created and hashed.
        function menuXML = getContextMenuXML(this)
            menuXML = struct;
            if ~isempty(this.ContextMenuXML)
                menuXML = this.ContextMenuXML;
            end
        end    
    end
    
    methods(Access=private)
        % initializes the XML Struct with xmlRootProps.
        function initXMLStruct(this, parsedXML, xmlRootProps)
            % set the rootProps on root structure of the ContextMenuXML
            %struct('queryString',queryString,'actionNamespace',actionNamespace)
            rootXMLNode = struct('Data', struct, 'Children', struct);
            fieldNames = fieldnames(xmlRootProps);
            for fieldIndex=1:numel(fieldNames)
                fieldName = fieldNames{fieldIndex};
                if(~isempty(xmlRootProps.(fieldName)))                    
                    rootXMLNode.Data.(fieldName) = xmlRootProps.(fieldName);
                end
            end
            rootXMLNode.('Children') = parsedXML;
            this.ContextMenuXML = rootXMLNode;
        end
    end
end

