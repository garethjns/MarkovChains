classdef markovChain
    properties
        transitionMatrix = [] % Chance of all states transitioning
        members = [] % Member state objects
        IDs % Numeric names of members
        nStates % Total number of members
        its = 200; % Iterations to preallocate
        it % Iteration
        currentState % String
        currentStateID % Numeric name
        currentValue % Numeric value
        h = []; % Handle to figure
        params % Original parameters
        seed % Seed
    end
    
    properties (SetAccess = private)
        stateHistory
        stateHistoryID
        valueHistory
        TMMode = 'Member inherited';
    end
    
    properties (Hidden)
        xAxis % Axis for graph
        plotOn = 0;
        stateIndex % Not used
        stateCols % Colours for graphs - random
    end
    
    methods
        function obj = markovChain(states, params)
            
            % Set parameters
            obj.params = params;
            % Overwrite defaults with fields in params
            flds = fieldnames(params);
            for f = 1:numel(flds)
                obj.(flds{f}) = params.(flds{f});
            end
            
            % Prepare states
            obj.nStates = numel(states);
            obj.members = states;
            
            % Prepare figure
            if obj.plotOn && (~exist('h', 'var') || isempty(h))
                obj.h = figure;
                hold on
                subplot(2,1,1)
                ylabel('State (ID)')
                subplot(2,1,2)
                ylabel('State (value)')
                xlabel('Iteration')
            end
            
            % Make numeric names easy access
            obj.IDs = NaN(1, obj.nStates);
            for s = 1:obj.nStates
                obj.IDs(s) = obj.members{s}.ID;
            end
            
            % Set transitionMatrix
            switch obj.TMMode
                case 'Rand' % Totally random TM
                    obj = randomTransitionMatrix(obj);
                otherwise % Normal
                    obj = specifiedTransitionMatrix(obj);
            end
            
            % Not set.method to avoid call when setting params
            % Calls reset (too early when setting params)
            obj = obj.setSeed(obj.seed);
        end
        
        function obj = setSeed(obj, seed)
            if isempty(seed)
                obj.seed = rng;
            else
                obj.seed = rng(seed);
                obj.seed = rng(seed);
            end
            obj = obj.reset();
        end
        
        function obj = reset(obj)
            % Choose random starting state
            stateIdx = randi(obj.nStates);
            obj.currentState = obj.members{stateIdx};
            obj.currentStateID = obj.IDs(stateIdx);
            
            % Prepare histories
            obj = prepHistory(obj);
            
            % Prepare colours
            obj.stateCols = rand(obj.nStates, 3);
            % Use stateIndex to index states
            obj.stateIndex = 1:obj.nStates;
            % Or use (obj.currentStateID==obj.IDs)
            
            % Reset iterations
            obj.it = 0;
        end
        
        function obj = run(obj, its)
            % If no its specified run to end
            if ~exist('its', 'var')
                its = obj.its;
            end
            
            % If too many iterations, append more
            rmIts = (obj.its - obj.it);
            if its>rmIts
                obj = addIterations(obj, its-rmIts);
            end
            
            % Run
            for i = obj.it+1 : obj.it+its
                obj = obj.iterate();
            end
            
            disp('Finished')
        end
        
        function obj = iterate(obj)
            obj.it = obj.it+1;
            
            % Get current state row
            r = obj.IDs == obj.currentStateID;
            
            changeRatios = obj.transitionMatrix(r', :);
            
            % Pick next state
            [~, mIdx] = max(abs(rand(1,obj.nStates)).*changeRatios);
            % mIdx corresponds to obj.stateIndex
            
            % Update member properties (like value) here
            
            % Set next state
            obj.currentState = obj.members{mIdx};
            obj.currentStateID = obj.IDs(mIdx);
            obj.currentValue = obj.members{mIdx}.value;
            
            % Update histories
            obj.stateHistory{obj.it} = obj.currentState.name;
            obj.stateHistoryID(obj.it) = obj.currentStateID;
            obj.valueHistory(obj.it) = obj.currentValue;
            
            % Plot
            if obj.plotOn
                obj.plotState();
                obj.plotValue();
            end
            obj.cmdOutput();
        end
        
        function obj = addIterations(obj, its)
            % Lazy
            % Create new model, steal preallocated vectors
            newParams.its = its;
            newMod = markovChain({state([], [], [], [])}, newParams);
            
            % Pull out histories and stick in this model
            obj.xAxis = ...
                [obj.xAxis, obj.xAxis(end)+newMod.xAxis];
            obj.stateHistory = ...
                [obj.stateHistory, newMod.stateHistory];
            obj.stateHistoryID = ...
                [obj.stateHistoryID, newMod.stateHistoryID];
            obj.valueHistory = ...
                [obj.valueHistory, newMod.valueHistory];
            
            obj.its = obj.its+its;
        end
    end
    
    methods (Access = private)
        function plotState(obj)
            subplot(2,1,1)
            hold on
            % Scatter current state on current it
            scatter(obj.it, obj.currentStateID, ...
                'MarkerEdgeColor', ...
                obj.stateCols((obj.currentStateID==obj.IDs)',:))
            % Draw line between last state and this state, coloured by
            % new state
            if obj.it>1
                plot(obj.xAxis(obj.it-1:obj.it), ...
                    obj.stateHistoryID(obj.it-1:obj.it), ...
                    'Color', ...
                    obj.stateCols((obj.currentStateID==obj.IDs)',:))
            end
            drawnow
        end
        
        function plotValue(obj)
            subplot(2,1,2)
            hold on
            scatter(obj.it, obj.currentValue, ...
                'MarkerEdgeColor', ...
                obj.stateCols((obj.currentStateID==obj.IDs)',:))
            if obj.it>1
                plot(obj.xAxis(obj.it-1:obj.it), ...
                    obj.valueHistory(obj.it-1:obj.it), ...
                    'Color', ...
                    obj.stateCols((obj.currentStateID==obj.IDs)',:))
            end
            drawnow
        end
        
        function cmdOutput(obj)
            disp([num2str(obj.it),': ', ...
                obj.currentState.name, ' - ', ...
                num2str(obj.currentState.value)])
        end
        
        function obj = prepHistory(obj)
            obj.xAxis = 1:obj.its;
            obj.stateHistory = cell(1, obj.its);
            obj.stateHistoryID = NaN(1, obj.its);
            obj.valueHistory = NaN(1, obj.its);
        end
        
        function obj = randomTransitionMatrix(obj)
            % Totally randomise transition matrix ignoring specified states
            obj.transitionMatrix = ...
                abs(randn(obj.nStates, obj.nStates));
        end
        
        function obj = specifiedTransitionMatrix(obj)
            % Set random first as lazy preallocation
            obj = randomTransitionMatrix(obj);
            for s = 1:obj.nStates
                % Set transition to all other states as outstate (2)
                obj.transitionMatrix(s,:) = obj.members{s}.switchP(2);
                % Set transition to self as instate (1)
                obj.transitionMatrix(s,s) = obj.members{s}.switchP(1);
            end
        end
    end
end