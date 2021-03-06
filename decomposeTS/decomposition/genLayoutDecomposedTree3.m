% this function is used to compute planar configurations of tree nodes
% this function is very specific to our application, for the visualization
% of decomposed time series

% this is a modified version of 'genLayoutDecomposedTree2.m'
% main difference:
% layout generated by this version is more visually comfortable,
% the layout is generated in a top-down way

% current support plotting of 'time series'

function anchorTree = genLayoutDecomposedTree3(decomposedTree, reference)
    narginchk(1,2);
    
    if nargin == 1
        reference = 'time-series';
    elseif nargin == 2
        tf = strcmp(reference, {'time-series', 'info-gain'});
        if sum(tf) == 0
            error('Now only support two kinds of layouts\n');
        end
    end

    anchorTree = tree(decomposedTree, []);
    dt = decomposedTree.depthtree;
    depth = dt.depth;

   
     
    root = decomposedTree.get(1);
    timeseries = root.timeseries;
    
    % place to set the horizontal and vertical gaps
    % y-gap is set to be 2 times as the magnitude
    % x-gap is set to be 1/10 of the length of the signal
    
    switch reference
        case 'time-series'
            mag = max(timeseries) - min(timeseries);
            gapY = 2*mag;    
        case 'info-gain'
%             mag = max(infoGains) - min(infoGains);
            iterator = decomposedTree.depthfirstiterator;
            mag_var_infoGain = 0;
            for i=iterator
                i_node = decomposedTree.get(i);
                i_infoGains = i_node.infoGains;
                if max(i_infoGains) - min(i_infoGains) > mag_var_infoGain
                    mag_var_infoGain = max(i_infoGains) - min(i_infoGains);
                end
            end
            gapY = 2*mag_var_infoGain;    
        otherwise
            error('Now only support two kinds of layouts\n');
    end
    
    len = length(timeseries);
    gapX = 0.05*len;
     

    yCenter = gapY * depth;
    xshift = 0;
    anchorTree = anchorTree.set(1, [xshift, yCenter]);
    %% generate layout in a top-down way
	for i=0:depth-1
        
        pIdx = find(dt == i);
        nSiblings = length(pIdx);
        cIdx = [];
        % 2.1 get children indices
        for j=1:nSiblings
            j_cIdx = retrieveChildrenIdx(decomposedTree,pIdx(j));
            cIdx = cat(1, cIdx, j_cIdx(:));            
        end
        % 2.2 get parent & child scope
        cIdx = [];
        cOrder = [];
        cXScopes = [];
        
        for j=1:nSiblings
            j_anchor_node = anchorTree.get(pIdx(j));
            j_anchor_node_x_median = j_anchor_node(1);
            
            j_tree_node = decomposedTree.get(pIdx(j));
            j_ts_len    = length(j_tree_node.timeseries);
            
            xlen = j_ts_len + gapX;
            xmin = j_anchor_node_x_median - xlen/2;
            xmax = j_anchor_node_x_median + xlen/2;

            j_cIdx = retrieveChildrenIdx(decomposedTree, pIdx(j));
            if isempty(j_cIdx)
                continue;
            end
            
            l = j_cIdx(1);
            l_node = decomposedTree.get(l);
            lOrder = median(l_node.temporalIdx);
            lLen = length(l_node.timeseries);
            
            
            r = j_cIdx(2);
            r_node = decomposedTree.get(r);
            rOrder = median(r_node.temporalIdx);
            rLen = length(r_node.timeseries);
            
            if lOrder < rOrder
                cIdx = cat(1, cIdx, [l; r]);
                cOrder = cat(1, cOrder, [lOrder; rOrder]);
                cXScopes = cat(1, cXScopes, [xmin xmin + lLen]);
                cXScopes = cat(1, cXScopes, [xmin + lLen + gapX xmax]);
            else
                cIdx = cat(1, cIdx, [r;l]);
                cOrder = cat(1, cOrder, [rOrder; lOrder]);
                cXScopes = cat(1, cXScopes, [xmin xmin + rLen]);
                cXScopes = cat(1, cXScopes, [xmin + rLen + gapX xmax]);
                
            end            
        end
        
        % 2.3 re-ordering
        [cOrder, tmpidx] =  sort(cOrder, 'ascend');
        cXScopes         =  cXScopes(tmpidx,:);
        cIdx             =  cIdx(tmpidx);
        
        for j=1:numel(cIdx)-1
            eval = cXScopes(j,2);
            sval = cXScopes(j+1,1);
            
            if sval <= eval + gapX
                for k=j+1:numel(cIdx)
                    cXScopes(k,:) = cXScopes(k,:) + (eval + gapX - sval);
                end
            end
        end
        
        % 2.4 set anchor tree
        yCenter = gapY*(depth-i-1);
        
        for j=1:length(cIdx)
            xshift = cXScopes(j,:);
            xshift = sum(xshift)/2;
            anchorTree = anchorTree.set(cIdx(j), [xshift, yCenter]);
        end
        
 
      
    end
    
end