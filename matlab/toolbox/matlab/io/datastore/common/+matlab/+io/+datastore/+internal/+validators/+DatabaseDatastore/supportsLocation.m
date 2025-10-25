function tf = supportsLocation(location)
%SUPPORTSLOCATION checks if location is a valid database connection
%object
%   SUPPORTSLOCATION(LOCATION) returns true if location is an
%   object of type database.jdbc.connection or database.odbc.connection; false
%   otherwise

    if isa(location, 'database.jdbc.connection') ...
            || isa(location, 'database.odbc.connection') ...
            || isa(location, 'database.mysql.connection') ...
            || isa(location,'database.postgre.connection')
        tf = true;
    else
        tf = false;
    end
end

