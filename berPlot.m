function fig = berPlot(results, options)
    if nargin < 2 || isempty(options), options = struct(); end
    fig = errorRatePlot(results,'BER',options);
end
