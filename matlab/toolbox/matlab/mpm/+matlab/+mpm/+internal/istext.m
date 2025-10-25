function tf = istext(input)
    tf = true;
    try
        mustBeText(input);
    catch
        tf = false;
    end
end