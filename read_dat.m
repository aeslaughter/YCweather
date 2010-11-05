function S = read_dat(filename)
% READ_DAT reads data from the station *.yc format file and builds a data
% structure containing the station information as well as associated
% weather data.
%__________________________________________________________________________
% USAGE: S = READ_DAT(station)
%
% INPUT: station = a text string giving the *.yc filename to be openned
%   
% OUTPUT: S = a data structure corresponding to the station represented by
%             the inputed *.yc file, the structure looks as follows
%
%   S.name      = station name as will be displayed in the gui
%   S.location  = location of station as will be displayed in the gui
%   S.season    = winter season (e.g. 2007/2008)
%   S.arrayID   = Campbell Sci., arrayID to include with station data, if
%                 value equals NaN then nothing is excluded from data
%   S.TCprofile = Text string of thermocouple profile label (e.g. 'TC'), if
%                 string is 'none' then no thermocouples exist in data
%   S.datafile  = location of the *.dat file containing the raw data
%   S.Time      = numeric array of serial MATLAB times matching raw data,
%                 this data must be in serial format and either included in
%                 the data itself of calculated using "calc_time.m".  This
%                 field is added from the varialbes structure, ther must be
%                 a variablename field "Time" either in raw data or
%                 computed.
%   S.variables = structure of the variables to be made available to user
%
%   S.variables.<varname>.unit  = text string containing variable units
%                        .label = text string of label for use in legend
%                        .data  = numeric data from raw file
%
% NOTES:
%   The *yc files must be formatted as follows.
%
%       1) The first six rows contain a single value that make up the
%       entries to the output structure S, as follows:
%           - Station tag (should conform to MATLAB's genvarname)
%           - Station label for GUI button
%           - Station location label for GUI button groups
%           - Full or relative path to *.dat file
%           - The Array ID number to extract, if this is not need use
%           'none' instead of a number
%           - Thermocouple identifier (e.g. TC), tells the YCweather that
%           <varname> items beginning with TC are temperatures associated
%           with depth for making profile plots
%       2) These rows are followed by single # sing and rows of comma 
%       seperated values that give the variable name, display status, 
%       units, and label.  There must be one row for each column of data
%       present in the raw *.dat file refered to by S.datafile
%       3) The end of the file is composed of comma seperated lists that
%       allow custom <varname> to be produced.  This list should be proceed
%       with a # alone in a row. These strings must be organized as such:
%           
%           output,function,input1,input2,...
%
%       so that a <varname> calculated using the assigned function with
%       inputs listed afterward, where the inputs likely refer to
%       fieldnames in the data variables data structure from the raw file.
%       
%       To illustrate this, consider the calc_time.m function.  Within the
%       *.yc file the function string reads:
%               time,calcwx_time,year,day,hrmin,yyyydddHHMM
%
%       This results in the execution of:
%               time = calcws_time(d,'year','day','hrmin','yyyydddHHMM');
%
%       Where d is the data structure that contains fields 'year','day',
%       and 'hrmin'.  The final input is a time code, see calc_time for
%       specific information.  When programing a custom funtion, the output
%       must be the structure that was input (d) with the added variable
%       included (e.g. time).
% 
% EXAMPLE *.yc FILE:
%         YCaspirit
%         Amer. Spirit
%         Yellowstone Club
%         ASPIRIT.dat
%         60
%         0
%         #
%         ArrayID,0,0,0
%         year,0,0,0
%         day,0,0,0
%         hrmin,0,0,0
%         WindSpeed,1,mph,Wind Speed
%         WindDir,1,deg,Wind Direction
%         WindMax,1,mph,Maximum Wind Speed
%         AirTemp,1,C, Air Temperature
%         Humidity,1,%,Relative Humidity
%         SWin,1,W/m^2,Incoming Shortwave
%         Longwave,1,W/m^2,Incoming Longwave
%         Battery,1,V,Voltage
%         #
%         Time,calcwx_time,year,day,hrmin,CSI
%
% PROGRAM OUTLINE:
% 1 - OPEN *.yc FILE AND EXTRACT THE STATION INFORMATION
% 2 - READ RAW DATA FROM DATA FILE ASSOCIATED WITH STATION
% 3 - REMOVE DATA NOT IN SPECIFIED ARRAY AND ELIMINATE DUPLICATE ROWS
% 4 - BUILD THE VARIABLE DATA STRUCTURE
% 5 - PREFORM CUSTOM CALCULTIONS (see calcwx_time.m for more information)
% 6 - SET THE TIME FIELD AND REMOVE EXTRANOUS DATA
% 7 - SEARCH TIME ARRAY FOR DUPLICATE ENTRIES 
%__________________________________________________________________________

try
% 1 - OPEN *.yc FILE AND EXTRACT THE STATION INFORMATION
    % 1.1 - Open the *.yc file
        fid = fopen(filename); 
        if fid < 0; 
            disp(['!ERROR! read_dat.m - error opening file: ',filename]);   
            return;
        end

    % 1.2 - Read the file and find breaks ('#')
        a = textscan(fid,'%s','delimiter','\n'); a = a{1};
        N = strmatch('#',deblank(a));

    % 1.3 - Compute the number of data columns
        if length(N) == 1; N(2) = length(a); end
        n = N(2) - N(1) - 1;
        fclose(fid);

    % 1.4 - Build station data structure
        S.tag = deblank(a{1});          % Tag for use in data structure
        S.display = deblank(a{2});      % Name displayed in GUI
        S.group  = deblank(a{3});       % Name for grouping stations
        S.subfolder  = deblank(a{1});   % Folder with above folder for storing data 
        S.datfile = deblank(a{4});      % Relative/absolute file for *.dat
        S.arrayID = str2double(a{5});   % ArrayID identifing rows to remove 
        S.TCprofile = deblank(a{6});    % String identifing TC profiles

    % 1.5 - Retrieve the folder
        pth = fileparts(filename);
        t = regexp(pth,'\');                        
        S.folder = pth(t(length(t))+1:length(pth));

% 2 - READ RAW DATA FROM DATA FILE ASSOCIATED WITH STATION
    % 2.1 - Adjust for relative paths
        if ~exist(S.datfile,'file');
            [pth,fname,ext] = fileparts(filename);
            S.datfile = [pth,'\',a{4}];
            if ~exist(S.datfile,'file');
                disp(['DAT file does not exist for ',fname,ext]);
                fclose(fid); return;
        end,end

    % 2.2 - Read the entire data file
        A = dlmread(S.datfile);

% 3 - REMOVE DATA NOT IN SPECIFIED ARRAY AND ELIMINATE DUPLICATE ROWS
    % 3.1 -  Removes data not in arrayid, common for Campbell Sci. data
        if ~isnan(S.arrayID)
            keep = A(:,1) == S.arrayID;
            A = A(keep,:);
        end

    % 3.2 - Remove duplicate rows
        A = unique(A,'rows');

% 4 - BUILD THE VARIABLE DATA STRUCTURE
    % 4.1 - Produce error or warn user if the number of columns does not
    % match between the *.yc and *.dat file
        out = num2cell(A,1); 
        [p,nm,e] = fileparts(filename);
        if length(out) < n; 
            mes = ['ERROR reading file: ',nm,e,'.  The number columns ',...
                'in *.yc file is greater than columns in *.dat file'];
            disp(mes);
            return;
        elseif length(out) > n;
            mes = ['WARNING reading file: ',nm,e,'.  The number columns ',...
                'in *.yc file is less than columns in *.dat file'];
            disp(mes);
        end

    % 4.2 - Build a structure for storing data and variable atributes
        k = 1;
        for i = N(1)+1:N(2)-1;
            x = textscan(a{i},'%s%f%s%s',n,'delimiter',','); 
            d.(x{1}{1}).unit    = x{3}{1};
            d.(x{1}{1}).label   = x{4}{1};
            d.(x{1}{1}).display = x{2};
            d.(x{1}{1}).data    = out{k}; k = k + 1;
        end

% 5 - PREFORM CUSTOM CALCULTIONS (see calcwx_time.m for more information)
    % 5.1 - Extract the custom functions from the file
        fcn = a(N(2)+1:length(a));

    % 5.2 - Execute each of the functions
        for i = 1:length(fcn);  % Cycle through custom functions in *.yc
            if ~isempty(fcn{i});% Skip if an empty row is found

                % Extract individual
                f = textscan(fcn{i},'%s','delimiter',','); f = f{1};
                n = length(f);       
                d.(f{1}) = feval(f{2},d,(f{3:n}));
        end,end

% 6 - SET THE TIME FIELD AND REMOVE EXTRANOUS DATA
    % 6.1 - Set time field in output structure
        S.Time = d.Time.data;
        
    % 6.2 - Remove data that has a display value of 0
        fn = fieldnames(d);
        for i = 1:length(fn);
            test = d.(fn{i}).display;

            if test == 0;   d = rmfield(d,fn{i});
            else            d.(fn{i}) = rmfield(d.(fn{i}),'display');
            end
        end

    % 6.3 - Define the variables field in the output structure
        S.variables = d;  

% 7 - SEARCH TIME ARRAY FOR DUPLICATE ENTRIES
    % 7.1 - Get indices of duplicates;
        [S.Time,m,n] = unique(S.Time);

    % 7.2 - Remove duplicate entries
        fname = fieldnames(S.variables);
        for i = 1:length(fname);
            S.variables.(fname{i}).data = S.variables.(fname{i}).data(m);
        end

catch
    mes = ['An error occured reading ',filename,' (read_dat.m)',...
            ', see errorlog.txt.'];
    errorlog(mes);
end
