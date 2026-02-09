function resampling_viewer(results,result100, name)

%Prepare userData
userData = struct('results',results,'result100',result100,'type','Event spectrum','integrationBorders',[],'textptr',[],'kmin',1e-17,'showValuesInSeconds', false);

%Create Figure and Save Data
hFigResViewer=figure('Name',name);


%Create Axes
hAx=axes;

% Set X and Y axis labels
xlabel(hAx,'Dissociation rate (1/s)')
ylabel(hAx,'Fraction')

% Enable holding for overlaying multiple plot elements on the same axes
hold(hAx,'on')

% Define callback function for mouse click on axes
set(hAx,'ButtonDownFcn',@Axes_1_ButtonDownFcn);

% Set Y-axis limits and scale for the X-axis
hAx.YLim=[0 1.4];
hAx.XScale='log';

% Initialize empty graphics objects array for plotting integration borders
hBorders = gobjects(0);

% Create text UI control for displaying bleaching number
hTextBleachingNum = uicontrol('Style', 'text', 'Units','normalized','HorizontalAlignment','left', 'Position', [0.02, .96, .6, .035]);


% Set up ui context menu for right click on the axis
hAx.UIContextMenu = uicontextmenu;
% Define context menu items and their callback functions
uimenu(hAx.UIContextMenu,'Label','Show state spectrum','Callback',@TypeChangedCB);
uimenu(hAx.UIContextMenu,'Label','Clear integration borders','Callback',@ClearIntegrationBordersCB);
uimenu(hAx.UIContextMenu,'Label','Set integration borders','Callback',@SetIntegrationBordersCB);
uimenu(hAx.UIContextMenu,'Label','Show mean binding time in seconds','Callback',@ShowMeanBindingTimeCB, 'Checked', 'off');
uimenu(hAx.UIContextMenu,'Label','Adjust axis limits and font size','Callback',@AdjustAxisLimitsDialog);
% uimenu(hAx.UIContextMenu,'Label','Save Expectation values','Callback',@SaveExpectationValueCB);


% Create scatter plots for resampling data with different marker styles and colors
hResampling = scatter(hAx,NaN,NaN,'SizeData',20,'Marker','o','MarkerEdgeColor','k');

% Create stem plots for visualizing 100% data
h100Plot = stem(hAx,NaN,NaN,'linewidth',1.5,'color','r','MarkerSize',2);
hLegend = legend(hAx,'Box','off','String',{'Resampling','100% data'},'Visible','off');


%Draw
PlotSpec();

%%Plotting functions

%Draw spectrum into source axes
    function PlotSpec()

        % Fetch data from the user data structure        
        curResults=userData.results;
        curResult100=userData.result100;

        %Get number of resamplings
        nResamplings = numel(curResults);

        % Transformation between state and event spectrum  
        switch userData.type
            case 'Show state spectrum'
                % Adjust data for state spectrum display:
                % Normalize S by k and then normalize S to sum to 1

                %Adjust resampling data
                for resamplingIdx=1:nResamplings
                    curResults(resamplingIdx).S=curResults(resamplingIdx).S./curResults(resamplingIdx).k;
                    curResults(resamplingIdx).S=curResults(resamplingIdx).S/sum(curResults(resamplingIdx).S);
                end
                % Adjust 100% data
                curResult100.S=curResult100.S./curResult100.k;
                curResult100.S=curResult100.S/sum(curResult100.S);
        end


        % Prepare data for plotting resamplings
        kResampling = [];
        sResampling = [];

        for resamplingIdx=1:nResamplings
            %Get S and k values for current resampling
            tempS=curResults(resamplingIdx);
            tempk=curResult100.k;

            % Exclude very small S values for better visualization
            tempk(tempS.S<1e-15)=[];
            tempS.S(tempS.S<1e-15)=[];

            %Write all resamplings in one array for easier plotting
            kResampling = [kResampling tempk];
            sResampling = [sResampling tempS.S];
        end
        
        % Plot resampling
        set(hResampling,'XData',kResampling,'YData',sResampling)

        %Plot 100% data
        set(h100Plot,'XData',curResult100.k,'YData',curResult100.S)


        % Compute and display average bleaching number
        allBleachingNums = [curResults(:).a1];
        hTextBleachingNum.String=['Average bleaching number =', num2str(mean(allBleachingNums)) '+-' num2str(std(allBleachingNums))];
        
        % Call function to plot integration borders
        PlotIntegrationBorders()
    end


    function ClearIntegrationBordersCB(~,~)
        %Reset integration boders

        %Delete integration borders from user data
        userData.integrationBorders=[];

        % Call function to plot integration borders
        PlotIntegrationBorders()
    end
    
    function PlotIntegrationBorders()

        % Delete current integration borders
        for borderIdx = 1:numel(hBorders)
            % Remove each border line plot from the axes
            delete(hBorders(1));

            %Delete from array
            hBorders(1) = [];
        end

        % Retrieve entered integration border data from userData
        enteredData = userData.integrationBorders;

        % Fetch results from userData structure
        curResults=userData.results;
        nResamplings = numel(curResults);

        %Switch between state and event spectrum
        if strcmp(userData.type,'Show state spectrum')
            % Adjust data for state spectrum display
            for resamplingIdx=1:nResamplings
                % Normalize S by k and then normalize S to sum to 1
                curResults(resamplingIdx).S=curResults(resamplingIdx).S./curResults(resamplingIdx).k;
                curResults(resamplingIdx).S=curResults(resamplingIdx).S/sum(curResults(resamplingIdx).S);
            end
        end

        % Get number of entered integration borders
        nBorders = numel(enteredData);

        % Initialize graphics object array for borders
        hBorders = gobjects(1,nBorders);

        % Plot entered integration borders
        for borderIdx = 1:nBorders
            % Draw vertical line for each border at specified x-coordinate
            hBorders(borderIdx) = plot(hAx,[enteredData(borderIdx) enteredData(borderIdx)],[0 1]);
        end

        % Reset all previously drawn text annotations
        for textIdx=1:numel(userData.textptr)
            delete(userData.textptr(textIdx))
        end

        % Clear the textptr array
        userData.textptr=[];

        % Compute local integral and display values
        for borderIdx=1:numel(userData.integrationBorders)-1
            % Find index range for local integral calculation
            handleNum=find(curResults(1).k>userData.integrationBorders(borderIdx),1,'first');
            idx2=find(curResults(1).k<userData.integrationBorders(borderIdx+1),1,'last');
            weightsFraction=zeros(1,numel(curResults));
            weightsRate=zeros(1,numel(curResults));

            % Compute weights for each resampling
            for resamplingIdx=1:numel(curResults)
                if isempty(handleNum) || isempty(idx2)
                    weightsFraction(resamplingIdx)=0;
                    weightsRate(resamplingIdx)=0;
                else
                    % Compute fraction and rate weights
                    weightsRate(resamplingIdx)=sum(curResults(resamplingIdx).S(handleNum:idx2).*curResults(resamplingIdx).k(handleNum:idx2))/sum(curResults(resamplingIdx).S(handleNum:idx2));
                    
                    % If the resampling has no rate between the current integration borders, 
                    % the weights rate will be NaN. We handle this by setting both, the weights rate 
                    % and the fraction to NaN and ignore NaN Values in the subsequent calculation of 
                    % mean and standard deviation.

                    if isnan(weightsRate(resamplingIdx))
                        % weightsRate(resamplingIdx) is NaN, because the current resampled spectrum has no rate within the
                        % current integration borders, so set the fraction also to NaN
                        weightsFraction(resamplingIdx) = NaN;
                    else
                       
                        % Current resampled spectrum has a value within the current integration borders
                        % so we can go on normally and calculate the fraction
                        weightsFraction(resamplingIdx)=sum(curResults(resamplingIdx).S(handleNum:idx2));
                    end

                end
            end

            % Compute mean and standard deviation of weighted rate
            meanWeightsRate = mean(weightsRate,'omitnan');
            stdWeightsRate = std(weightsRate,'omitnan');

            
            if userData.showValuesInSeconds
                % Convert average binding rates to seconds and compute standard deviations accordingly
                meanWeightsRate = 1/mean(weightsRate);
                stdWeightsRate = meanWeightsRate^2 * std(weightsRate);

                % Set unit to seconds
                unit = ' s';
            else
                %Add unit to average binding rate
                unit = ' 1/s';
            end



            % Generate strings for displaying mean and standard deviation
            string2=[[num2str(meanWeightsRate,3), unit], "+-", [num2str(stdWeightsRate,'%0.2g'), unit]];
            string=[[num2str(mean(weightsFraction,'omitnan')*100,3), ' %'],"+-", [num2str(std(weightsFraction,'omitnan')*100,'%0.2g'), ' %']];
            
            % Add text annotations to the plot and update userData textptr array
            userData.textptr=[userData.textptr,...
                text(hAx,userData.integrationBorders(borderIdx),1,string),...
                text(hAx,userData.integrationBorders(borderIdx),1.25,string2)];
        end


        % Show only the last two legend entries if more than two are present
        if length(hLegend.String) > 2
            set(hLegend, 'String', hLegend.String(1:2));
        end



    end


%%Callbacks for the context menu

% Callback function triggered when the type of spectrum to display is changed
    function TypeChangedCB(src,~)

        % Update userData.type based on the selected menu item label
        userData.type= src.Label;

        % Toggle the label of the UI menu item between 'Show state spectrum' and 'Show event spectrum'
        if strcmp(src.Label, 'Show state spectrum')
            % Change label to 'Show event spectrum'
            src.Label = 'Show event spectrum'; 
        else
            % Change label to 'Show state spectrum'
            src.Label = 'Show state spectrum';
        end


        PlotSpec()
    end

%Callback for mouse click on axis
    function Axes_1_ButtonDownFcn(~, eventdata)

        %Left click -> Draw a border and perform local integral
        if eventdata.Button==1

            %Save position of border and sort ascending
            integrationBorders=sort([userData.integrationBorders,eventdata.IntersectionPoint(1)]);

            %Save in userData structure
            userData.integrationBorders=integrationBorders;

            %Call function to plot integration borders
            PlotIntegrationBorders()

        end

    end

% Callback function for setting integration borders
    function SetIntegrationBordersCB(~, ~)

        % Retrieve integration borders from userData
        integrationBorders = userData.integrationBorders';

        % Get the number of entries from the provided array
        nBorders = numel(integrationBorders);

        % Create the main window for setting integration borders
        hSetBordersFig = figure(...
            'Name', 'Set integration borders',...
            'NumberTitle', 'off', ...
            'Position', [100, 100, 400, 300],...
            'WindowKeyPressFcn',@KeyPressFcnCB,...
            'CloseRequestFcn',@CloseRequestCB);

        % Create an input field for the number of entries
        uicontrol('Style', 'text', 'String', 'Number of integration borders:', 'Position', [50, 250, 150, 20]);
        uicontrol('Style', 'edit', 'String',nBorders, 'Position', [220, 250, 50, 20], 'Callback', @editCB);

        % Create an empty table with the specified number of entries
        data = cell(nBorders, 1);
        columnNames = {'Dissociation rate (1/s)'};
        hTable = uitable('Parent', hSetBordersFig, 'Data', data, 'ColumnName', columnNames, 'Position', [50, 50, 300, 180],'ColumnEditable',true);

        % Populate the table with values from the provided array
        set(hTable, 'Data', num2cell(integrationBorders));

        % Create a button to finish the input
        uicontrol('Style', 'pushbutton', 'String', 'OK', 'Position', [180, 10, 80, 30], 'Callback', @OKCB);

        % Function called when the Finish button is pressed
        function OKCB(~, ~)

            % Get the entered numbers from the table
            integrationBorders = sort(cell2mat(get(hTable, 'Data')))';

            % Close the UI window
            close(hSetBordersFig);

            % Update userData with the new integration borders
            userData.integrationBorders = integrationBorders;

            % Plot the integration borders on the spectrum plot
            PlotIntegrationBorders()

        end

        % Function called when the OK button is pressed
        function editCB(src, ~)
            %Get current table data
            data = hTable.Data;

            %Get amount of desired splits
            nSequences = str2double(src.String);

            %Calculate difference between current amount of splits and new
            %amount of splits
            nAdditional = nSequences - size(data,1);

            if nAdditional > 0
                %More splits required

                %Create additional table entries
                hTable.Data = [data; repmat({1},nAdditional,1)];

            elseif nAdditional < 0
                %Less splits required so just delete amount of excess rows
                hTable.Data = data(1:end+nAdditional,:);
            end
        end


        function CloseRequestCB(~,~)

            %Delete figure
            delete(hSetBordersFig)
        end

        %User pressed esc key
        function KeyPressFcnCB(~,event)

            if strcmp(event.Key, 'escape')
                CloseRequestCB()
            end

        end

    end


    function AdjustAxisLimitsDialog(~,~)

        % Create the main window
        hOptionsFig = figure(...
            'Name', 'Adjust Axis and Font Sizes',...
            'NumberTitle', 'off',...
            'MenuBar','None',...
            'Position', [100, 100, 500, 250],...
            'WindowKeyPressFcn',@KeyPressFcnCB,...
            'CloseRequestFcn',@CloseRequestCB);

        % Get the current axis limits and font sizes
        currentXLim = xlim(hAx);
        currentYLim = ylim(hAx);
        currentAxisFontSize = get(hAx, 'FontSize');
        currentLabelFontSize = get(get(hAx, 'XLabel'), 'FontSize');


        if ~isempty(hLegend) && strcmp(hLegend.Visible, 'on')
            boolLegendVisible = true;
        else
            boolLegendVisible = false;
        end

        % Create input fields for X-axis limits
        uicontrol('Style', 'text', 'String', 'X-Axis Min:', 'Position', [20, 200, 80, 20]);
        hXMinEdit = uicontrol('Style', 'edit', 'Position', [100, 200, 80, 20], 'String', num2str(currentXLim(1)),'Callback',@ValuesChangedCB);

        uicontrol('Style', 'text', 'String', 'X-Axis Max:', 'Position', [200, 200, 80, 20]);
        hXMaxEdit = uicontrol('Style', 'edit', 'Position', [280, 200, 80, 20], 'String', num2str(currentXLim(2)),'Callback',@ValuesChangedCB);

        % Create input fields for Y-axis limits
        uicontrol('Style', 'text', 'String', 'Y-Axis Min:', 'Position', [20, 150, 80, 20]);
        hYMinEdit = uicontrol('Style', 'edit', 'Position', [100, 150, 80, 20], 'String', num2str(currentYLim(1)),'Callback',@ValuesChangedCB);

        uicontrol('Style', 'text', 'String', 'Y-Axis Max:', 'Position', [200, 150, 80, 20]);
        hYMaxEdit = uicontrol('Style', 'edit', 'Position', [280, 150, 80, 20], 'String', num2str(currentYLim(2)),'Callback',@ValuesChangedCB);

        % Create input fields for font sizes
        uicontrol('Style', 'text', 'String', 'Axis Font Size:', 'Position', [20, 100, 100, 20]);
        hAxisFontSizeEdit = uicontrol('Style', 'edit', 'Position', [130, 100, 50, 20], 'String', num2str(currentAxisFontSize),'Callback',@ValuesChangedCB);

        uicontrol('Style', 'text', 'String', 'Label Font Size:', 'Position', [200, 100, 100, 20]);
        hLabelFontSizeEdit = uicontrol('Style', 'edit', 'Position', [310, 100, 50, 20], 'String', num2str(currentLabelFontSize),'Callback',@ValuesChangedCB);

        %Create checkbox to enable or disable legend
        hCheckboxLegend = uicontrol('Style', 'checkbox', 'String', 'Show legend', 'Value', boolLegendVisible, 'Position', [30, 50, 100, 20],'Callback',@ValuesChangedCB);

        % Create a button to close window
        uicontrol('Style', 'pushbutton', 'String', 'OK', 'Position', [350, 20, 80, 30], 'Callback', @CloseRequestCB);

        % Function called when the OK button is pressed
        function ValuesChangedCB(~, ~)

            % Get the entered axis limits and font sizes
            xMin = str2double(get(hXMinEdit, 'String'));
            xMax = str2double(get(hXMaxEdit, 'String'));
            yMin = str2double(get(hYMinEdit, 'String'));
            yMax = str2double(get(hYMaxEdit, 'String'));

            axisFontSize = str2double(get(hAxisFontSizeEdit, 'String'));
            labelFontSize = str2double(get(hLabelFontSizeEdit, 'String'));

            % Adjust the axis limits and font sizes
            xlim(hAx,[xMin, xMax]);
            ylim(hAx,[yMin, yMax]);
            set(hAx, 'FontSize', axisFontSize);
            set(get(hAx, 'XLabel'), 'FontSize', labelFontSize);
            set(get(hAx, 'YLabel'), 'FontSize', labelFontSize);

            %Make legend visible or invisible
            if hCheckboxLegend.Value
                hLegend.Visible = 'on';
            else
                hLegend.Visible = 'off';
            end

        end



        function CloseRequestCB(~,~)

            %Delete figure
            delete(hOptionsFig)
        end

        %User pressed esc key
        function KeyPressFcnCB(~,event)

            if strcmp(event.Key, 'escape')
                CloseRequestCB()
            end

        end


    end

% Callback function to toggle between displaying mean binding time and mean dissociation rate
    function ShowMeanBindingTimeCB(src,~)

        % Toggle the label of the UI menu item and update userData accordingly
        if strcmp(src.Label, 'Show mean binding time in seconds')
            % Change label to display dissociation rate
            src.Label = 'Show mean dissociation rate in 1/second';

            % Set flag to display values in seconds
            userData.showValuesInSeconds = true;
        else
            % Change label to display binding time
            src.Label = 'Show mean binding time in seconds';
            % Set flag to display values in reciprocal seconds
            userData.showValuesInSeconds = false;
        end

        %Plot integration borders
        PlotIntegrationBorders()

    end


    function SaveExpectationValueCB(~,~)
        curResults=userData.results;
        %Local Integral
        idx=find(curResults(1).k>userData.integrationBorders(1),1,'first');
        idx2=find(curResults(1).k<userData.integrationBorders(2),1,'last');
        weights=zeros(1,numel(curResults));
        weights2=zeros(1,numel(curResults));
        for w=1:numel(curResults)
            if or(isempty(idx),isempty(idx2))
                weights(w)=0;
                weights2(w)=0;
            else
                weights(w)=sum(curResults(w).S(idx:idx2).*(idx:idx2))/sum(curResults(w).S(idx:idx2));
                weights2(w)=sum(curResults(w).S(idx:idx2).*curResults(w).k(idx:idx2))/sum(curResults(w).S(idx:idx2));
            end
        end
        
        [y,x]=hist(weights,curResults(1).k(idx:idx2));

        %uisave({'weights2','x','y'})
        t1=array2table(weights2');
        t2=array2table(weights');

        writetable(t1,'resampling_distr')
    end



end