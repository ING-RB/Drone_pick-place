classdef ReadType
    %ReadType Enum used in determining how to read metadata

    %   Copyright 2020-2023 The MathWorks, Inc.

    enumeration
        Nothing
        Package
        Class
        Function
        Mixed % A mix of the above
    end

end
