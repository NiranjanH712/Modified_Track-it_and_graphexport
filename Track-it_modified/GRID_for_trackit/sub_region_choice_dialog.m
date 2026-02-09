function [regionChoice, canceled] = sub_region_choice_dialog(batch)
%% Function to display a dialog window for selecting a sub-region of a batch for GRID analysis

%Get number of movies in current batch
nMovies = length(batch);
regionChoice = [];
canceled = false;

%Iterate through all movies and find maximum number of sub-regions
%in a movie
nSubRegions = 0;
for movieIdx = 1:nMovies
    nSubRegions = max(nSubRegions, batch(movieIdx).results.nSubRegions);
end

if nSubRegions > 0
    %At least one movie has a sub-region so create a dialog window
    %where user can select the sub-region in which dissociation
    %rates should be analyzed


    %Create list of sub-regions
    popList = cell(nSubRegions+2,1);
    popList{1} = 'All regions';
    popList{2} = 'Region 1 (tracking-region)';
    for roiIdx = 2:nSubRegions+1
        popList{roiIdx+1} = ['Region ',num2str(roiIdx)];
    end

    %Create dialog
    d = dialog('Position',[600 400 200 200],'Name','Select a region','WindowKeyPressFcn',@KeyPressFcnCB,'CloseRequestFcn',@CloseRequestCB);
    uicontrol('Units','normalized','Parent',d,'Style','text','Position',[.05 .7 .8 .2], 'String','In which region do you want to analyze dissociation rates?','HorizontalAlignment','Left');
    uicontrol('Units','normalized','Parent',d,'Style','listBox','Position',[.05 .3 .9 .35], 'String',popList,'Callback',@PopUpCB);
    uicontrol('Units','normalized','Parent',d,'Position',[.05 .1 .4 .15],'String','OK', 'Callback',@OkCB);
    uicontrol('Units','normalized','Parent',d,'Position',[.5 .1 .4 .15],'String','Cancel', 'Callback',@CloseRequestCB);

    % Wait for d to close before running to completion
    uiwait(d);

end

    function PopUpCB(src,~)
        %User changed the selected region
        regionChoice = src.Value - 1;

        % If 'All regions' is selected, set regionChoice to empty
        if regionChoice == 0
            regionChoice = [];
        end
    end

% Callback function for closing the dialog
    function CloseRequestCB(~,~)
        canceled = true; % Set canceled flag to true
        delete(gcf)
    end

% Callback function for the OK button
    function OkCB(~,~)
        canceled = false; % Set canceled flag to true
        delete(gcf)
    end

% Callback function for handling keyboard events
    function KeyPressFcnCB(~,event)
        if strcmp(event.Key, 'escape')
            %User pressed escape, close the dialog
            CloseRequestCB()
        end
    end



end