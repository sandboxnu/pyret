function initIntervals(xMinValue, xMaxValue) {
    const lossManager = new Map()

    for (let i = xMinValue; i < xMaxValue; i++) {
        lossManager.set([i, i + 1], null)
    }

    return lossManager;
}

function recomputePoints() {
    
}