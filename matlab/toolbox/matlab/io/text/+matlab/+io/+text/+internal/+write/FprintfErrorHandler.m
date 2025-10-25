function FprintfErrorHandler(fid, fileName, errNum)
%FPRINTFERRORHANDLER Close and delete the file, throw appropriate error

% Copyright 2021-2022 The MathWorks, Inc.

    % close the file
    fclose(fid);
    % delete the file
    delete(fileName);
    % use the error number to throw appropriate error
    switch(abs(errNum))
      case 5
        error(message("MATLAB:FileIO:IsOpenWrite"));
      case 6
        error(message("MATLAB:printf:OutOfSpace", fileName));
      case 7
        error(message("MATLAB:FileIO:FlushError"));
      case 8
        error(message("MATLAB:FileIO:InvalidFormat"));
      case 9
        error(message("MATLAB:FileIO:MatchingFailure"));
      case 10
        error(message("MATLAB:FileIO:SizeTooBig"));
      case 11
        error(message("MATLAB:FileIO:NoMemory"));
      case 12
        error(message("MATLAB:FileIO:NoMemoryForString"));
      case 13
        error(message("MATLAB:FileIO:NotEnoughArgs"));
      case 14
        error(message("MATLAB:FileIO:UnsupportedDirective"));
      case 15
        error(message("MATLAB:FileIO:BadWidthNaN"));
      case 16
        error(message("MATLAB:FileIO:BadWidthNegInf"));
      case 17
        error(message("MATLAB:FileIO:BadWidthInf"));
      case 18
        error(message("MATLAB:FileIO:BadWidthInt"));
      case 19
        error(message("MATLAB:FileIO:BadWidthEmptyArg"));
      case 31
        error(message("MATLAB:FileIO:WriteCarryByteFailed"));
      otherwise
        error(message("MATLAB:FileIO:UnknownError"));
    end
end