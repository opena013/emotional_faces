% Construct the cartesian product of all the given arguments (which are
% themselves vertical vectors, so something like [1 2 3]').
function product = cartesian_product(varargin)
    % Count the number of arguments provided and create a cell array of
    % that size.
    ls = cell(1, length(varargin));
    
    % For each argument...
    for i = 1:length(varargin)
        % Instantiate a numeric vector counting up from 1 to the length of
        % that argument.
        ls{i} = 1:size(varargin{i}, 1);
    end
    
    % Constructs a grid in N dimensional space (where N is the number of
    % arguments) for each of the variables.
    out = cell(1, length(varargin));
    [out{:}] = ndgrid(ls{:});
        
    % Convert the n-dimensional grid into a mtrix that represents all
    % combinations of the provided arguments.
    for i = 1:length(out)
        out{i} = varargin{i}(out{i}, :);
    end
        
    product = [out{:}];
end