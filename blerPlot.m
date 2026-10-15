function fig = blerPlot(results, options)
    if nargin < 2 || isempty(options), options = struct(); end
    if ~isfield(options,'yLimits'), options.yLimits = [1e-2 1]; end
    fig = errorRatePlot(results,'BLER',options);
end
