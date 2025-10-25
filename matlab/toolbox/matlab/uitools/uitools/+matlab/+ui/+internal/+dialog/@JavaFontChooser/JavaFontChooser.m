
classdef JavaFontChooser < matlab.ui.internal.dialog.Dialog
    % This function is undocumented and will change in a future release.
    
    %   Copyright 2007-2020 The MathWorks, Inc.

    properties (SetAccess = immutable)
        %Title to be set on the dialog
        Title = getString(message('MATLAB:FontChooser:FontChooserDialogTitle'));
        %InitialFont refers to the font structure that gets applied to the dialog 
        InitialFont = struct('FontName','Arial',...
                   'FontSize',10,...
                   'FontUnits','points',...
                   'FontWeight','normal',...
                   'FontAngle','normal');
    end
    
    properties
       %SelectedFont refers to the font structure that is returned by
       %the dialog upon selection by clicking ok
       SelectedFont     
    end

      
    properties(Access = private, Dependent = true)     
        FontName;
        FontStyle; 
        FontSize;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Dependent property set&get methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function out = get.FontName(obj)
           out = obj.InitialFont.FontName;
        end
        function set.FontName(obj, v)
           obj.InitialFont.FontName = v;
        end
        
        function out = get.FontStyle(obj)
            out = convertToStyle(obj,obj.InitialFont.FontWeight,obj.InitialFont.FontAngle);
        end
        
        function set.FontStyle(obj, v)
            [obj.InitialFont.FontWeight,obj.Font.FontAngle] = convertFromStyle(obj,v);
        end
        
        function out = get.FontSize(obj)
            out = obj.InitialFont.FontSize;
        end
        function set.FontSize(obj, v)
            obj.InitialFont.FontSize = v;
        end  
    end
    
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Other set&get methods for other properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Constructor
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = JavaFontChooser(title, initialFont)
            arguments
                title {mustBeTextScalar} = '';
                initialFont = [];
            end
            
            % title  
            if ~isempty(title)
                obj.Title = title;
            end
            
            % initial font
            if ~isempty(initialFont)
                if (~isstruct(initialFont))
                    error(message('MATLAB:UiFontChooser:InvalidFont'));
                end

                % initialFont is a structure and we take those properties
                % we are interested in, namely
                % FontName, FontAngle, FontWeight, FontUnits and FontSize.
                % Populate InitialFont based only on the
                % fields supplied. Incomplete structs are also allowed.
                if isfield(initialFont,'FontName')
                    obj.InitialFont.FontName = initialFont.FontName;
                end
                if isfield(initialFont,'FontAngle')
                    obj.InitialFont.FontAngle = initialFont.FontAngle;
                end
                if isfield(initialFont,'FontWeight')
                    obj.InitialFont.FontWeight = initialFont.FontWeight;
                end
                if isfield(initialFont,'FontUnits')
                    obj.InitialFont.FontUnits = initialFont.FontUnits;
                end
                if isfield(initialFont,'FontSize')
                    validateattributes(initialFont.FontSize,{'numeric'}, {'finite','scalar','positive'}, 'uisetfont','''FontSize''');
                    obj.InitialFont.FontSize = initialFont.FontSize;
                end
            end

            obj.createPeer();
        end
        
        % The only member function to open the dialog and make a
        % selection
        function show(obj)
            setPeerTitle(obj,obj.Title);
            setPeerInitialFont(obj,obj.InitialFont);
            jSelectedFont = obj.Peer.showDialog([]);
            if ~isempty(jSelectedFont)
                [fontWeight,fontAngle] = convertFromStyle(obj,jSelectedFont.getStyle);
                jFontSize = com.mathworks.mwswing.FontSize.createFromJavaFont(jSelectedFont);
                obj.SelectedFont = struct('FontName',char(jSelectedFont.getName),...
                    'FontWeight',fontWeight,'FontAngle',fontAngle,'FontUnits','points',...
                    'FontSize', str2double(jFontSize.getDisplaySize()));                
            else
                obj.SelectedFont = [];
            end
        end
        % Member function to convert from style values[0..3] to a valid FontWeight
        % and FontAngle.
        function [fontWeight, fontAngle] = convertFromStyle(~,fontstyle)
            switch fontstyle
                case 0
                    fontWeight = 'normal';
                    fontAngle = 'normal';
                case 1
                    fontWeight = 'bold';
                    fontAngle = 'normal';
                case 2
                    fontWeight = 'normal';
                    fontAngle = 'italic';
                case 3
                    fontWeight = 'bold';
                    fontAngle = 'italic';
                otherwise
                    fontWeight = 'normal';
                    fontAngle = 'normal';

            end
        end
        % Member function to convert to style values given strings
        % FontWeight and FontAngle.
        function fontStyle = convertToStyle(~,fontWeight,fontAngle)
            switch [lower(fontWeight),lower(fontAngle)]
                case ['normal','normal']
                    fontStyle = 0;
                case ['bold','normal']
                    fontStyle = 1;
                case ['normal','italic']
                    fontStyle = 2;
                case ['bold','italic']
                    fontStyle = 3;
                otherwise
                    fontStyle = 0;
            end
            
        end
        
    end
    
    methods(Access = 'private')
        % Create a java peer object -com.mathworks.widgets.fonts.FontDialog
        function createPeer(obj)
            if ~isempty(obj.Peer)
                delete(obj.Peer);
            end
            obj.Peer = handle(javaObjectEDT('com.mathworks.widgets.fonts.FontDialog',obj.Title),'callbackproperties');
            matlabFonts = listfonts;
            javaFontList = javaArray('java.lang.String', length(matlabFonts));
            for k = 1:length(matlabFonts)
                javaFontList(k) = java.lang.String(matlabFonts{k});                
            end 
            obj.Peer.setFontNames(javaFontList);
        end
        % Pass the InitialFont property From the MCOS object to the
        % java object
        function setPeerInitialFont(obj,v)
            if ~isstruct(v)
                error(message('MATLAB:UiFontChooser:InvalidInitialFont'));
            end
            % Use font converter utility in an attempt to get a valid font name
            % This will help UI fonts to some extent. 
            jFont = com.mathworks.hg.util.FontConverter.convertToJavaFont(obj.FontName, obj.FontSize, obj.FontStyle, obj.FontStyle);
            javaFontName = jFont.getName();
            % Use Font Size conversion utility to get the Java Point Size
            jFontSize = com.mathworks.mwswing.FontSize.createFromPointSize(obj.FontSize);
            javaFontSize = jFontSize.getJavaSize();
            
            % Apply Java font to peer
            javaFont = java.awt.Font(javaFontName, obj.FontStyle, javaFontSize);
            obj.Peer.setSelectedFont(javaFont);
        end
    end
    
    methods(Access='protected')
         % Pass the Title property from the MCOS object to the java
        % object.
        function setPeerTitle(obj,v)
            if ~ischar(v)
                error(message('MATLAB:UiFontChooser:InvalidTitleType'));
            end
            obj.Peer.setTitle(v);
        end 
    end
            
    
end
