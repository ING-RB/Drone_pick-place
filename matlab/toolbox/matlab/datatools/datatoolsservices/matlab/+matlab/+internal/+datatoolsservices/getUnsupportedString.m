function out = getUnsupportedString(val)
    % Returns the 'disp' version of a variable, as it is shown in the
    % Unsupported view of the Variable Editor if it contains less than
    % maxElements, otherwise returns a message indicating it is over the limit
    % for display.
    %
    % This is a copy of the long standing function in arrayviewfunc.
    % Repeating here since arrayviewfunc will be deprecated.
    
    % Copyright 2020 The MathWorks, Inc.

    % Max number of elements to display
    maxElements = 2^19;
    out = [];
    
    if isa(val, 'tall')
        % Special treatment for tall variables, so that the contents shows up
        % better than it would be default, since the unsupported view strips
        % lines with hyperlinks in it.
        out = evalc(['oldVal = feature(''hotlinks'', false);', ...
            'restore = onCleanup(@() feature(''hotlinks'', oldVal));', ...
            'display(val)']);
        
        % Remove hyperlinks so that the Nx1 tall column vector string shows up
        out = regexprep(out, '<.*?>', '');
    elseif numel(val) > maxElements || length(size(val)) > maxElements
        % Either there are too many elements, or too many dimentions to try to
        % display in the Variable Editor
        tooLargeMessage = message("MATLAB:datatools:workspaceFunctions:StatusTooLarge", maxElements); %#ok<*NASGU>
        out = evalc('disp(tooLargeMessage.getString)');
    else
        try
            out = evalc('display(val)');
            out = strrep(strrep(out, '<strong>', ''), '</strong>', '');
        catch ex
            % catch any exceptions in the display call.  This can happen if you
            % have errors in a class file for which you have a variabe of open
            % in the Variable Editor
        end
    end
    
    if isempty(out)
        % There was an error from above, return an error message
        cannotReferenceMessage = message("MATLAB:datatools:workspaceFunctions:StatusCannotReference");
        out = evalc('disp(cannotReferenceMessage.getString)');
    end
end
