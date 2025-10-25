function dbl = double(opaque_array)
%double Convert a Java object to a double array

%   Copyright 1984-2020 The MathWorks, Inc.

    % Use the builtin "double" for opaque types other than Java that do not
    % provide their own double method
    if ~isjava(opaque_array)
        dbl = builtin('double', opaque_array);
        return
    end


    %Convert opaque array to cell array to get the items in it.
    try
        cel = cell(opaque_array);
    catch  
        dbl = [];
        return
    end

    sz = size(cel);
    numCells = numel(cel);

    %An empty Java array becomes an empty double of matching dimensions.
    %Create the empty array and return
    if isempty(cel)
        dbl = double.empty(sz);
        return;
    end
    
    
    t = opaque_array(1);
    
    %If the input Java array is scalar and numeric, convert to double and 
    %return
    if isscalar(cel) && isnumeric(t)
        dbl = double(t);
        return;
    end
    
    %Index into the Java array until the first scalar value is found
    c = class(t);
    while contains(c, '[]')
        t = t(1);
        c = class(t);
    end
    
    dbl = zeros(sz);
    
    if isa(t,'java.lang.Number')  
        %The Java array is numeric or contains numeric values but is not  
        %scalar.  Convert each element to double and return.
        for i=1:numCells
            if isa(cel{i}, 'java.lang.Object')
                dbl(i) = doubleValue(cel{i});  %Will throw if no doubleValue method
            else
                dbl(i) = cel{i};
            end
        end
        return;
    end

    % If we have reached this point, the first element of the java array is
    % not a java.lang.Number.  Convert each value to double. For Java objects,
    % this will error if a toDouble method is not available for the given
    % object.
    if isscalar(cel)
        if isjava(opaque_array(1))
            dbl = toDouble(opaque_array(1));
        else
            dbl = double(opaque_array(1));
        end
    else
      for i = 1:numCells
          if isjava(cel{i})
              dbl(i) = toDouble(cel{i});
          else
              dbl(i) = cel{i};
          end
      end
    end   
  
end