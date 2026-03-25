/**
 * initializes data points and intervals for loss manager
 */
function initIntervals(xMinValue, xMaxValue) {
    const lossManager = new Map()

    for (let i = xMinValue; i < xMaxValue; i++) {
        lossManager.set([i, i + 1], null)
    }

    return lossManager;
}

/**
 * map f(x) to each x and stores points in data
 */
function recomputePoints(f, data) {
    
}

/**
 * flow:
 * 1. take in a function
 * 2. apply f(x) to each x (abstracted and will be done in Pyret)
 * 3. compute loss over each interval
 * 4. split interval w/ highest loss in half
 * 5. recompute losses
 * Stopping condition: threshold, numSamples
 * To do: how to decide which loss function for a given f
 */
function runner() {

}