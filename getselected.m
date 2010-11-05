function use = getselected(gui,varargin)
% GETSELECTED builds a cell array of the selected stations.
%__________________________________________________________________________
% USAGE: use = getselected(gui)
%
% INPUT: gui = Program Control handle
%        varargin = 'all' causes all the tags to be returned
%
% OUTPUT: use = cell array of the select stations
%__________________________________________________________________________

% Determine the selected season
    h = guihandles(gui);

% Find the station buttons that exists
    Panels = get(h.stationpanel,'Children');    % Station Panels
    S = [];
    
    % Gather buttons inside of each station panel
    for i = 1:length(Panels);
        Buttons = get(Panels(i),'Children');
        S = [S;Buttons];
    end   
        
    Name = get(S,'Tag'); % Tags of each button
    
% Make "Name" as a cell array in case only a single station exists
    if ischar(Name); Name = {Name}; end
    if ~isempty(varargin); use = Name; return; end

% Build a cell array of the selected stations
    k = 1; use = {};
    for i = 1:length(Name);
        test = get(S(i),'Value');
        if test == 1;
            use{k} = Name{i};
            k = k + 1;
    end,end
    