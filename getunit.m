function varargout = getunit(unit,varargin)
% GETUNIT  returns unit information or converts units.
%__________________________________________________________________________
% SYNTAX: 
%   label = getunit(unit)
%   label = getunit(unit,format)
%   [new_number,new_unit] = getunit(unit,'convert',number)
%   [new_number,new_unit] = getunit(unit,'convert',number,conversion)
%
% DESCRIPTION:
%   label = getunit(unit) returns a text string of the unit
%   label = getunit(unit,format) returns a plot axis label in the desired
%       format of 'latex', 'tex', or 'none'. The usage of normal is the 
%       same as the above option without the format.
%   [output,unit] = getunit(unit,'convert',number) converts the numeric
%       value in "number" the to the corresponding unit and ouputs the new
%       value and the new unit
%   [output,unit] = getunit(unit,'convert',number,conversion) operates as
%       but utilizes a string ('english' or 'metric') for determining the
%       output units.  If the input is the same as the output nothing
%       changes.
%_________________________________________________________________________

% 1 - PULLS DATA FROM units.txt FILE
    fid = fopen('units.txt');
    form = '%s%s%s%s%s%s%s%f';
    F = textscan(fid,form,'delimiter',',','CommentStyle','#');
    fclose(fid);

% 2 - EXTRACT DATA FOR UNIT INPUT FILE
    %if isnan(unit); varargout = {[],[]}; return; end
    type = ''; unit = strtrim(unit); 

    % 2.1 - Search all data for id matches
    for i = 1:length(F{1});

        % 2.1.1 - Determine if the units are metric or english
            metric  = strcmpi(F{1}{i},unit);  
            english = strcmpi(F{2}{i},unit);  

        % 2.1.2 - Extract data from data read from units.txt 
            u = {F{1}{i},F{2}{i},F{3}{i},F{4}{i},...
                    F{5}{i},F{6}{i},F{7}{i},F{8}(i)};

        % 2.1.3 - Exit loop if a match was made
            if metric;  type = 'metric';  desired = 'english'; break; end
            if english; type = 'english'; desired = 'metric';  break; end
     end

    % 2.2 - Exit program if the input is not recongnized
        if isempty(type); 
            disp(['The unit, "',unit,'" , was not recongnized.']);
            return;
        end

% 3 - CONVERT UNITS OPTION
    if ~isempty(varargin) && strcmpi(varargin{1},'convert')
        [varargout{1},varargout{2}] = ...
            convertunits(varargin,unit,type,desired,u);
        return;
    end

% 4 - BUILD TEXT LABEL
    % 3.1 - Determine the interpreter
        if isempty(varargin); varargin{1} = 'none'; end
        switch varargin{1};
            case 'latex'; loc = 4;
            case 'tex';   loc = 6;
            otherwise;    loc = 1;
        end

    % 3.2 - Build the character string
        switch type
            case 'metric';  varargout{1} = [u{3},' (',u{loc},')'];
            case 'english'; varargout{1} = [u{3},' (',u{loc+1},')'];
        end

%--------------------------------------------------------------------------
% SUBFUNCTION: convertunits
function [n_out,u_out] = convertunits(input,unit,type,def,u)

% 1 - Test that numeric input is correct
     N = length(input);
     if isempty(input{2});
        errordlg('No value given to convert (getunit.m)','ERROR');
        return;
     elseif ~isnumeric(input{2});
        errordlg('Input must be numeric (getunit.m)','ERROR');
        return;
     else
        num = input{2}; % Input numeric value for converting
        n_out = num; u_out = unit;
     end

% 2 - Determine the ouput units desired (use default if nothing is input)
    % 2.1 - Deterimine the desired output
        if N < 3;
            desired = def; 
        else
            desired = input{3};
        end

    % 2.2 - Exit if the desired == type
        if strcmpi(type,desired); return; end

% 3 - Convert the units to the desired output
    % 3.1 - Convert units using custom function (6999 in units.txt)
    if u{8} == 6999;
        [n_out,u_out] = custom(unit,u,type,num);

    % 3.2 - Convert units using multiplier in units.txt
     else
        switch type
            case 'metric';  
                n_out = num.*u{8}; u_out = u{2}; 
            case 'english'; 
                n_out = num./u{8}; u_out = u{1};
        end
     end

%--------------------------------------------------------------------------
% SUBFUNCTION: CUSTOM - converts units such as temperature that are not
%                       a straight multiplier
function [n_out,u_out] = custom(unit,u,type,num)

switch unit
    % 4.1 - Temperature Conversion
    case {'C','F'}
        switch type
            case 'metric';  n_out = (9/5).*num + 32;    u_out = u{2};
            case 'english'; n_out = (5/9).*(num - 32);  u_out = u{1};
        end  
end
