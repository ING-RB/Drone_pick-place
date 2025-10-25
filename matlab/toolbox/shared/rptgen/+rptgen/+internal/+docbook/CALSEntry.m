classdef CALSEntry < handle
    %CALSENTRY Defines a table entry
    %   This class defines an XML table entry based on the CALS table
    %   model.
    
    %   Copyright 2020 Mathworks, Inc.
    
    properties (Constant)
        ALIGN_LEFT string    = "Left"
        ALIGN_CENTER string  = "Center"
        ALIGN_RIGHT string   = "Right"
        ALIGN_JUSTIFY string = "Justify"
        ALIGN_CHAR string    = "Char"
        VALIGN_TOP string    = "Top"
        VALIGN_MIDDLE string = "Middle"
        VALIGN_BOTTOM string = "Bottom"
    end
    
    properties
        Align
        VAlign
        Rotate
        ColSep
        RowSep
        MoreRows
        ColSpanStart
        ColSpanEnd
    end
    
    properties (Access=private)
        Impl  
    end
    
    methods
        
        function init(obj, ownerDoc, content)
            obj.Impl = createElement(ownerDoc, 'entry');
            if nargin == 3
                if isa(content,'char') || isa(content,'string')
                    node = createTextNode(ownerDoc,content);
                else
                    if isa(content,'matlab.io.xml.dom.Node')
                        node = content;
                    else
                        error('Invalid CALSEntry type: "%s"',content);
                    end
                end
                appendChild(obj,node);
            end
        end
        
        function impl = getImpl(obj) 
            impl = obj.Impl;
        end
        
        function appendChild(obj, child)
            appendChild(obj.Impl, child);
        end
               
        function setAlign(obj,alignVal)
            %  Align controls the horizontal position of text within the
            %  column. The value of Align may be Left (quad flush left),
            %  Center (centered), Right (quad flush right), Justify (both
            %  quad left and right), or Char (align to the left of Char,
            %  positioned by Charoff). There is no default except for
            %  SpanSpec, where the default is Center. For Entry and
            %  EntryTbl, the value may be inherited from ColSpec or
            %  SpanSpec.
            setAttribute(obj.Impl,"align",alignVal);
        end
        
        function align = getAlign(obj)
            align = getStringAttribute(obj,"align",obj.ALIGN_LEFT);
        end
        
        function set.Align(obj,val)
            setAttribute(obj,"align",val);
        end
        
        function val = get.Align(obj)
            val = getStringAttribute(obj,"align",obj.ALIGN_LEFT);
        end        
 
        function  setVAlign(obj,alignVal)
            % VAlign governs the vertical positioning of text within an Entry.
            % Allowed values are Top, Middle, and Bottom (no default).
            setAttribute(obj.Impl,"valign",alignVal);
        end
        
        function set.VAlign(obj,val)
            setVAlign(obj,val);
        end
       
        function valign = getVAlign(obj) 
            valign = getStringAttribute(obj,"valign",obj.VALIGN_TOP);
        end
        
        function val = get.VAlign(obj)
            val = getVAlign(obj);
        end
        
        function setRotate(obj,rotateVal)
            % Rotate governs rotations, which are not additive to those specified
            % in the FOSI. Values may be 1 (yes) or 0 (no).
            % 0 (no) specifies no rotation; 1 (yes) specifies 90 degrees rotation
            % counterclockwise to table orientation. No other values are supported!          
            setBooleanAttribute(obj,"rotate",rotateVal);
        end
        
        function set.Rotate(obj,val)
            setRotate(obj,val);
        end
      
        function tf = getRotate(obj)
            tf = getBooleanAttribute(obj,"rotate",false);
        end
        
        function val = get.Rotate(obj)
            val = getRotate(obj);
        end

        function setColsep(obj,colsepVal)
            % Colsep controls the occurance of vertical rules between table columns.
            % A value of 1 (yes) specifies that a rule should occur.
            % A value of 0 (no) specifies that it should not.
            % Colsep is inherited from enclosing table elements.
            setBooleanAttribute(obj,"colsep",colsepVal);
        end
        
        function set.ColSep(obj,val)
            setColsep(obj,val);
        end
     
        function tf = getColsep(obj)
            tf = getBooleanAttribute(obj,"colsep",true);
        end  
        
        function val = get.ColSep(obj)
            val = getColsep(obj);
        end
          
        function setRowsep(obj,rowsepVal)
            % Rowsep controls the occurance of horizontal rules between 
            % table rows. A value of 1 (yes) specifies that a rule should 
            % occur. A value of 0 (no) specifies that it should not.
            % Rowsep is inherited from enclosing table elements.
            setBooleanAttribute(obj,"rowsep",rowsepVal);
        end
        
        function set.RowSep(obj,val)
            setRowsep(obj,val);
        end
     
        function tf = getRowsep(obj)
            tf = getBooleanAttribute(obj,"rowsep",true);
        end   
        
        function val = get.RowSep(obj)
            val = getRowsep(obj);
        end

        function setMoreRows(obj,numRows)
            % MoreRows indicates how many more rows, in addition to the
            % current row, this Entry is to occupy. It creates a vertical
            % span. The default of 0 indicates that the Entry occupies 
            % only a single row.
            if numRows <= 0
                removeAttribute(obj.Impl,"morerows");
            else
                setAttribute(obj.Impl,"morerows",int2str(numRows));
            end
        end
         
        function set.MoreRows(obj,val)
            setMoreRows(obj,val);            
        end
    
        function val = getMoreRows(obj)
            val = getAttribute(obj.Impl,"morerows");
            val = str2double(val);
            if isnan(val)
                val = 0;
            end
        end
        
        function val = get.MoreRows(obj)
            val = getMoreRows(obj);
        end
        
        function set.ColSpanStart(obj,val)
            setAttribute(obj.Impl,"namest",int2str(val));
        end
        
        function val = get.ColSpanStart(obj)
            val = getAttribute(obj.Impl,"namest");
        end
        
        function set.ColSpanEnd(obj,val)
            setAttribute(obj.Impl,"nameend",int2str(val));
        end
        
        function val = get.ColSpanEnd(obj)
            val = getAttribute(obj.Impl,"nameend");
        end

        function setColSpan(obj,startCol,endCol)
            obj.ColSpanStart = startCol;
            obj.ColSpanEnd = endCol;
        end
  
    end
    
    methods (Access=private)    
        function attr = getStringAttribute(obj,attributeName,defaultValue)
            % Returns attribute value if it is defined.
            % Returns default value if not.
            if hasAttribute(obj.Impl,attributeName)
                attr = getAttribute(obj.Impl,attributeName);
            else
                attr = defaultValue;           
            end
        end
    
        function setBooleanAttribute(obj,attributeName,val)
            % Sets an attribute with value "0" or "1" appropriately
            if (val)
                setAttribute(obj.Impl,attributeName,"1");
            else
                setAttribute(obj.Impl,attributeName,"0");
            end
        end
        

        function tf = getBooleanAttribute(obj,attributeName,defaultValue)
            % Returns true if attribute value is "1"
            % Returns false if attribute value is "0"
            % Returns default value if attribute not defined
            if hasAttribute(obj.Impl,attributeName)
                tf = strcmp(getAttribute(obj.Impl,attributeName),'1');
            else
                tf = defaultValue;
            end
        end
        
     
    end

end

