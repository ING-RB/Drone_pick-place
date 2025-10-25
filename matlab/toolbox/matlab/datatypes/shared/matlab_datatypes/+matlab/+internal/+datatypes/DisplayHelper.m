classdef DisplayHelper < matlab.mixin.CustomDisplay & matlab.mixin.internal.Scalar & handle
%DISPLAYHELPER Utility class to override the default display of CustomDisplay property groups.

%   Copyright 2016-2020 The MathWorks, Inc.

    properties
        % Override Property for Footer - Is displayed at the end of the
        % object display. (There is no default footer)
        Footer = '';
        % Override Property for Header - Is displayed instead of the
        % default custom display header 
        Header = '';
        ClassName;
    end
    
    properties (Access = private)
        PropertyGroups = matlab.mixin.util.PropertyGroup.empty;
        text_;
    end
    
    properties (Dependent)
        ShortClassName
    end
    
    methods
        function obj = DisplayHelper(classname)
        % DISPLAYHELPER create a display helper object
            obj.ClassName = classname;
        end
        
        function addPropertyGroupNoTitle(obj,printobj,props)
            %ADDPROPERTYGROUPNOTITLE add a property group without a title
            % See Also, addPropertyGroup
            if nargin < 3 && isstruct(printobj)
                gr = printobj;
            else
                gr = props2struct(printobj,props);
            end
            obj.PropertyGroups(end+1) = matlab.mixin.util.PropertyGroup(gr,'');
            obj.text_ = getDisplayText(obj,inputname(1));
        end
        
        function addPropertyGroup(obj,title,printobj,props)
        %ADDPROPERTYGROUP add a property group with a title
        % addPropertyGroup(obj,title,printobj,props) adds a section in the
        % display with a title. This group will display "TITLE Properties:"
        % before the group. The group will display the properties in PROP
        % from the object or struct PRINTOBJ. 
        % 
        % obj.addPropertyGroup('Title', A, {'Prop1','Prop2'}) will look like:
        % 
        %   Title Properties:
        %     Prop1: disp(A.Prop1)
        %     Prop2: disp(A.Prop2)
            title = convertStringsToChars(title);
            if nargin < 4 && isstruct(printobj)
                gr = printobj;
            else
                gr = props2struct(printobj,props);
            end
            obj.PropertyGroups(end+1) = matlab.mixin.util.PropertyGroup(gr, ...
                [title ' ' getString(message('MATLAB:textio:importOptionsProperties:Properties'))]);
            obj.text_ = getDisplayText(obj,inputname(1));
        end
        
        function addPropertyGroupCustomTitle(obj,title,printobj,props)
        %ADDPROPERTYGROUP add a property group with a title
        % addPropertyGroup(obj,title,printobj,props) adds a section in the
        % display with a title. This group will display "TITLE Properties:"
        % before the group. The group will display the properties in PROP
        % from the object or struct PRINTOBJ. 
        % 
        % obj.addPropertyGroup('Custom Title', A, {'Prop1','Prop2'}) will look like:
        % 
        %   Custom Title:
        %     Prop1: disp(A.Prop1)
        %     Prop2: disp(A.Prop2)
            if nargin < 3 && isstruct(printobj)
                gr = printobj;
            else
                gr = props2struct(printobj,props);
            end
            obj.PropertyGroups(end+1) = matlab.mixin.util.PropertyGroup(gr, ...
                title);
            obj.text_ = getDisplayText(obj,inputname(1));
        end
        
        
        
        function clearPropertyGroups(obj)
        %CLEARPROPERTYGROUPS Remove all the property groups
        % useful for prototyping display.
            obj.PropertyGroups = matlab.mixin.util.PropertyGroup.empty;
            obj.text_ = getDisplayText(obj,inputname(1));
        end
        
        function text = getDisplayText(obj,name)
        %GETDISPLAYTEXT get the raw text to be displayed
        % Get the display text for inspection or augmentation
            if nargin == 1
                name = inputname(1);
            end
            text = string(split(evalc('display(obj)'),newline)) + newline;
            text(1 + obj.isloose) = name + " = " + newline;
            text(end) = [];
            obj.text_ = text;
        end
        
        function replacePropDisp(obj, propName, newval)
        %REPLACEPROPDISP replace the display of a property
        % Use this to print a customer display e.g. contents of a cell
        % array.
            t = obj.text_;
            idx = startsWith(t.strip, propName + ": ");
            t(idx) = t(idx).replaceBetween(": ",newline,newval);
            obj.text_ = t;
        end
        
        function appendPropDisp(obj, propName, newval)
        %APPENDPROPDISP add text at the end of a property display
        % This can be used to add trailing information after the display.
        % e.g. 
        %   MemoryInUse: 35 (Gigabytes)
        %
            t = obj.text_;
            idx = startsWith(t.strip, propName + ":");
            t(idx) = t(idx).insertBefore(newline," " + newval);
            obj.text_ = t;
        end
        
        function prependPropNameDisp(obj, propName, prefix)
        %PREPENDPROPNAMEDISP add text before the property name
            t = obj.text_;
            idx = startsWith(t.strip, propName + ": ");
            
            t(idx) = t(idx).insertBefore(propName+": ",prefix);
            first_non_space = find(~isspace(t(idx)),1);
            if first_non_space > strlength(prefix) + 2
                t(idx) = extractAfter(t(idx), strlength(prefix));
            end
            obj.text_ = t;
        end
              
        function val = get.ShortClassName(obj)
            parts = split(obj.ClassName,'.');
            val = parts{end};
        end
        
        function printToScreen(obj,name,printVarLine)
        %PRINTTOSCREEN prints the display to screen
            if nargin == 1
                name = inputname(1);
            end
            
            if isempty(obj.text_) % get the default display if not already populated.
                obj.text_ = getDisplayText(obj,name);
            end
            
            t = obj.text_;
            
            if ~(obj.usingHotlinks)
                t = replaceBetween(t,"<a",obj.ShortClassName + "</a>",obj.ShortClassName,"Boundaries","inclusive");
            end
                
            if ~printVarLine % Omit the "var =" line when printing as part of a disp method
                t(logical(obj.isloose*[1 1])) = [];
                t(1) = [];
            end
            
            if ~(obj.isloose) % remove lines which are only whitespace.
                t((t.replace(" ","").replace(char(9),"")) == newline) = [];
            end
            
            fprintf(1,'%s',t);
           
        end
    end
    
    methods (Static)
        function link = propDisplayLink(objname,propname)
        %PROPDISPLAYLINK get a link for displaying a property
            objname = convertStringsToChars(objname);
            msg = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureMissingVariable', objname));
            codeToExecute = sprintf(['if exist(''' objname ''',''var''),%%s,else,fprintf(''%s\\\\n'');end'], msg);
            codeToExecute = sprintf(codeToExecute,"fprintf('" + objname + "." + propname + " = \n\n');display(" + objname + "." + propname + ")");
            link = sprintf('<a href="matlab:%s" style="font-weight:bold">%s</a>', codeToExecute, propname);
        end
        
        function helpLink = helpTextLink(helptopic,fullhelpaddress)
        %HELPTEXTLINK get the help popup link 
            if matlab.internal.datatypes.DisplayHelper.usingHotlinks()
                helpLink = sprintf('<a href="matlab:helpPopup %s">%s</a>',fullhelpaddress,helptopic);
            else
                helpLink = helptopic;
            end
        end
        
        function tf = usingHotlinks()
        %USINGHOTLINKS returns whether the display is using hotlinks
            tf = matlab.internal.display.isHot();
        end
        
        function tf = isloose()
        %ISLOOSE returns the format spacing property
            tf = (matlab.internal.display.formatSpacing == "loose");
        end
       
    end
    
    methods (Sealed, Access = protected)
        function propgrp = getPropertyGroups(obj)
            propgrp = obj.PropertyGroups;
        end
        
        function h = getHeader(obj)
            if isempty(obj.Header)
                h = obj.getHeader@matlab.mixin.CustomDisplay();
                replacename = obj.ClassName;
                h = replace(h,'matlab.internal.datatypes.DisplayHelper',replacename);
                h = replace(h,'DisplayHelper',obj.ShortClassName);
            else
                h = obj.Header;
            end
        end
        
        function f = getFooter(obj)
        	f = obj.Footer;
        end
    end
end

function gr = props2struct(obj,props)
    gr = struct();
    for i = 1:numel(props)
        gr.(props{i}) = obj.(props{i});
    end
end

