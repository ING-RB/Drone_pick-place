classdef InertiaUnitsEnumType

    properties
        value
    end

    enumeration
        kgm2 ("kg*m^2")
        gcm2 ("g*cm^2")
        slugft2 ("slug*ft^2")
        slugin2 ("slug*in^2")
        lbft2 ("lb*ft^2")
        lbin2 ("lb*in^2")
    end

    methods
        function this = InertiaUnitsEnumType(value)
            this.value = value;
        end
    end
end