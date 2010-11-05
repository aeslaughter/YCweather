function out = calcwx_labLW(d,varargin)
% CALCFLUX calculates the radiation flux for absorbed shortwave, net
% longwave, latent, and sensible heat at the snow surface%
%__________________________________________________________________________
%
%__________________________________________________________________________

% 1 - READ THE CALCULATION TYPE
    n = length(varargin);
    type = varargin{n};

% 2 - READ THE DATA FROM THE STRUCTURE, CONVERTING TO STRINGS
    for i = 1:n-1;  in{i} = d.(varargin{i}).data; end
  
% 3 - ESTABLISH THE EQUATION CONSTANTS AND VARIABLES
    switch type
        case 'eppley';
            c1 = 0.0010295; c2 = 0.0002391; c3 = 0.0000001568; s = 0.00431;        
        case 'kz';
            c1 = 0.00103; c2 = 0.000239; c3 = 0.000000157; s = 11.83E-6;   
    end

% 4 - CALCULATE THE LONGWAVE RADIATION
    V  = in{1};    R = log(in{2});   sb = 5.6697e-8;
    T  = 1./(c1 + c2.*R + c3.*R.*R.*R);
    LW = V./s + sb.*T.*T.*T.*T;

% 5 - RETURN THE NEW STRUCTURE ARRAY
    out.data    = LW;
    out.display = 1;
    out.unit    = 'W/m^2';
    out.label   = 'Longwave (from Raw Data)';
    