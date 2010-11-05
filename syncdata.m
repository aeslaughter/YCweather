function rdir = syncdata(local,remote,varargin)
% SYNCDATA sychronizes files between the local and remote database
%__________________________________________________________________________
% SYNTAX: 
%   syncdata(local,remote);
%   syncdata(local,remote,mes);
%   syncdata(local,remote,mes,'on');
%   syncdata(local,remote,'','on');
%
% DESCRIPTION:
%
%__________________________________________________________________________

% 1 - GATHER INPUT OPTIONS
    mes = 'Synchronizing with latest available data, please wait...';
    img = 'off';
    if length(varargin) >= 1 && ~isempty(varargin{1});
        mes = varargin{1}; 
    end
    if length(varargin) >= 2 && ischar(varargin{2});
        img = varargin{2};
    end

% 2 - BUILD WINSCP COMMAND
    S{1} = '!winscp.exe /console /command ';
    if strcmpi(img,'off');
        S{2} = '"option exclude Images" ';    
    else
        S{2} = '';
    end
  %     ss = '!winscp.exe /command "option exclude Images" "open ftp://anonymous:ycweather@caesar.ce.montana.edu"  "synchronize local C:\Users\pigpen\Documents\MSUResearch\MATLABcode\YCweather_v4\database\08-09  /pub/snow/db/08-09/" "exit"';
    S{3} = '"open ftp://anonymous:ycweather@caesar.ce.montana.edu" ';
    S{4} = ['"synchronize local ""',local,'"" ""',remote,'""" '];
    S{5} = '"exit" ';
    
% 3 - EVALUATE COMMAND
    disp(mes);
    eval([S{:}]);
    disp('Complete.');

