function [S] = group_items(sta,grp,type)
% GROUP_ITEMS 
%__________________________________________________________________________




%__________________________________________________________________________

% - Search for matches and groups these matches into a cell array
    N = length(grp);
    k(1:N) = 1;     % Initilizes counter for each code in "list"
    S = cell(N,1);  % Initilizes the storate array

    fn = fieldnames(sta);

    % - Loop through each weather station name
    for i = 1:length(fn);
        item = sta.(fn{i}).(type);

        % Compare with codes in "list"
        for j = 1:length(grp);
            
            % If the code matches store the name in the cell array "S"
            if strcmpi(grp{j},item);
                S{j}{k(j)}  = fn{i};      % Storage array
                k(j) = k(j) + 1;          % Increment counter
                break
    end,end,end


