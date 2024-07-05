% Function for plotting a table as a heatmap, using two columns as the x
% and y axes of the grid. For a table with more than 2 predictors, the 
% other columns can be locked at particular values.
%
% Parameters:
%   grid:       A table with named columns. Includes header
%               `log_likelihood` as the header representing the values
%               within the grid squares themselves.
%   x_dim:      A string representing the header name for the column that
%               will span the x-axis.
%   y_dim:      A string representing the header name for the column that
%               will span the y-axis.
%   lock_at:    A struct with named fields that represents the headers not
%               represented in `x_dim`, `y_dim`, and `log_likelihood`.
%
% Written by: Samuel Taylor, Laureate Institute for Brain Research (2022)

function heatmap_grid(grid, x_dim, y_dim, lock_at)      
    % Lock specified dimensions at provided values (needed when creating
    % heatmaps from data with more than 2 dimensions -- must "slice" across
    % several dimensions in order to create a 2D plot. 
    if exist('lock_at', 'var')
        lockdims = fieldnames(lock_at);

        % Filter the rows of the table for each locked dimension, keeping
        % only rows that are have values for each "locked" dimensions that
        % match the given value.
        for lock_i = 1:numel(lockdims)
            lockdim = lockdims{lock_i};
            lockval = lock_at.(lockdim);

            grid = grid(abs(grid.(lockdim) - lockval) < eps, :);
        end
    end
    
    % Display the heatmap, using the log_likelihood column of the table as
    % the column of interest. Hide the grid lines (makes it prettier),
    % modify the title, and use a warmer color palette for the heatmap.
    heatmap(                                                                        ...
        grid, x_dim, y_dim,                                                         ...
        'ColorVariable', 'log_likelihood',                                          ...
        'GridVisible', 'off',                                                       ...
        'Title', ['Negative Log Likelihood Heatmap for ', x_dim, ' and ' y_dim],    ...
        'Colormap', flipud(hot)                                                     ...
    );
end