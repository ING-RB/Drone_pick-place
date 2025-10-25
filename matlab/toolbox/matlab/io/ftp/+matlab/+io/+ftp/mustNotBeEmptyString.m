function mustNotBeEmptyString(str)
    if str == ""
        error(message("MATLAB:io:ftp:ftp:IncorrectInputArgumentForString"));
    end
end