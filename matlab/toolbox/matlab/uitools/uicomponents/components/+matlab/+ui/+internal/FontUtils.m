classdef FontUtils 
    % Font processing methods to be used by components
    % Currently almost all font processing is done on the client
    % fixed width font is the exception because it requires the value from
    % groot
    methods(Static)
        % Helper function to process fonts for the view

        function newFont = getFontForView(value)
            %fixedwidth font uses FixedWidthFontName from groot. 
            if strcmpi(value,'fixedwidth')
                rootValue = get(0,'FixedWidthFontName');
                newFont = rootValue;
            else
                newFont = value;
            end
        end
    end
end