classdef HelpTextWrapper < ...
        matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTextComponentWrapper
    %This class is undocumented and may change in a future release.
    
    %HELPTEXTWRAPPER - This class acts as a wrapper for HelpText widget
    %constructed using UI Components. This hides some of the implementation
    %quirkiness around managing tables.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties
        AboutSelection
        Additional
        WhatToConsider
    end
    
    properties(Constant)
        FontSize = 11;
    end
    
    methods
        function obj = HelpTextWrapper(varargin)
            obj@matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTextComponentWrapper(varargin{:});

            containerChildren = obj.ContainerComponent.Children;
            set(containerChildren, 'Padding', 8);
            set(obj.LabelComponent, 'FontSize', obj.FontSize);
            matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(containerChildren,...
                'BackgroundColor', matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorAnnouncementBanner);
            
            %Fix for help text getting clipped off in case of unspaced
            %text(Overrides values in HTMLTextComponentWrpper) for g2986652.
            gridLayout = obj.LabelComponent.Parent;
            gridLayout.RowHeight = {'1x'};
            gridLayout.ColumnWidth = {'1x'};
        end
        
        function formatTextForDisplay(obj)
            %formatTextForDisplay - formats/styles the text for a HelpText
            %header and its content section.
            
            import matlab.hwmgr.internal.hwsetup.util.*;
            
            beginSection = '<div>';
            endSection = '</div>';
            beginHeader = '<h1>';
            endHeader = '</h1>';
            beginContent = '<b style="font-weight:normal;line-height:1.5;">';
            endContent = '</b>';
            separator = '<br>';
            
            h1 = message('hwsetup:widget:HelpTextAboutSelectionHeader').getString();
            h2 = message('hwsetup:widget:HelpTextWhatToConsiderHeader').getString();
            
            %AboutSelection
            formattedText = '';
            if ~isempty(char(obj.AboutSelection))
                header = [beginHeader, h1, endHeader];
                content = [beginContent, obj.AboutSelection, endContent];
                formattedText = [beginSection, header, content, endSection];
            end
            
            %WhatToConsider
            if ~isempty(char(obj.WhatToConsider))
                %add separator only if AboutSelection is displayed
                if ~isempty(char(obj.AboutSelection))
                    beginSection = [separator separator beginSection];
                end
                header = [beginHeader, h2, endHeader];
                content = [beginContent, obj.WhatToConsider, endContent];
                formattedText = [formattedText, beginSection, header, content, endSection];
            end
            
            %Additional
            if ~isempty(char(obj.Additional))
                %add separator only if AboutSelection or WhatToConsider is displayed
                if ~isempty(char(obj.AboutSelection)) ||...
                        ~isempty(char(obj.WhatToConsider))
                    beginSection = [separator beginSection];
                end
                content = [beginContent, obj.Additional, endContent];
                formattedText = [formattedText, beginSection, content, endSection];
            end
            
            formattedText = HTMLStyles.applyErrorStyle(formattedText);
            formattedText = HTMLStyles.applyHeaderStyle(formattedText);
            formattedText = HTMLStyles.applyWarningStyle(formattedText);
            
            obj.LabelComponent.Text = char(join(formattedText, ''));
        end
    end
    
    %----------------------------------------------------------------------
    % setter methods
    %----------------------------------------------------------------------
    methods
        function set.AboutSelection(obj, value)
            obj.AboutSelection = value;
            obj.formatTextForDisplay();
        end
        
        function set.Additional(obj, value)
            obj.Additional = value;
            obj.formatTextForDisplay();
        end
        
        function set.WhatToConsider(obj, value)
            obj.WhatToConsider = value;
            obj.formatTextForDisplay();
        end
    end
end