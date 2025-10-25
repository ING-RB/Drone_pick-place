classdef GraphicMaker < handle
    %GRAPHICMAKER Generate DocBook XML for a report imate
    %   An instance of this class generates the DocBook XML needed to
    %   include an image and its image map in a report.
    
    %   Copyright 2020 Mathworks, Inc.
    
    properties 
        ParentDocument {mustBeObjectOrEmpty(ParentDocument,'matlab.io.xml.dom.Document')} = [] 
        FileRef
        IsInline logical = false;
        Title {mustBeObjectOrEmpty(Title,'string')} = []
        Caption {mustBeObjectOrEmpty(Caption,'string')} = []
        Width {mustBeObjectOrEmpty(Width,'string')} = []
        Height {mustBeObjectOrEmpty(Height,'string')} = []
        ContentHeight {mustBeObjectOrEmpty(ContentHeight,'string')} = []
        ContentWidth {mustBeObjectOrEmpty(ContentWidth,'string')} = []
        Align {mustBeObjectOrEmpty(Align,'string')} = []
        ScaleFit {mustBeObjectOrEmpty(ScaleFit,'string')} = []
        AreaList {mustBeObjectOrEmpty(AreaList,'matlab.io.xml.dom.Element')} = []
        AreaIDPrefix {mustBeObjectOrEmpty(AreaIDPrefix,'string')} = []
        AreaIDCounter double = 0;
        CalloutList {mustBeObjectOrEmpty(CalloutList,'matlab.io.xml.dom.Element')} = []
        
    end
    
    methods
        function obj = GraphicMaker(parentDocument,fileReference)
            %GRAPHICMAKER Construct an instance of this class
            %   Detailed explanation goes here
            obj.ParentDocument = parentDocument;
            obj.FileRef = fileReference;
        end
        
        function setInline(obj,tf)
            obj.IsInline = tf;
        end
        
        function tf = getInline(obj)
            tf = obj.IsInline;
        end
        
        function setTitle(obj,title)
            if isempty(title)
                obj.Title = [];
            else
                if ~isa(title, 'matlab.io.xml.dom.Node')
                    node = createTextNode(obj.ParentDocument,title);
                end
                %@NOTE: perhaps should protect vs "foreign" nodes not
                %parented by obj.ParentDocument
                obj.Title = node;
            end
        end
        
        function title = getTitle(obj)
            title = obj.Title;
        end
        
        function setCaption(obj,cap)
            obj.Caption = cap;
        end
        
        function string = getCaption(obj)
            string = obj.Caption;
        end
        
        function setWidth(obj,w)
            if isa(w,'char') || isa(w,'string')
                obj.Width = w;
            else
                obj.Width = num2str(w);
            end
        end
        
        function str = getWidth(obj)
            str = obj.Width;
        end
        
        
        % Sets the DocBook "depth" image attribute.  (note name mismatch)
        function setHeight(obj,h)
            if isa(h,'char') || isa(h,'string')
                obj.Height = h;
            else
                obj.Height = int2str(h);
            end
        end
        
        function str = getHeight(obj)
            str = obj.Height;
        end
        
        % Sets the DocBook "contentdepth" image attribute.  (note name mismatch)
        
        function setContentHeight(obj,ch)
            if isa(ch,'char') || isa(ch,'string')
                obj.ContentHeight = ch;
            else
                obj.ContentHeight = int2str(ch);
            end
        end
        
        function str =  getContentHeight(obj)
            str = obj.ContentHeight;
        end
        
        function setContentWidth(obj,cw)
            if isa(cw,'char') || isa(cw,'string')
                obj.ContentWidth = cw;
            else
                obj.ContentWidth = int2str(cw);
            end
        end
        
        function str =  getContentWidth(obj)
            str = obj.ContentWidth;
        end
        
        
        % Alignment values can be 'auto' (none), 'left','center', and 'right'
        function setAlign(obj,a)
            if (~isempty(a) && ~strcmpi(char(a),'auto'))
                obj.Align = a;
            end
        end
        
        function str = getAlign(obj)
            str = obj.Align;
        end
        
        
        % Sets the DocBook "scalefit" image attribute.  Not using boolean to allow
        % "unset" to mean stylesheet default value
        function setScaleFit(obj,sf)
            if isa(sf,'char') || isa(sf,'string')
                obj.ScaleFit = sf;
            else
                obj.ScaleFit = int2str(sf);
            end
        end
        
        function str = getScaleFit(obj)
            str = obj.ScaleFit;
        end
        
        function result = addArea(obj,varargin)         
            switch nargin-1
                case 2
                    % id = addArea(obj,coords,linkends);
                    coords = varargin{1};
                    linkends = varargin{2};
                    nCoords = numel(coords);
                    if nCoords == 3
                        otherunits = "circle";
                    elseif nCoords == 4
                        otherunits = "rect";
                    else
                        otherunits = "polygon";
                    end
                    coordString="";
                    nCoordsMinusOne = nCoords-1;
                    for i=1:nCoordsMinusOne
                        coordString = coordString + num2str(coords(i)) + ",";
                    end
                    coordString = coordString + num2str(coords(nCoords));
                    result = addArea(obj,otherunits,coordString,linkends);
                case 3
                    % id = addArea(obj,otherunits,coords, linkends);
                    otherunits = varargin{1};
                    coords = varargin{2};
                    linkends = varargin{3};
                    if obj.AreaIDCounter == 0
                        unix_m4 = (now - datenum('01-Jan-1970'))*86400 + 4*3600;
                        unix_m4 = unix_m4 * 1000;
                        obj.AreaIDPrefix = num2str(unix_m4);
                    end
                    id = [obj.AreaIDPrefix  '-'  char(int2str(obj.AreaIDCounter))];
                    obj.AreaIDCounter = obj.AreaIDCounter+1;
                    addArea(obj,id,otherunits,coords,linkends);
                    result = id;
                case 4
                    % area = addArea(obj,id, otherunits, coords, linkends
                    id = varargin{1};
                    otherunits = varargin{2};
                    coords = varargin{3};
                    linkends = varargin{4};
                    area = createElement(obj.ParentDocument,"area");
                    setAttribute(area,"id",id);
                    setAttribute(area,"otherunits",otherunits);
                    setAttribute(area,"coords",coords);
                    setAttribute(area,"linkends",linkends);
                    if isempty(obj.AreaList)
                        obj.AreaList = createElement(obj.ParentDocument,"areaspec");
                    end
                    appendChild(obj.AreaList,area);
                    result = area;
                otherwise
                    error('GraphicMaker.addArea has invalid number of input arguments: %d', nargin-1);                  
            end
                    
        end
        
        
        % @param areaRef is a unique identifier to an <area>.  addArea(...) returns just such an areaRef
        % @param calloutNode is a Node which will be wrapped in a <para> element
        function addCallout(obj,areaRef,calloutText)
            if ~isempty(calloutText)
                if isa(calloutText, 'matlab.io.xml.dom.Node')
                    calloutNode = calloutText;
                else
                    calloutNode = createTextNode(obj.ParentDocument,calloutText);
                end
                
                if isempty(obj.CalloutList)
                    obj.CalloutList = createElement(obj.ParentDocument,"calloutlist");
                end
                
                paraEl = createElement(obj.ParentDocument,"para");
                appendChild(paraEl,calloutNode);
                
                calloutElement = createElement(obj.ParentDocument,"callout");
                if ~isempty(areaRef)
                    setAttribute(calloutElement,"arearefs",areaRef);
                end
                appendChild(calloutElement,paraEl);
                appendChild(obj.CalloutList,calloutElement);
            end
        end
        
        function node = createGraphic(obj)
            img = addImageObject(obj, '');
            
            if obj.IsInline && isempty(obj.Title)
                mo = createElement(obj.ParentDocument,'inlinemediaobject');
                appendChild(mo,img);
                if ~isempty(obj.Caption)
                    caption = createElement(obj.ParentDocument,'emphasis');
                    appendChild(caption,createTextNode(obj.ParentDocument,obj.Caption));
                    imageAndCaption = createDocumentFragment(obj.ParentDocument);
                    appendChild(imageAndCaption,mo);
                    appendChild(imageAndCaption,caption);
                    node = imageAndCaption;
                else
                    node = mo;
                end
            else
                
                %Test to see if mediaobject is ok with imageobjectco children
                %        if useCallouts
                %            mo = fParentDocument.createElement("mediaobjectco");
                %        else
                mo = createElement(obj.ParentDocument,'mediaobject');
                %        end
                appendChild(mo,img);
                if ~isempty(obj.Caption)
                    caption = createElement(obj.ParentDocument,'caption');
                    ctxt = rptgen.internal.docbook.StringImporter. ...
                        importHonorLineBreaksPara(obj.ParentDocument, ...
                        obj.Caption);
                    appendChild(caption, ctxt);
                    appendChild(mo,caption);
                end
                
                if ~isempty(obj.Title)
                    figureEl = createElement(obj.ParentDocument,'figure');
                    titleEl  = createElement(obj.ParentDocument,'title');
                    appendChild(titleEl,obj.Title);
                    appendChild(figureEl,titleEl);
                    figureEl.appendChild(mo);
                    node = figureEl;
                else
                    node = mo;
                end
            end
        end
    end
    
    methods (Access=private)
        
        
        function img = addImageObject(obj, role)
            if ~isempty(obj.FileRef)
                
                imgData = createElement(obj.ParentDocument,'imagedata');
                setAttribute(imgData,'fileref',obj.FileRef);
                if (endsWith(obj.FileRef,'svg') || endsWith(obj.FileRef,"svgz"))
                    % The HTML processor treats SVG images differently and needs to
                    % be instructed to act
                    setAttribute(imgData,"format","SVG");
                end
                obj.FileRef = [];
                
                if ~isempty(obj.ContentHeight)
                    setAttribute(imgData,"contentdepth",obj.ContentHeight);
                    obj.ContentHeight = [];
                end
                
                if ~isempty(obj.ContentWidth)
                    imgData.setAttribute("contentwidth",obj.ContentWidth);
                    obj.ContentWidth = [];
                end
                
                if ~isempty(obj.Height)
                    imgData.setAttribute("depth", obj.Height);
                    obj.Height = [];
                end
                
                if ~isempty(obj.Width)
                    imgData.setAttribute("width", obj.Width);
                    obj.Width = [];
                end
                
                if ~isempty(obj.Align)
                    imgData.setAttribute("align",obj.Align);
                    obj.Align = [];
                end
                
                if ~isempty(obj.ScaleFit)
                    imgData.setAttribute("scalefit",obj.ScaleFit);
                    obj.ScaleFit = [];
                end
                
                img = createElement(obj.ParentDocument,"imageobject");
                appendChild(img,imgData);
                
                if ~isempty(obj.AreaList)
                    imgCO = createElement(obj.ParentDocument,"imageobjectco");
                    appendChild(imgCO,obj.AreaList); % AreaSpec
                    appendChild(imgCO,img); % ImageObject
                    if ~isempty(obj.CalloutList)
                        appendChild(imgCO,obj.CalloutList); % CalloutList
                    end
                    img = imgCO;
                end
                if ~isempty(role)
                    %Could use this to create different images for different formats
                    setAttribute(img,'role',role);
                end
                
                %@TODO: could create a DocumentFragment which can contain multiple
                %imageobjects
            end
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

