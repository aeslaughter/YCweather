function out = calcwx_flux(d,varargin)
% CALCWX_FLUX calculates the fluxes and related properties for YCweather
%__________________________________________________________________________
% USAGE: [X] = calcFLUX(d,varargin)
%
% INPUT:
%   d = data structure used by YCweather for storing data for a station
%   varargin = data necessary to make the desired calculation
%   varargin(length(varargin)) = tag for identifing calculation
%
% OUTPUT:
%   out = structure array containing the new calculated data
%
% PROGRAM OUTLINE:
%   1 - GATHER THE INPUT 
%   2 - FLUX CALCULATIONS  
%   3 - RETURN THE NEW STRUCTURE ARRAY
%
% FUNCTIONS CALLED: none
%__________________________________________________________________________

%   1 - GATHER THE INPUT
    n = length(varargin);
    type = varargin{n};
    for i = 1:n-1;  
        input = varargin{i};

    % 1.1 - Case when data if contained
        if isfield(d,varargin{i});
            in{i} = d.(varargin{i}).data;

    % 1.2 - Case when a constant is desired
        elseif isnumeric(str2double(input));
            in{i} = str2double(varargin{i});

    % 1.3 - Input error
        else
            disp('Error with input to calcwx_flux...'); return;
        end
    end

% 2 - FLUX CALCULATIONS
switch type
    % 2.1 - Outgoing and net longwave
    case {'LWout','longwave'}
        LWin = in{1};            % Incoming longwave (W/m2)
        Ts   = in{2};            % Temp. of snow (C)
        emis = 0.95;             % Emissivity of snow 
        sb   = 5.670 * 10^-8;    % Stefan-Boltzmann constant (W/m^2/K^4)
        unit = 'W/m^2';          % Flux units 
       
        if strcmpi(type,'LWout') 
            Ts = Ts + 273.15;
            FLUX = emis*sb.*Ts.*Ts.*Ts.*Ts;
            name = 'Flux: Outgoing Longwave';
        else 
            Ts = Ts + 273.15;
            FLUX = LWin - emis*sb.*Ts.*Ts.*Ts.*Ts;
            name = 'Flux: Net Longwave';
        end

    % 2.2 - Shortwave raditation 
     case 'shortwave'
        SWin = in{1};           % Incoming shortwave (W/m^2)
        SWout = in{2};          % Reflected shortwave (W/m^2)

        FLUX = SWin - SWout;
        name = 'Flux: Net Shortwave';
        unit    = 'W/m^2';
     
    % 2.3 - Sensibile heat
    case 'sensible'
        % 2.3.1 - Collect input
            Vw = in{1};             % Wind velocity (m/s)
            Ta = in{2}+273.15;      % Air temp. (K)
            Ts = in{3}+273.15;      % Snow temp. (K)
        
        % 2.3.2 - Calcute the density of air
            R       = 0.287;         % Gas constant for air (kJ/kg*K)
            Patm    = 72.4;          % Atmosphiric pressure (kPa) @9000 ft
            rho_air = Patm./(R.*Ta); % Density of air (kg/m^3)      
   
        % 2.3.3 - Calculate specific heat of air 
            Cpd = [1003, 1003, 1005, 1008];  % Heat Capacity of Air(J/kg*K)
            Tr = [200, 250, 300, 350];       % Reference Temp for curve fit (K)   
            Cp_air = interp1(Tr,Cpd,Ta,'pchip');
  
        % 2.3.4 - Find sensible heat flux
            Kh   = 0.0023;            % Turbulent transfer coefficient
            FLUX = rho_air.*Cp_air.*Kh.*Vw.*(Ta - Ts);
            name = 'Flux: Sensible Heat';
            unit    = 'W/m^2';
        
    % 2.4 - Latent heat
    case {'latent','RHsnow'}
        % 2.4.1 - Collect ionput
            Vw = in{1};             % Wind velocity (m/s)
            Ta = in{2}+273.15;      % Air temp. (C)
            Ts = in{3}+273.15;      % Snow temp. (C)
            RH = in{4};             % Relative humidity of air (%)
      
        % 2.4.2 - Set constants
            Ls = 2833;              % Latent heat of sublimation (kJ/kg)
            Ke = 0.0023;            % Turbulent heat tranfser coefficent 
            Patm = 72.4;            % Atmospheric pressure (kPa) @9000 fit
            Rv = 0.462;             % Gas constant for water vapor (kJ/kgK)
            e0 = 0.402;             % Reference vapor pressure (kPa)
            T0 = -5+273.15;         % Referecne temperature (C)

        % 2.4.3 - Calcute the density of air
             R       = 0.287;         % Gas constant for air (kJ/kg*K)
             rho_air = Patm./(R.*Ta); % Density of air (kg/m^3)  

        % 2.4.4 - Calculate vapor pressures
            ea = e0*exp(Ls/Rv * (1./T0 - 1./Ta)).*(RH/100);
            es = e0*exp(Ls/Rv * (1./T0 - 1./Ts));
        
        % 2.4.5 - Calculate correct output
            if strcmpi(type,'latent');
                FLUX = 0.622*1000*rho_air*Ls*Ke.*Vw.*(ea-es)/Patm;
                name = 'Flux: Latent Heat';
                unit    = 'W/m^2';
            else
                FLUX = ea./es .* 100;
                name = 'RH at Snow Surface';
                unit = '%';
            end

    % 2.5 - Reflectivity
    case 'reflectivity'
        i = in{1};              % Incident shortwave
        idx = i < 5; i(idx) = NaN;
        r = in{2};              % Reflected shortwave
        FLUX = r./i * 100;
        idx = FLUX > 100 | FLUX < 0;
        FLUX(idx) = NaN;
        name = 'Reflectivity';
        unit = '%';

    % 2.6 - Net radiation at surface
    case 'total'
        Qsw = in{1};            % Shortwave flux
        Qlw = in{2};            % Longwave flux
        Qs  = in{3};            % Sesible heat flux
        Qh  = in{4};            % Latent heat flux

        FLUX = Qsw + Qlw + Qs + Qh;
        name = 'Flux: Total';
        unit    = 'W/m^2';

    % 2.7 - Rate of mass flux at snow surface
    case 'massflux'
        Qe = in{1}; % Latent heat flux
        Ls = 2833;  % Latent heat of sublimation (kJ/kg)
      
        flx  = Qe./Ls;          % Mass flux (kg/m^2/s)
        FLUX = flx.*03.59928;    % Mass flux (mmH20/m^2/hr)
        name = 'Mass Flux Rate at Surface';
        unit = 'mmH20/m^2/hr';

    % 2.8 - Case when adjust is used, multiplier for SW data
    case 'adjust';
        old = in{1}; mod = in{2}; class(mod)
        FLUX = old * mod;
        name = ['Shortwave x',num2str(mod)];
        unit = 'W/m^2';       
end
  
% 3 - RETURN THE NEW STRUCTURE ARRAY
    out.data    = FLUX;
    out.display = 1;
    out.unit    = unit;
    out.label   = name;
    