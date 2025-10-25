classdef ListMaker < handle
    %LISTMAKER Converts a MATLAB array to a DocBook list
    %   An instances of this class generates a DocBook list from an
    %   an array of strings, character arrays, or MAXP Text nodes.
    
    % Copyright 2020 Mathworks, Inc.
    
    
    
    methods (Static)
        
        function val = LIST_TYPE_ITEMIZED(), val = "itemizedlist"; end
        function val = LIST_TYPE_ORDERED(), val = "orderedlist"; end
        function val = LIST_TYPE_SIMPLE(), val = "simplelist"; end
        
        function val = NUMERATION_TYPE_ARABIC(), val = "arabic"; end
        function val = NUMERATION_TYPE_LOWERALPHA(), val  = "loweralpha"; end
        function val = NUMERATION_TYPE_UPPERALPHA(), val  = "upperalpha"; end
        function val = NUMERATION_dTYPE_LOWERRROMAN(), val = "lowerroman"; end
        function val = NUMERATION_TYPE_UPPERROMAN(), val  = "upperroman"; end
        
        function val = INHERITNUM_TYPE_INHERIT(), val = "inherit"; end
        function val = INHERITNUM_TYPE_IGNORE(), val  = "ignore"; end
        
        function val = CONTINUATION_TYPE_CONTINUES(), val = "continues"; end
        function val = CONTINUATION_TYPE_RESTARTS(), val  = "restarts"; end
        
        function val = SPACING_TYPE_COMPACT(), val = "compact"; end
        function val = SPACING_TYPE_NORMAL(), val  = "normal"; end
        
    end
    
    properties
        ListType string = rptgen.internal.docbook.ListMaker.LIST_TYPE_ORDERED;
        NumerationType string = rptgen.internal.docbook.ListMaker.NUMERATION_TYPE_ARABIC;
        InheritnumType string = rptgen.internal.docbook.ListMaker.INHERITNUM_TYPE_IGNORE;
        ContinuationType string = rptgen.internal.docbook.ListMaker.CONTINUATION_TYPE_RESTARTS;
        SpacingType string = rptgen.internal.docbook.ListMaker.SPACING_TYPE_COMPACT;
        ListTitle {mustBeObjectOrEmpty(ListTitle,'string')} = []
        ListTitleStyleName {mustBeObjectOrEmpty(ListTitleStyleName,'string')} = []
        ListStyleName {mustBeObjectOrEmpty(ListStyleName,'string')} = []
        ListContent {mustBeObjectOrEmpty(ListContent,'cell')} = [];
    end
    
    methods
        function obj = ListMaker(listContent)
            %LISTMAKER Construct an instance of this class
            %   Detailed explanation goes here
            if iscell(listContent)
                obj.ListContent = listContent;
            else
                obj.ListContent = {listContent};
            end
        end
        
        function setContent(obj,listContent), obj.ListContent=listContent; end
        function val = getContent(obj), val = obj.ListContent; end
        
        function setTitle(obj,title), obj.ListTitle = title; end
        function title = getTitle(obj), title = obj.ListTitle; end
        
        function setTitleStyleName(obj,name), obj.ListTitleStyleName = name; end
        function name = getTitleStyleName(obj), name = obj.ListTitleStyleName;end
        
        function setListStyleName(obj,name), obj.ListStyleName = name; end
        function name = getListStyleName(obj), name = obj.ListStyleName; end
        
        function setListType(obj,listType), obj.ListType = lower(listType); end
        function listType = getListType(obj), listType = obj.ListType; end
        
        function setNumerationType(obj,numerationType), obj.NumerationType = numerationType; end
        function type = getNumerationType(obj), type = obj.NumerationType; end
        
        function setInheritnumType(obj,iType), obj.InheritnumType = iType; end
        function type = getInheritnumType(obj), type = obj.InheritnumType; end
        
        function setContinuationType(obj,continuationType), obj.ContinuationType = continuationType; end
        function type = getContinuationType(obj), type = obj.ContinuationType;end
        
        function setSpacingType(obj,spacingType), obj.SpacingType = spacingType; end
        function type = getSpacingType(obj), type = obj.SpacingType; end
        
        function listEl = createList(obj, parentDocument)
            import rptgen.internal.docbook.ListMaker
            if isempty(obj.ListContent)
                listEl = createComment(parentDocument,"List is empty");
                return
            end
            
            listEl = createElement(parentDocument,obj.ListType);
            
            itemName = "listitem";  %Changes to "member" for simple list
            isSimple = false;
            if obj.ListType == ListMaker.LIST_TYPE_ORDERED
                setAttribute(listEl,"numeration",obj.NumerationType);
                setAttribute(listEl,"inheritnum",obj.InheritnumType);
                setAttribute(listEl,"continuation",obj.ContinuationType);
                setAttribute(listEl,"spacing",obj.SpacingType);
            elseif obj.ListType == ListMaker.LIST_TYPE_ITEMIZED
                setAttribute(listEl,"spacing",obj.SpacingType);
            elseif obj.ListType == ListMaker.LIST_TYPE_SIMPLE
                setAttribute(listEl,"columns","1");
                itemName = "member";
                isSimple = true;
            end
            
            if ~isSimple && ... %simple lists can not have a title
                    ~isempty(obj.ListTitle)
                titleEl =createElement( parentDocument,"title");
                
                if ~isempty(obj.ListTitleStyleName)
                    pi = createProcessingInstruction(parentDocument,"db2dom","style-name=" + obj.ListTitleStyleName);
                    appendChild(titleEl,pi);
                end
                
                appendChild(titleEl,createTextNode(parentDocument,obj.ListTitle));
                appendChild(listEl,titleEl);
            end
            
            if ~isempty(obj.ListStyleName)
                pi =createProcessingInstruction( parentDocument,"db2dom", "style-name=" +obj.ListStyleName);
                appendChild(listEl,pi);
            end
            
            itemEl = createElement(parentDocument,itemName);
            appendChild(listEl,itemEl);
            nItems = numel(obj.ListContent);
            for i=1:nItems
                if isa(obj.ListContent{i},'string')|| isa(obj.ListContent{i},'char')
                    addItemContent(obj,createTextNode(parentDocument,obj.ListContent{i}), ...
                        itemEl,isSimple);
                elseif isa(obj.ListContent{i},'matlab.io.xml.dom.Text')
                    addItemContent(obj,obj.ListContent{i},itemEl,isSimple);
                elseif isa(obj.ListContent{i},'matlab.io.xml.dom.Element') && ...
                        string(getTagName(obj.ListContent{i})) == "link"
                    %an Element inside listitem must be paragraph-level
                    %The only instance of Node passed to ListMaker I know of is <link>
                    addItemContent(obj,obj.ListContent{i},itemEl,isSimple);
                elseif isa(obj.ListContent{i},'matlab.io.xml.dom.Node')
                    %Note that this will miss a bad Element inside of a DocumentFragment
                    appendChild(itemEl,obj.ListContent{i});
                elseif isa(obj.ListContent{i},'cell')
                    appendChild(itemEl,makeNestedList(obj,obj.ListContent{i}, parentDocument));
                else
                    addItemContent(obj,createTextNode(parentDocument,rptgen.toString(obj.ListContent{i})), ....
                        itemEl,isSimple);
                end
                
                %If the next item is not an object array, create a new ListItem
                if i == nItems-1 || ...
                        (i < nItems && isa(obj.ListContent{i+1},'cell'))
                    %noop
                else
                    itemEl = createElement(parentDocument,itemName);
                    appendChild(listEl,itemEl);
                end
            end
        end
        
    end
    
    methods (Access=private)
        
        function nestedList = makeNestedList(obj,nestContent,parentDocument)
            import rptgen.internal.docbook.ListMaker
            oldListContent = obj.ListContent;
            oldListTitle   = obj.ListTitle;
            oldContType    = obj.ContinuationType;
           
            obj.ListContent = nestContent;
            obj.ListTitle  = [];
            obj.ContinuationType = ListMaker.CONTINUATION_TYPE_RESTARTS;
            
            nestedList = createList(obj,parentDocument);
            
            obj.ListContent = oldListContent;
            obj.ListTitle   = oldListTitle;
            obj.ContinuationType = oldContType;           
        end


        function itemContent = addItemContent(obj,itemContent,listItem,isSimple) %#ok<INUSL>
            % LISTITEM requires that its children be paragraph-level elements
            %
            % A SIMPLELIST MEMBER is OK with CDATA
            %
            % Wrap the Node with a PARA element if we are not creating a SIMPLELIST
            %
            % @param itemContent a node representing the content of the
            % @param listItem the LISTITEM or MEMBER element
            % @param isSimple whether or not we are making a SIMPLELIST
            % @return itemContent, wrapped if necessary
            if ~isSimple
                % We're only wrapping Text and <link> elements, so simple paragraph is ok here
                paraEl = createElement(listItem.getOwnerDocument(),"simpara");
                if paraEl.getOwnerDocument() ~= itemContent.getOwnerDocument()
                    itemContent = importNode(paraEl.getOwnerDocument(),itemContent,true); % make a deep copy
                end
                appendChild(paraEl,itemContent);
                itemContent = paraEl;
            end
            appendChild(listItem,itemContent);       
        end
    
    end
    
end




function tf = mustBeObjectOrEmpty(value,class)
if isempty(value)
    tf = true;
else
    if isa(value,class)
        tf = true;
    else
        tf = false;
    end
end
end

