function isValidName = ValidateNamespaceAndFunctionClass(name)
    %this regular expression returns the indices of every character in the
    %passed in name that is a letter, a number, or an underscore.
    isValidName =  regexp(name,"\w*");
    isValidName = (length(isValidName) == length(name));
end

