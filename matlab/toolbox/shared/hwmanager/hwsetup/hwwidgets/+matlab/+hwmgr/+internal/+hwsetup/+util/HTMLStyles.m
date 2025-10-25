classdef HTMLStyles < handle
    %matlab.hwmgr.internal.hwsetup.util.HTMLStyles is a class that applies
    %HTML styling to the given content. The api's accept text to be
    %formatted and return the styled text.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    methods(Static)
        function formattedText = applyHeaderStyle(text)
            %applyHeaderStyle- Translates the text style from h1 tag to 
            %use bold blue header text.
            
            h1Style = '<h1 style="color:var(--mw-color-list-primary);font-weight:bold;margin-bottom:5px;">';
            formattedText = strrep(text, '<h1>', h1Style);
        end

        function formattedText = applyErrorStyle(text)
            %applyErrorStyle- Translates the text style from h6 tag to
            %use red error text.
            
            h6Style = '<h6 style="color:var(--mw-color-error);">';
            formattedText = strrep(text, '<h6>', h6Style);
            
            %g2314193 removed support for span tag. We replace it with b.
            formattedText = strrep(formattedText, '<span', '<b');
            formattedText = strrep(formattedText,...
                'class="hwsetup_error"', 'style="color:var(--mw-color-error);"');
            formattedText = strrep(formattedText, '</span', '</b');
        end
        
        function formattedText = applyWarningStyle(text)
            %applyWarningStyle- Translates the text style from warning
            %css class to orange text
            
            %g2314193 removed support for span tag. We replace it with b.
            formattedText = strrep(text, '<span', '<b');
            formattedText = strrep(formattedText,...
                'class="hwsetup_warn"', 'style="color:orange;"');
            formattedText = strrep(formattedText, '</span', '</b');
        end
    end
end