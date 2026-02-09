function stop = DispStatus(~,optimValues,state)
%DISPSTATUS  Dislay current status and iteration count of Solver 

%Stop by user
stop = false;
drawnow;
stop=getappdata(0,'optimstop');

%Display status of solver
   switch state
       case 'init'
           disp('---GRID is running---')
           fprintf('Iteration Count: 0')
       case 'iter'
           for idx=1:numel(num2str(optimValues.iteration-1))
             fprintf('\b')
           end
           fprintf(num2str(optimValues.iteration))
       case 'done'
           disp('.')
           disp('---GRID has finished---')
       otherwise
   end
   
end