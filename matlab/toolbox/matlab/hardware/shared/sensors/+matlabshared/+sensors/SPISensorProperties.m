classdef (Hidden) SPISensorProperties < handle
    %Base class for SPI Interface

    %   Copyright 2023-2024 The MathWorks, Inc.

    %#codegen
    properties(SetAccess=protected)
        BitRate;
        SPIMode;
        BitOrder;
        SCLPin;
        SDIPin;
        SDOPin;
        Interface = 'SPI';
        SPIChipSelectPin;
    end
end
