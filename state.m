classdef state
    properties
        name % Name, string
        ID % Numeric ID
        value = []; % Numeric value
        switchP = []; % Switch prob [self, other]
    end
    
    methods
        % Create
        function obj = state(name, ID, value, switchP)
            % Set basic stuff
            if isempty(name)
                obj.name = 'Placeholder';
            else
                obj.name = name;
            end
            if isempty(value)
                obj.value = randn;
            else
                obj.value = value;
            end
            
            % Set ID - do here instead of set method as uses
            % obj.name
            if isempty(ID)
                obj.ID = double(obj.name(1));
            else
                obj.ID = ID;
            end
            
            % Set and normalise switch probabilities
            obj.switchP = switchP;
        end
        
        % Set and normalise switch probabilities
        function obj = set.switchP(obj, switchP)
            if isempty(switchP)
                r = abs(rand);
                obj.switchP = [r, 1-r];
            else % Specified
                obj.switchP = switchP/sum(switchP);
            end
        end
        
        % Set initial value
        function obj = set.value(obj, value)
            if isempty(value)
                obj.value = randi(10000);
            else
                obj.value = value;
            end
            
        end
    end
end